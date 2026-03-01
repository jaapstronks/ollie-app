//
//  FoodRecallService.swift
//  Otis-app
//
//  Service for fetching pet food recall alerts from FDA API

import Foundation
import Combine
import os
import OtisShared

/// Service for fetching and managing pet food recall alerts
@MainActor
class FoodRecallService: ObservableObject {

    // MARK: - Published State

    @Published var recalls: [FoodRecall] = []
    @Published var matchingRecalls: [FoodRecall] = []
    @Published var isLoading = false
    @Published var lastError: Error?
    @Published var lastChecked: Date?

    // MARK: - Settings

    @Published var settings: FoodAlertSettings {
        didSet {
            saveSettings()
        }
    }

    // MARK: - Private

    private let logger = Logger.otis(category: "FoodRecallService")
    private var cache: (recalls: [FoodRecall], fetchedAt: Date)?
    private let cacheValidityHours: Double = 6

    // MARK: - Common Pet Food Brands

    /// Popular pet food brands for quick selection
    static let commonBrands: [String] = [
        "Royal Canin",
        "Hill's Science Diet",
        "Purina Pro Plan",
        "Eukanuba",
        "IAMS",
        "Pedigree",
        "Blue Buffalo",
        "Orijen",
        "Acana",
        "Wellness",
        "Nutro",
        "Taste of the Wild",
        "Merrick",
        "Canidae",
        "Natural Balance"
    ]

    // MARK: - Init

    init() {
        self.settings = Self.loadSettings()
    }

    // MARK: - Public Methods

    /// Check for recalls, using cache if valid
    func checkForRecalls() async {
        // Skip if disabled
        guard settings.enabled else { return }

        // Check cache validity
        if let cached = cache,
           Date().timeIntervalSince(cached.fetchedAt) < cacheValidityHours * 3600 {
            recalls = cached.recalls
            updateMatchingRecalls()
            return
        }

        await fetchRecalls()
    }

    /// Force refresh, bypassing cache
    func refresh() async {
        cache = nil
        await fetchRecalls()
    }

    /// Check if a recall matches any of the user's saved brands
    func matchesUserBrands(_ recall: FoodRecall) -> Bool {
        guard !settings.savedBrands.isEmpty else { return false }

        let normalizedRecallBrand = normalizedBrandName(recall.brand)
        return settings.savedBrands.contains { savedBrand in
            let normalizedSaved = normalizedBrandName(savedBrand)
            return normalizedRecallBrand.contains(normalizedSaved) ||
                   normalizedSaved.contains(normalizedRecallBrand)
        }
    }

    /// Acknowledge a recall (dismiss from alerts)
    func acknowledgeRecall(_ recall: FoodRecall) {
        settings.acknowledgedRecallIds.insert(recall.id)
        updateMatchingRecalls()
    }

    /// Get unacknowledged matching recalls
    var unacknowledgedRecalls: [FoodRecall] {
        matchingRecalls.filter { !settings.acknowledgedRecallIds.contains($0.id) }
    }

    // MARK: - Settings Persistence

    private static let settingsKey = "FoodAlertSettings"

    private static func loadSettings() -> FoodAlertSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(FoodAlertSettings.self, from: data) else {
            return .defaultSettings()
        }
        return settings
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.settingsKey)
    }

    // MARK: - Private Methods

    private func fetchRecalls() async {
        isLoading = true
        lastError = nil

        do {
            let fetchedRecalls = try await performFetch()
            recalls = fetchedRecalls
            cache = (recalls: fetchedRecalls, fetchedAt: Date())
            lastChecked = Date()
            settings.lastChecked = Date()
            updateMatchingRecalls()
            logger.info("Fetched \(fetchedRecalls.count) recalls")
        } catch {
            lastError = error
            logger.error("Failed to fetch recalls: \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func performFetch() async throws -> [FoodRecall] {
        // FDA API endpoint for animal adverse events (includes recalls)
        // Query for dog food recalls in the last 90 days
        let urlString = "https://api.fda.gov/animalandveterinary/event.json?search=animal.species:\"Dog\"+AND+_exists_:reaction&limit=50&sort=original_receive_date:desc"

        guard let url = URL(string: urlString) else {
            throw FoodRecallError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FoodRecallError.networkError
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(FDAResponse.self, from: data)

        return parseResponse(apiResponse)
    }

    private func parseResponse(_ response: FDAResponse) -> [FoodRecall] {
        guard let results = response.results else { return [] }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        return results.compactMap { event -> FoodRecall? in
            // Extract brand from first drug product
            guard let drug = event.drug?.first,
                  let brand = drug.brand_name ?? drug.manufacturer?.name else {
                return nil
            }

            // Extract product name
            let product = drug.active_ingredients?.first?.name ?? drug.brand_name ?? "Unknown Product"

            // Extract reaction/reason
            let reactions = event.reaction?.compactMap { $0.veddra_term_name } ?? []
            let reason = reactions.joined(separator: ", ")
            guard !reason.isEmpty else { return nil }

            // Parse date
            let dateString = event.original_receive_date ?? ""
            let date = dateFormatter.date(from: dateString) ?? Date()

            // Determine severity based on reactions
            let severity = determineSeverity(reactions: reactions)

            // Create unique ID
            let id = "\(brand)-\(dateString)-\(reason.prefix(20))"
                .replacingOccurrences(of: " ", with: "-")
                .lowercased()

            return FoodRecall(
                id: id,
                date: date,
                brand: brand,
                product: product,
                reason: reason,
                severity: severity,
                affectedRegions: ["US"],
                sourceURL: URL(string: "https://www.fda.gov/animal-veterinary/safety-health/recalls-withdrawals")
            )
        }
    }

    private func determineSeverity(reactions: [String]) -> FoodRecall.Severity {
        let lowercased = reactions.map { $0.lowercased() }

        if lowercased.contains(where: { $0.contains("death") || $0.contains("died") }) {
            return .critical
        } else if lowercased.contains(where: { $0.contains("liver") || $0.contains("kidney") || $0.contains("hospitali") }) {
            return .high
        } else if lowercased.contains(where: { $0.contains("vomit") || $0.contains("diarr") || $0.contains("sick") }) {
            return .medium
        } else {
            return .low
        }
    }

    private func updateMatchingRecalls() {
        matchingRecalls = recalls.filter { matchesUserBrands($0) }
    }

    /// Normalize brand names for fuzzy matching
    private func normalizedBrandName(_ brand: String) -> String {
        brand.lowercased()
            .replacingOccurrences(of: "'s", with: "s")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - FDA API Response Types

private struct FDAResponse: Codable {
    let results: [FDAEvent]?
}

private struct FDAEvent: Codable {
    let original_receive_date: String?
    let drug: [FDADrug]?
    let reaction: [FDAReaction]?
}

private struct FDADrug: Codable {
    let brand_name: String?
    let manufacturer: FDAManufacturer?
    let active_ingredients: [FDAIngredient]?
}

private struct FDAManufacturer: Codable {
    let name: String?
}

private struct FDAIngredient: Codable {
    let name: String?
}

private struct FDAReaction: Codable {
    let veddra_term_name: String?
}

// MARK: - Errors

enum FoodRecallError: LocalizedError {
    case invalidURL
    case networkError
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return Strings.Errors.invalidURL
        case .networkError: return Strings.Errors.networkError
        case .parseError: return Strings.FoodRecall.parseError
        }
    }
}
