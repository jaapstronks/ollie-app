//
//  BreedService.swift
//  Otis-app
//
//  Service for fetching dog breeds from TheDogAPI
//

import Foundation
import OtisShared
import os

/// Service for fetching and caching dog breed data from TheDogAPI
@Observable
@MainActor
class BreedService {

    // MARK: - State

    private(set) var breeds: [Breed] = []
    private(set) var isLoading = false
    private(set) var lastError: Error?

    // MARK: - Singleton

    static let shared = BreedService()

    // MARK: - Private Properties

    @ObservationIgnored private let logger = Logger.otis(category: "BreedService")

    /// UserDefaults keys for caching
    private enum CacheKeys {
        static let breeds = "cached_breeds"
        static let cacheDate = "breeds_cache_date"
    }

    /// Cache validity in days
    private let cacheValidityDays: Double = 7

    /// API key from Info.plist (set via xcconfig)
    private var apiKey: String? {
        Bundle.main.infoDictionary?["TheDogAPIKey"] as? String
    }

    // MARK: - Init

    private init() {
        loadCachedBreeds()
    }

    // MARK: - Public Methods

    /// Fetch breeds from API or cache
    /// Returns cached breeds if available and fresh, otherwise fetches from API
    func fetchBreeds() async {
        // Check if cache is still valid
        if !breeds.isEmpty && isCacheValid() {
            logger.debug("Using cached breeds (\(self.breeds.count) breeds)")
            return
        }

        isLoading = true
        lastError = nil

        do {
            let fetchedBreeds = try await performFetch()
            breeds = fetchedBreeds.sorted { $0.name < $1.name }
            saveToCache(breeds)
            logger.info("Fetched \(fetchedBreeds.count) breeds from TheDogAPI")
        } catch {
            logger.error("Failed to fetch breeds: \(error.localizedDescription)")
            lastError = error
            // Fall back to cached breeds if available
            if breeds.isEmpty {
                loadCachedBreeds()
            }
        }

        isLoading = false
    }

    /// Find a breed by exact ID
    func breed(byId id: Int) -> Breed? {
        breeds.first { $0.id == id }
    }

    /// Find a breed by name using fuzzy matching
    /// Matches partial names, case-insensitive
    func findBreed(named name: String) -> Breed? {
        let searchName = name.lowercased().trimmingCharacters(in: .whitespaces)

        // Try exact match first
        if let exactMatch = breeds.first(where: { $0.name.lowercased() == searchName }) {
            return exactMatch
        }

        // Try contains match
        if let containsMatch = breeds.first(where: { $0.name.lowercased().contains(searchName) }) {
            return containsMatch
        }

        // Try reverse contains (search term in breed name)
        if let reverseMatch = breeds.first(where: { searchName.contains($0.name.lowercased()) }) {
            return reverseMatch
        }

        // Try matching individual words
        let searchWords = searchName.components(separatedBy: .whitespaces)
        for breed in breeds {
            let breedWords = breed.name.lowercased().components(separatedBy: .whitespaces)
            let matchCount = searchWords.filter { word in
                breedWords.contains { $0.hasPrefix(word) || word.hasPrefix($0) }
            }.count
            if matchCount >= min(2, searchWords.count) {
                return breed
            }
        }

        return nil
    }

    /// Get breeds filtered by size category
    func breeds(for size: PuppyProfile.SizeCategory) -> [Breed] {
        breeds.filter { $0.weightRange.sizeCategory == size }
    }

    /// Search breeds by name query
    func searchBreeds(query: String) -> [Breed] {
        guard !query.isEmpty else { return breeds }

        let searchQuery = query.lowercased()
        return breeds.filter { breed in
            breed.name.lowercased().contains(searchQuery)
        }
    }

    /// Force refresh breeds, bypassing cache
    func refresh() async {
        clearCache()
        await fetchBreeds()
    }

    // MARK: - Private Methods

    private func performFetch() async throws -> [Breed] {
        guard let apiKey = apiKey, !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            logger.warning("TheDogAPI key not configured, using fallback breeds")
            return Self.fallbackBreeds
        }

        let urlString = "https://api.thedogapi.com/v1/breeds"
        guard let url = URL(string: urlString) else {
            throw BreedServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BreedServiceError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            logger.error("API returned status code: \(httpResponse.statusCode)")
            throw BreedServiceError.networkError
        }

        let decoder = JSONDecoder()
        let apiBreeds = try decoder.decode([TheDogAPIBreed].self, from: data)

        // Convert API responses to our Breed model
        let parsedBreeds = apiBreeds.compactMap { Breed(from: $0) }

        if parsedBreeds.isEmpty {
            logger.warning("No breeds parsed from API response, using fallback")
            return Self.fallbackBreeds
        }

        return parsedBreeds
    }

    // MARK: - Cache Management

    private func isCacheValid() -> Bool {
        guard let cacheDate = UserDefaults.standard.object(forKey: CacheKeys.cacheDate) as? Date else {
            return false
        }

        let daysSinceCached = Date().timeIntervalSince(cacheDate) / (24 * 60 * 60)
        return daysSinceCached < cacheValidityDays
    }

    private func saveToCache(_ breeds: [Breed]) {
        do {
            let data = try JSONEncoder().encode(breeds)
            UserDefaults.standard.set(data, forKey: CacheKeys.breeds)
            UserDefaults.standard.set(Date(), forKey: CacheKeys.cacheDate)
        } catch {
            logger.error("Failed to cache breeds: \(error.localizedDescription)")
        }
    }

    private func loadCachedBreeds() {
        guard let data = UserDefaults.standard.data(forKey: CacheKeys.breeds) else {
            // No cache available, use fallback breeds
            breeds = Self.fallbackBreeds
            return
        }

        do {
            breeds = try JSONDecoder().decode([Breed].self, from: data)
            logger.debug("Loaded \(self.breeds.count) breeds from cache")
        } catch {
            logger.error("Failed to decode cached breeds: \(error.localizedDescription)")
            breeds = Self.fallbackBreeds
        }
    }

    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: CacheKeys.breeds)
        UserDefaults.standard.removeObject(forKey: CacheKeys.cacheDate)
    }

    // MARK: - Fallback Breeds

    /// Fallback breeds for offline use or when API is unavailable
    static let fallbackBreeds: [Breed] = [
        Breed(id: 1, name: "Affenpinscher", weightRange: .init(minKg: 3, maxKg: 6)),
        Breed(id: 10, name: "Australian Shepherd", weightRange: .init(minKg: 18, maxKg: 29)),
        Breed(id: 15, name: "Beagle", weightRange: .init(minKg: 9, maxKg: 11)),
        Breed(id: 17, name: "Bedlington Terrier", weightRange: .init(minKg: 8, maxKg: 10)),
        Breed(id: 21, name: "Bernese Mountain Dog", weightRange: .init(minKg: 35, maxKg: 55)),
        Breed(id: 30, name: "Border Collie", weightRange: .init(minKg: 14, maxKg: 20)),
        Breed(id: 34, name: "Boston Terrier", weightRange: .init(minKg: 4, maxKg: 11)),
        Breed(id: 36, name: "Boxer", weightRange: .init(minKg: 25, maxKg: 32)),
        Breed(id: 41, name: "Bulldog", weightRange: .init(minKg: 18, maxKg: 25)),
        Breed(id: 53, name: "Cavalier King Charles Spaniel", weightRange: .init(minKg: 5, maxKg: 8)),
        Breed(id: 58, name: "Chihuahua", weightRange: .init(minKg: 1, maxKg: 3)),
        Breed(id: 65, name: "Cocker Spaniel", weightRange: .init(minKg: 12, maxKg: 16)),
        Breed(id: 68, name: "Collie", weightRange: .init(minKg: 18, maxKg: 29)),
        Breed(id: 71, name: "Corgi", weightRange: .init(minKg: 10, maxKg: 14)),
        Breed(id: 76, name: "Dachshund", weightRange: .init(minKg: 7, maxKg: 15)),
        Breed(id: 79, name: "Dalmatian", weightRange: .init(minKg: 20, maxKg: 27)),
        Breed(id: 81, name: "Doberman Pinscher", weightRange: .init(minKg: 27, maxKg: 45)),
        Breed(id: 98, name: "French Bulldog", weightRange: .init(minKg: 8, maxKg: 14)),
        Breed(id: 107, name: "German Shepherd Dog", weightRange: .init(minKg: 22, maxKg: 40)),
        Breed(id: 113, name: "Golden Retriever", weightRange: .init(minKg: 25, maxKg: 34)),
        Breed(id: 115, name: "Great Dane", weightRange: .init(minKg: 45, maxKg: 90)),
        Breed(id: 124, name: "Havanese", weightRange: .init(minKg: 3, maxKg: 6)),
        Breed(id: 132, name: "Irish Setter", weightRange: .init(minKg: 27, maxKg: 32)),
        Breed(id: 141, name: "Jack Russell Terrier", weightRange: .init(minKg: 5, maxKg: 8)),
        Breed(id: 149, name: "Labrador Retriever", weightRange: .init(minKg: 25, maxKg: 36)),
        Breed(id: 157, name: "Maltese", weightRange: .init(minKg: 2, maxKg: 4)),
        Breed(id: 167, name: "Miniature Schnauzer", weightRange: .init(minKg: 5, maxKg: 8)),
        Breed(id: 185, name: "Pomeranian", weightRange: .init(minKg: 1, maxKg: 3)),
        Breed(id: 187, name: "Poodle (Standard)", weightRange: .init(minKg: 20, maxKg: 32)),
        Breed(id: 188, name: "Poodle (Miniature)", weightRange: .init(minKg: 5, maxKg: 9)),
        Breed(id: 193, name: "Pug", weightRange: .init(minKg: 6, maxKg: 8)),
        Breed(id: 201, name: "Rottweiler", weightRange: .init(minKg: 36, maxKg: 61)),
        Breed(id: 212, name: "Saint Bernard", weightRange: .init(minKg: 54, maxKg: 91)),
        Breed(id: 219, name: "Shiba Inu", weightRange: .init(minKg: 8, maxKg: 11)),
        Breed(id: 221, name: "Shih Tzu", weightRange: .init(minKg: 4, maxKg: 7)),
        Breed(id: 224, name: "Siberian Husky", weightRange: .init(minKg: 16, maxKg: 27)),
        Breed(id: 248, name: "Vizsla", weightRange: .init(minKg: 18, maxKg: 27)),
        Breed(id: 250, name: "Weimaraner", weightRange: .init(minKg: 25, maxKg: 41)),
        Breed(id: 259, name: "Yorkshire Terrier", weightRange: .init(minKg: 2, maxKg: 3)),
    ]
}

// MARK: - Errors

enum BreedServiceError: LocalizedError {
    case invalidURL
    case networkError
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return Strings.Errors.invalidURL
        case .networkError:
            return Strings.Errors.networkError
        case .parseError:
            return Strings.Errors.couldNotProcessData
        }
    }
}
