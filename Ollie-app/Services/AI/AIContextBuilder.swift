//
//  AIContextBuilder.swift
//  Ollie-app
//
//  Assembles modular context components into AI request payloads.
//  Ensures only required components are included for each surface type.
//

import Foundation
import OtisShared

// MARK: - Context Builder

/// Builds context payloads for AI requests by assembling modular components.
/// Each surface type specifies which components it needs, and the builder
/// only includes those components in the payload.
final class AIContextBuilder {

    // MARK: - Dependencies

    private let eventStore: EventStore?
    private let profileStore: ProfileStore?

    // Optional providers - may not be available
    private var skillProgressProvider: (() -> [SkillProgress])?
    private var regressionLogProvider: (() -> [RegressionLogEntry])?
    private var socializationProgressProvider: ((PuppyProfile) -> SocializationProgress?)?

    /// Initialize with optional stores.
    /// If stores are not provided, context building will return empty/default components.
    init(
        eventStore: EventStore? = nil,
        profileStore: ProfileStore? = nil
    ) {
        self.eventStore = eventStore
        self.profileStore = profileStore
    }

    // MARK: - Provider Registration

    /// Register a provider for skill progress data (for training context)
    func registerSkillProgressProvider(_ provider: @escaping () -> [SkillProgress]) {
        self.skillProgressProvider = provider
    }

    /// Register a provider for regression log data (for training context)
    func registerRegressionLogProvider(_ provider: @escaping () -> [RegressionLogEntry]) {
        self.regressionLogProvider = provider
    }

    /// Register a provider for socialization progress data
    func registerSocializationProgressProvider(_ provider: @escaping (PuppyProfile) -> SocializationProgress?) {
        self.socializationProgressProvider = provider
    }

    // MARK: - Build Context

    /// Build a complete context payload for the specified surface.
    func buildContext(
        for surface: AISurface,
        profile: PuppyProfile,
        recentEvents: [PuppyEvent],
        prediction: PottyPrediction? = nil,
        gapStats: GapStats? = nil,
        sleepState: SleepState? = nil
    ) -> AIContextPayload {
        var components: [String: AnyCodable] = [:]

        let requiredKeys = surface.requiredComponents
        let optionalKeys = surface.optionalComponents

        // Build required components
        for key in requiredKeys {
            if let component = buildComponent(
                key: key,
                profile: profile,
                events: recentEvents,
                prediction: prediction,
                gapStats: gapStats,
                sleepState: sleepState
            ) {
                components[key.rawValue] = component
            }
        }

        // Build optional components (only if data available)
        for key in optionalKeys {
            if let component = buildComponent(
                key: key,
                profile: profile,
                events: recentEvents,
                prediction: prediction,
                gapStats: gapStats,
                sleepState: sleepState
            ) {
                components[key.rawValue] = component
            }
        }

        return AIContextPayload(
            surface: surface,
            profileId: profile.id,
            locale: Locale.current.identifier,
            promptVersion: surface.promptVersion,
            components: components
        )
    }

    // MARK: - Component Building

    private func buildComponent(
        key: AIContextComponentKey,
        profile: PuppyProfile,
        events: [PuppyEvent],
        prediction: PottyPrediction?,
        gapStats: GapStats?,
        sleepState: SleepState?
    ) -> AnyCodable? {
        switch key {
        case .dogIdentity:
            return AnyCodable(DogIdentityContext(profile: profile))

        case .household:
            let context = HouseholdContext(profile: profile)
            // Only include if there are household members
            return context.memberCount > 0 ? AnyCodable(context) : nil

        case .pottyPatterns:
            return AnyCodable(PottyPatternsContext(
                events: events,
                prediction: prediction,
                gapStats: gapStats
            ))

        case .sleep:
            let state = sleepState ?? SleepCalculations.currentSleepState(events: events)
            return AnyCodable(SleepContext(events: events, sleepState: state))

        case .feeding:
            return AnyCodable(FeedingContext(profile: profile, events: events))

        case .exercise:
            return AnyCodable(ExerciseContext(profile: profile, events: events))

        case .training:
            if let summary = buildTrainingSummary(profile: profile, events: events) {
                return AnyCodable(TrainingProgressContext(summary: summary))
            }
            return AnyCodable(TrainingProgressContext())

        case .trainingDetail:
            if let summary = buildTrainingSummary(profile: profile, events: events) {
                return AnyCodable(TrainingDetailContext(summary: summary))
            }
            return nil

        case .socialization:
            let progress = socializationProgressProvider?(profile)
            return AnyCodable(SocializationContext(profile: profile, socializationProgress: progress))

        case .recentEvents:
            return AnyCodable(RecentEventsSummary(events: events))

        case .health:
            return AnyCodable(HealthContext(profile: profile, events: events))
        }
    }

    private func buildTrainingSummary(profile: PuppyProfile, events: [PuppyEvent]) -> TrainingAISummary? {
        guard let skillProgressProvider = skillProgressProvider else { return nil }

        let skillProgress = skillProgressProvider()
        guard !skillProgress.isEmpty else { return nil }

        let regressionLog = regressionLogProvider?() ?? []

        // Convert training events to session summaries
        let trainingEvents = events.filter { $0.type == .training }
        let sessions = trainingEvents.compactMap { event -> SessionSummary? in
            guard let exercise = event.exercise else { return nil }

            // Parse success/fail from result if available
            var success = 1
            var failed = 0
            if let result = event.result?.lowercased() {
                if result.contains("fail") || result.contains("miss") {
                    success = 0
                    failed = 1
                }
            }

            return SessionSummary(
                skillId: exercise,
                timestamp: event.time,
                successReps: success,
                failedReps: failed,
                context: event.note
            )
        }

        return TrainingAISummary.create(
            profileId: profile.id,
            ageInWeeks: profile.ageInWeeks,
            daysHome: profile.daysHome,
            skillProgress: skillProgress,
            recentTrainingEvents: sessions,
            regressionLog: regressionLog
        )
    }
}

// MARK: - Context Payload

/// Complete context payload for an AI request.
struct AIContextPayload: Codable, Sendable {
    let surface: AISurface
    let profileId: UUID
    let locale: String
    let promptVersion: String

    /// Component data keyed by component type
    let components: [String: AnyCodable]

    /// Timestamp when this context was built
    let generatedAt: Date

    init(
        surface: AISurface,
        profileId: UUID,
        locale: String,
        promptVersion: String,
        components: [String: AnyCodable]
    ) {
        self.surface = surface
        self.profileId = profileId
        self.locale = locale
        self.promptVersion = promptVersion
        self.components = components
        self.generatedAt = Date()
    }
}

// MARK: - Type Erasure for Codable

/// Type-erased Codable wrapper for heterogeneous component storage.
/// Stores the JSON-encoded data for reliable encoding/decoding.
struct AnyCodable: Codable, Sendable {
    private let encodedData: Data

    /// Access the decoded value (for compatibility with existing code)
    var value: Any? {
        try? JSONSerialization.jsonObject(with: encodedData)
    }

    init<T: Codable & Sendable>(_ value: T) {
        // Encode the value to JSON data for storage
        self.encodedData = (try? JSONEncoder().encode(value)) ?? Data()
    }

    /// Initialize directly from pre-encoded data
    init(data: Data) {
        self.encodedData = data
    }

    init(from decoder: Decoder) throws {
        // When decoding, re-encode the container to get raw data
        let container = try decoder.singleValueContainer()

        // Try to decode as various types and re-encode
        if let dict = try? container.decode([String: AnyCodable].self) {
            self.encodedData = (try? JSONEncoder().encode(dict)) ?? Data()
        } else if let array = try? container.decode([AnyCodable].self) {
            self.encodedData = (try? JSONEncoder().encode(array)) ?? Data()
        } else if let string = try? container.decode(String.self) {
            self.encodedData = (try? JSONEncoder().encode(string)) ?? Data()
        } else if let int = try? container.decode(Int.self) {
            self.encodedData = (try? JSONEncoder().encode(int)) ?? Data()
        } else if let double = try? container.decode(Double.self) {
            self.encodedData = (try? JSONEncoder().encode(double)) ?? Data()
        } else if let bool = try? container.decode(Bool.self) {
            self.encodedData = (try? JSONEncoder().encode(bool)) ?? Data()
        } else {
            self.encodedData = Data()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        // Decode the stored JSON data and re-encode it
        if let jsonObject = try? JSONSerialization.jsonObject(with: encodedData) {
            if let dict = jsonObject as? [String: Any] {
                // Encode dictionary manually
                let reEncoded = try JSONSerialization.data(withJSONObject: dict)
                if let jsonString = String(data: reEncoded, encoding: .utf8) {
                    // Write as raw JSON using JSONDecoder trick
                    try container.encode(RawJSON(json: jsonString))
                } else {
                    try container.encodeNil()
                }
            } else if let array = jsonObject as? [Any] {
                let reEncoded = try JSONSerialization.data(withJSONObject: array)
                if let jsonString = String(data: reEncoded, encoding: .utf8) {
                    try container.encode(RawJSON(json: jsonString))
                } else {
                    try container.encodeNil()
                }
            } else if let string = jsonObject as? String {
                try container.encode(string)
            } else if let number = jsonObject as? NSNumber {
                // Check if it's a boolean
                if CFGetTypeID(number) == CFBooleanGetTypeID() {
                    try container.encode(number.boolValue)
                } else if number.doubleValue == Double(number.intValue) {
                    try container.encode(number.intValue)
                } else {
                    try container.encode(number.doubleValue)
                }
            } else {
                try container.encodeNil()
            }
        } else {
            try container.encodeNil()
        }
    }
}

/// Helper for encoding raw JSON strings
private struct RawJSON: Encodable {
    let json: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // This is a workaround - ideally we'd write raw JSON
        // For now, just encode the string representation
        try container.encode(json)
    }
}
