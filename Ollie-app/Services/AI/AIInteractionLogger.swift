//
//  AIInteractionLogger.swift
//  Ollie-app
//
//  Logs AI interactions for review and prompt improvement.
//  Captures full context, prompts, and responses for export.
//

import Foundation
import OtisShared

// MARK: - AI Interaction Entry

/// A logged AI interaction with full context for review.
struct AIInteractionEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let surface: String

    // Request context
    let profileSummary: ProfileSummary
    let contextPayload: AIContextPayload
    let systemPrompt: String
    let outputFormat: String

    // Response (stored as raw JSON string to avoid codable issues)
    let responseJSON: String?
    let rawResponse: String?
    let provider: String?
    let model: String?
    let latencyMs: Int
    let confidence: Double?
    let reasoningTags: [String]
    let error: String?

    // User feedback (added later)
    var userFeedback: String?
    var feedbackRating: FeedbackRating?
    var feedbackTimestamp: Date?

    struct ProfileSummary: Codable {
        let puppyName: String
        let ageWeeks: Int
        let daysHome: Int
        let sizeCategory: String
    }

    enum FeedbackRating: String, Codable, CaseIterable {
        case helpful = "helpful"
        case notHelpful = "not_helpful"
        case wrong = "wrong"
        case tooWordy = "too_wordy"
        case missingContext = "missing_context"
    }
}

// MARK: - AI Interaction Logger

/// Logger for AI interactions with persistence and export.
@MainActor
final class AIInteractionLogger {
    static let shared = AIInteractionLogger()

    private let fileURL: URL
    private var entries: [AIInteractionEntry] = []
    private let maxEntries = 200  // Keep last 200 interactions

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("ai_interactions.json")
        loadEntries()
    }

    // MARK: - Logging

    /// Log an AI interaction with full context.
    func log(
        surface: AISurface,
        profile: PuppyProfile,
        context: AIContextPayload,
        systemPrompt: String,
        outputFormat: String,
        response: Any?,
        rawResponse: String?,
        provider: String?,
        model: String?,
        latencyMs: Int,
        confidence: Double?,
        reasoningTags: [String],
        error: String?
    ) {
        // Convert response to JSON string for storage
        var responseJSON: String?
        if let resp = response {
            if let dict = resp as? [String: Any],
               let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                responseJSON = String(data: data, encoding: .utf8)
            } else {
                responseJSON = String(describing: resp)
            }
        }

        let entry = AIInteractionEntry(
            id: UUID(),
            timestamp: Date(),
            surface: surface.rawValue,
            profileSummary: .init(
                puppyName: profile.name,
                ageWeeks: profile.ageInWeeks,
                daysHome: profile.daysHome,
                sizeCategory: profile.sizeCategory.rawValue
            ),
            contextPayload: context,
            systemPrompt: systemPrompt,
            outputFormat: outputFormat,
            responseJSON: responseJSON,
            rawResponse: rawResponse,
            provider: provider,
            model: model,
            latencyMs: latencyMs,
            confidence: confidence,
            reasoningTags: reasoningTags,
            error: error,
            userFeedback: nil,
            feedbackRating: nil,
            feedbackTimestamp: nil
        )

        entries.append(entry)

        // Trim to max entries
        if entries.count > maxEntries {
            entries = Array(entries.suffix(maxEntries))
        }

        saveEntries()
    }

    // MARK: - Feedback

    /// Add user feedback to an interaction.
    func addFeedback(entryId: UUID, rating: AIInteractionEntry.FeedbackRating, comment: String?) {
        guard let index = entries.firstIndex(where: { $0.id == entryId }) else { return }

        entries[index].feedbackRating = rating
        entries[index].userFeedback = comment
        entries[index].feedbackTimestamp = Date()

        saveEntries()
    }

    // MARK: - Retrieval

    /// Get recent interactions.
    func recentEntries(limit: Int = 50) -> [AIInteractionEntry] {
        Array(entries.suffix(limit).reversed())
    }

    /// Get entries for a specific surface.
    func entries(for surface: AISurface, limit: Int = 20) -> [AIInteractionEntry] {
        entries
            .filter { $0.surface == surface.rawValue }
            .suffix(limit)
            .reversed()
            .map { $0 }
    }

    /// Get entries with feedback.
    func entriesWithFeedback() -> [AIInteractionEntry] {
        entries.filter { $0.feedbackRating != nil }
    }

    // MARK: - Export

    /// Export all interactions as JSON for analysis.
    func exportJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(entries)
    }

    /// Export as shareable file URL.
    func exportToFile() -> URL? {
        guard let data = exportJSON() else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "ai_interactions_\(dateFormatter.string(from: Date())).json"

        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: exportURL)
            return exportURL
        } catch {
            print("Failed to export AI interactions: \(error)")
            return nil
        }
    }

    /// Export summary for quick review (less verbose).
    func exportSummary() -> String {
        var lines: [String] = []
        lines.append("AI Interaction Summary")
        lines.append("Generated: \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("Total entries: \(entries.count)")
        lines.append("")

        // Group by surface
        let grouped = Dictionary(grouping: entries, by: { $0.surface })
        for (surface, surfaceEntries) in grouped.sorted(by: { $0.key < $1.key }) {
            lines.append("## \(surface) (\(surfaceEntries.count) calls)")

            for entry in surfaceEntries.suffix(5) {
                lines.append("")
                lines.append("### \(entry.timestamp.formatted())")
                lines.append("Provider: \(entry.provider ?? "unknown") / \(entry.model ?? "unknown")")
                lines.append("Latency: \(entry.latencyMs)ms, Confidence: \(entry.confidence.map { String(format: "%.0f%%", $0 * 100) } ?? "N/A")")

                if let error = entry.error {
                    lines.append("ERROR: \(error)")
                } else if let responseJSON = entry.responseJSON {
                    lines.append("Response:")
                    lines.append(responseJSON)
                }

                if let feedback = entry.userFeedback {
                    lines.append("User Feedback [\(entry.feedbackRating?.rawValue ?? "none")]: \(feedback)")
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Clear all logged interactions.
    func clearAll() {
        entries.removeAll()
        saveEntries()
    }

    // MARK: - Persistence

    private func loadEntries() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([AIInteractionEntry].self, from: data)
        } catch {
            print("Failed to load AI interaction log: \(error)")
        }
    }

    private func saveEntries() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save AI interaction log: \(error)")
        }
    }
}

// MARK: - Integration Hook

extension AIOrchestrator {

    /// Log an interaction after request completes.
    func logInteraction(
        surface: AISurface,
        profile: PuppyProfile,
        context: AIContextPayload,
        response: AIBrokerResponse,
        latencyMs: Int
    ) {
        let instructions = AIInstructions.systemInstruction(for: surface)
        let format = AIInstructions.outputFormat(for: surface)

        // Extract confidence from response
        var confidence: Double?
        if let dict = response.response.value as? [String: Any],
           let conf = dict["confidence"] as? Double {
            confidence = conf
        }

        AIInteractionLogger.shared.log(
            surface: surface,
            profile: profile,
            context: context,
            systemPrompt: instructions,
            outputFormat: format,
            response: response.response.value,
            rawResponse: response.rawResponse,
            provider: response.providerUsed,
            model: response.modelUsed,
            latencyMs: latencyMs,
            confidence: confidence,
            reasoningTags: response.reasoningTags ?? [],
            error: response.error
        )
    }
}
