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
    private var behaviorInterventionProvider: (() -> [BehaviorIntervention])?
    private var sentimentStateProvider: (() -> SentimentState?)?

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

    /// Register a provider for behavior intervention data
    func registerBehaviorInterventionProvider(_ provider: @escaping () -> [BehaviorIntervention]) {
        self.behaviorInterventionProvider = provider
    }

    /// Register a provider for sentiment state data
    func registerSentimentStateProvider(_ provider: @escaping () -> SentimentState?) {
        self.sentimentStateProvider = provider
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

        // Use profile's preferred locale for consistent caching across household members
        // Falls back to device locale for legacy profiles without preferredLocale set
        let locale = profile.preferredLocale ?? Locale.current.identifier

        return AIContextPayload(
            surface: surface,
            profileId: profile.id,
            locale: locale,
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
            // Access current user record ID on main actor for HouseholdContext
            // Use nonisolated read from cached value
            let context = HouseholdContext(
                profile: profile,
                currentUserRecordID: UserIdentityStore.cachedCurrentUserRecordID
            )
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

        case .sentiment:
            // Build sentiment context from provider if available
            if let state = sentimentStateProvider?() {
                return AnyCodable(UserSentimentContext(state: state))
            }
            return nil

        case .behavior:
            let interventions = behaviorInterventionProvider?() ?? []
            return AnyCodable(BehaviorChallengesContext(events: events, interventions: interventions))
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

/// Type-erased Codable wrapper using a recursive enum to preserve JSON structure.
/// This avoids the decode-reencode cycle that can corrupt data.
struct AnyCodable: Codable, Sendable {
    private let jsonValue: JSONValue

    /// Access the decoded value as a Foundation object (for compatibility with existing code)
    var value: Any? {
        jsonValue.toFoundation()
    }

    init<T: Codable & Sendable>(_ value: T) {
        // Encode to JSON and decode back as JSONValue to normalize
        if let data = try? JSONEncoder().encode(value),
           let decoded = try? JSONDecoder().decode(JSONValue.self, from: data) {
            self.jsonValue = decoded
        } else {
            self.jsonValue = .null
        }
    }

    /// Initialize directly from a JSONValue
    init(jsonValue: JSONValue) {
        self.jsonValue = jsonValue
    }

    /// Initialize from pre-encoded JSON data
    init(data: Data) {
        if let decoded = try? JSONDecoder().decode(JSONValue.self, from: data) {
            self.jsonValue = decoded
        } else {
            self.jsonValue = .null
        }
    }

    init(from decoder: Decoder) throws {
        self.jsonValue = try JSONValue(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try jsonValue.encode(to: encoder)
    }
}

/// Recursive enum representing any valid JSON value
enum JSONValue: Codable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    /// Convert to Foundation types for compatibility with JSONSerialization-based code
    func toFoundation() -> Any {
        switch self {
        case .null:
            return NSNull()
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
        case .array(let value):
            return value.map { $0.toFoundation() }
        case .object(let value):
            return value.mapValues { $0.toFoundation() }
        }
    }
}
