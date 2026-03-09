//
//  AIOrchestrator.swift
//  Ollie-app
//
//  Refactored AI orchestration using modular context components.
//  Handles caching, budget limits, rollout, and surface-specific logic.
//

@preconcurrency import CoreData
import Foundation
import OtisShared

// MARK: - AI Orchestrator

/// Central orchestration for AI-powered features.
/// Uses modular context components for efficient, surface-specific context assembly.
@MainActor
final class AIOrchestrator {
    static let shared = AIOrchestrator()

    // MARK: - Dependencies

    private let client: AIModelBrokerClientProtocol
    private let subscriptionManager: SubscriptionManager
    private let contextBuilder: AIContextBuilder

    // MARK: - State

    private var inFlightTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Init

    private init(
        client: AIModelBrokerClientProtocol = AIModelBrokerClient(),
        subscriptionManager: SubscriptionManager = .shared
    ) {
        self.client = client
        self.subscriptionManager = subscriptionManager
        self.contextBuilder = AIContextBuilder()

        // Cleanup expired cache entries on startup
        Task {
            let context = PersistenceController.shared.newBackgroundContext()
            context.perform {
                CDAICache.cleanupExpired(in: context)
                try? context.save()
            }
        }
    }

    // MARK: - Public API

    /// Request AI guidance for a specific surface.
    /// Returns cached result if available and fresh, otherwise triggers async refresh.
    func request<Response: Codable>(
        surface: AISurface,
        profile: PuppyProfile,
        recentEvents: [PuppyEvent],
        prediction: PottyPrediction? = nil,
        gapStats: GapStats? = nil,
        sleepState: SleepState? = nil,
        surfacePayload: Encodable? = nil,
        responseType: Response.Type
    ) async -> AIResult<Response> {
        // Check access
        guard canUseAI(for: profile) else {
            return .fallback(reason: .notEligible)
        }

        // Check cache (CloudKit-synced Core Data)
        if let cached = validCachedResponse(for: surface, profileId: profile.id) {
            return decodeResponse(cached, as: responseType)
        }

        // Check budget
        guard consumeBudgetIfAvailable(profileId: profile.id, surface: surface) else {
            Analytics.trackAIDecision(
                surface: legacySurface(surface),
                applied: false,
                fallbackReason: "budget_exhausted",
                confidence: nil,
                provider: nil,
                model: nil,
                latencyMs: nil,
                shadowMode: AINudgeRollout.isShadowMode
            )
            return .fallback(reason: .budgetExhausted)
        }

        // Build context
        let context = contextBuilder.buildContext(
            for: surface,
            profile: profile,
            recentEvents: recentEvents,
            prediction: prediction,
            gapStats: gapStats,
            sleepState: sleepState
        )

        // Build request
        let request = AIInstructions.buildBrokerRequest(
            surface: surface,
            context: context,
            providerPolicy: defaultProviderPolicy,
            shadowMode: AINudgeRollout.isShadowMode,
            surfacePayload: surfacePayload
        )

        // Execute
        let start = Date()
        do {
            let response = try await executeBrokerRequest(request)
            let latencyMs = Int(Date().timeIntervalSince(start) * 1000)

            // Cache response (CloudKit-synced Core Data)
            cacheResponse(response, surface: surface, profileId: profile.id)

            // Track analytics
            let confidence = extractConfidence(from: response)
            let applied = !AINudgeRollout.isShadowMode && (confidence ?? 0) >= surface.confidenceThreshold
            Analytics.trackAIDecision(
                surface: legacySurface(surface),
                applied: applied,
                fallbackReason: applied ? nil : "shadow_or_low_confidence",
                confidence: confidence,
                provider: response.providerUsed,
                model: response.modelUsed,
                latencyMs: latencyMs,
                shadowMode: AINudgeRollout.isShadowMode
            )

            return decodeResponse(response, as: responseType)
        } catch {
            let latencyMs = Int(Date().timeIntervalSince(start) * 1000)
            Analytics.trackAIDecision(
                surface: legacySurface(surface),
                applied: false,
                fallbackReason: "request_failed",
                confidence: nil,
                provider: nil,
                model: nil,
                latencyMs: latencyMs,
                shadowMode: AINudgeRollout.isShadowMode
            )
            return .fallback(reason: .requestFailed(error))
        }
    }

    /// Synchronously get cached result if available (for UI rendering).
    func cachedResult<Response: Codable>(
        surface: AISurface,
        profileId: UUID,
        responseType: Response.Type
    ) -> Response? {
        guard let cached = validCachedResponse(for: surface, profileId: profileId) else {
            return nil
        }

        if case .success(let response) = decodeResponse(cached, as: responseType) {
            return response
        }
        return nil
    }

    /// Schedule background refresh without blocking.
    func scheduleRefreshIfNeeded(
        surface: AISurface,
        profile: PuppyProfile,
        recentEvents: [PuppyEvent],
        prediction: PottyPrediction? = nil,
        gapStats: GapStats? = nil,
        sleepState: SleepState? = nil,
        surfacePayload: Encodable? = nil
    ) {
        // Already cached and fresh
        if validCachedResponse(for: surface, profileId: profile.id) != nil {
            return
        }

        // Already in flight
        let dedupeKey = "\(surface.rawValue)-\(profile.id.uuidString)-\(Date().windowStamp(hours: 1))"
        guard inFlightTasks[dedupeKey] == nil else { return }

        // Schedule background task
        let task = Task { [weak self] in
            guard let self else { return }

            // Use Void response type for background refresh
            _ = await self.request(
                surface: surface,
                profile: profile,
                recentEvents: recentEvents,
                prediction: prediction,
                gapStats: gapStats,
                sleepState: sleepState,
                surfacePayload: surfacePayload,
                responseType: EmptyResponse.self
            )

            await MainActor.run {
                self.inFlightTasks[dedupeKey] = nil
            }
        }
        inFlightTasks[dedupeKey] = task
    }

    /// Clear all cached responses.
    func clearCache() {
        let context = PersistenceController.shared.newBackgroundContext()
        context.perform {
            let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")
            if let entries = try? context.fetch(request) {
                entries.forEach { context.delete($0) }
            }
            try? context.save()
        }
    }

    /// Get a cached response for a surface without making a request.
    /// Returns nil if no valid cache entry exists.
    func cachedResponse<Response: Codable>(surface: AISurface, profileId: UUID) -> Response? {
        guard let brokerResponse = validCachedResponse(for: surface, profileId: profileId) else {
            return nil
        }

        // Try decoding from the parsed response first
        if let data = try? JSONEncoder().encode(brokerResponse.response),
           let response = try? JSONDecoder().decode(Response.self, from: data) {
            return response
        }

        // Fall back to raw response string
        guard let rawString = brokerResponse.rawResponse,
              let data = rawString.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(Response.self, from: data)
    }

    // MARK: - Provider Registration

    /// Register data providers for context building.
    func registerSkillProgressProvider(_ provider: @escaping () -> [SkillProgress]) {
        contextBuilder.registerSkillProgressProvider(provider)
    }

    func registerRegressionLogProvider(_ provider: @escaping () -> [RegressionLogEntry]) {
        contextBuilder.registerRegressionLogProvider(provider)
    }

    func registerSocializationProgressProvider(_ provider: @escaping (PuppyProfile) -> SocializationProgress?) {
        contextBuilder.registerSocializationProgressProvider(provider)
    }

    func registerBehaviorInterventionProvider(_ provider: @escaping () -> [BehaviorIntervention]) {
        contextBuilder.registerBehaviorInterventionProvider(provider)
    }

    func registerSentimentStateProvider(_ provider: @escaping () -> SentimentState?) {
        contextBuilder.registerSentimentStateProvider(provider)
    }
}

// MARK: - Private Helpers

private extension AIOrchestrator {

    var defaultProviderPolicy: AIVendorPolicy {
        .init(preferredOrder: [.anthropic, .mistral], allowFailover: true)
    }

    func canUseAI(for profile: PuppyProfile) -> Bool {
        guard AINudgeRollout.isEnabled else { return false }
        guard subscriptionManager.hasAccess(to: .aiNudges) else { return false }
        let bucket = abs(profile.id.uuidString.hashValue) % 100
        return bucket < AINudgeRollout.rolloutPercentage
    }

    /// Fetch a valid cached response from Core Data (CloudKit-synced).
    func validCachedResponse(for surface: AISurface, profileId: UUID) -> AIBrokerResponse? {
        let context = PersistenceController.shared.viewContext
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else {
            return nil
        }
        guard let entry = CDAICache.fetchValid(surface: surface, profile: cdProfile, in: context),
              !entry.isExpired else {
            return nil
        }
        return entry.toResponse()
    }

    /// Cache a response to Core Data (CloudKit-synced).
    func cacheResponse(_ response: AIBrokerResponse, surface: AISurface, profileId: UUID) {
        let context = PersistenceController.shared.viewContext
        context.perform {
            guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else { return }
            CDAICache.upsert(surface: surface, response: response, profile: cdProfile, in: context)
            try? context.save()
        }
    }

    /// Check budget using Core Data counts (CloudKit-synced).
    func consumeBudgetIfAvailable(profileId: UUID, surface: AISurface) -> Bool {
        let context = PersistenceController.shared.viewContext
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else {
            return false
        }

        let surfaceCount = CDAICache.todayCallCount(surface: surface, profile: cdProfile, in: context)
        guard surfaceCount < surface.maxCallsPerDay else { return false }

        let totalCount = CDAICache.todayTotalCallCount(profile: cdProfile, in: context)
        guard totalCount < AINudgeRollout.maxTotalCallsPerDay else { return false }

        return true
    }

    func executeBrokerRequest(_ request: AIBrokerRequest) async throws -> AIBrokerResponse {
        // Convert to legacy request format for existing broker
        // TODO: Update broker to accept new request format directly
        let legacyRequest = convertToLegacyRequest(request)
        let legacyResponse = try await client.decide(legacyRequest)
        return convertFromLegacyResponse(legacyResponse)
    }

    func convertToLegacyRequest(_ request: AIBrokerRequest) -> AINudgeBrokerRequest {
        // Build legacy context summary from components
        let dogIdentity = request.context["dog_identity"]
        let recentEvents = request.context["recent_events"]

        let contextSummary = AINudgeContextSummary(
            ageWeeks: (dogIdentity?.value as? DogIdentityContext)?.ageWeeks ?? 0,
            daysHome: (dogIdentity?.value as? DogIdentityContext)?.daysHome ?? 0,
            recentEventCount: (recentEvents?.value as? RecentEventsSummary)?.eventsLast24h ?? 0,
            recentWalkCount: 0,
            recentMealCount: 0,
            recentPottyCount: 0,
            // Historical comparison not available in legacy conversion
            recentDaysWalkAvg: nil,
            priorDaysWalkAvg: nil,
            recentDaysMealAvg: nil,
            priorDaysMealAvg: nil,
            recentDaysPottyAvg: nil,
            priorDaysPottyAvg: nil,
            recentDaysTrainingAvg: nil,
            priorDaysTrainingAvg: nil
        )

        return AINudgeBrokerRequest(
            surface: legacySurface(request.surface),
            profileId: request.profileId,
            locale: request.locale,
            policyVersion: request.policyVersion,
            promptVersion: request.promptVersion,
            providerPolicy: request.providerPolicy,
            shadowMode: request.shadowMode,
            systemInstruction: request.systemInstruction,
            outputFormat: request.outputFormat,
            context: contextSummary,
            payload: .init(insightBundle: nil, notificationPolicy: nil)
        )
    }

    func convertFromLegacyResponse(_ response: AINudgeBrokerResponse) -> AIBrokerResponse {
        // Encode the response to get raw JSON
        let rawJSON = try? JSONEncoder().encode(response)
        let rawString = rawJSON.flatMap { String(data: $0, encoding: .utf8) }

        return AIBrokerResponse(
            providerUsed: response.providerUsed,
            modelUsed: response.modelUsed,
            reasoningTags: response.reasoningTags,
            response: AnyCodable(response),
            rawResponse: rawString,
            error: nil
        )
    }

    func legacySurface(_ surface: AISurface) -> AINudgeSurface {
        switch surface {
        case .insightBundle: return .insightBundle
        case .notificationPolicy: return .notificationPolicy
        default: return .insightBundle  // Map new surfaces to insight for analytics
        }
    }

    func decodeResponse<Response: Codable>(_ brokerResponse: AIBrokerResponse, as type: Response.Type) -> AIResult<Response> {
        // Check for error
        if let error = brokerResponse.error {
            return .fallback(reason: .requestFailed(AIError.brokerError(error)))
        }

        // Try to decode response
        do {
            let data = try JSONEncoder().encode(brokerResponse.response)
            let response = try JSONDecoder().decode(Response.self, from: data)

            // Check for shadow mode
            if response is AISurfaceResponse, AINudgeRollout.isShadowMode {
                return .shadow(response)
            }

            return .success(response)
        } catch {
            return .fallback(reason: .decodingFailed(error))
        }
    }

    func extractConfidence(from response: AIBrokerResponse) -> Double? {
        // Try to extract confidence from the response
        if let dict = response.response.value as? [String: Any],
           let confidence = dict["confidence"] as? Double {
            return confidence
        }
        return nil
    }
}

// MARK: - Result Type

/// Result of an AI request.
enum AIResult<Response> {
    case success(Response)
    case shadow(Response)  // In shadow mode, don't apply but return for logging
    case fallback(reason: AIFallbackReason)

    var response: Response? {
        switch self {
        case .success(let r), .shadow(let r): return r
        case .fallback: return nil
        }
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

enum AIFallbackReason {
    case notEligible
    case budgetExhausted
    case requestFailed(Error)
    case decodingFailed(Error)
    case lowConfidence(Double)

    var description: String {
        switch self {
        case .notEligible: return "not_eligible"
        case .budgetExhausted: return "budget_exhausted"
        case .requestFailed(let error): return "request_failed: \(error.localizedDescription)"
        case .decodingFailed(let error): return "decoding_failed: \(error.localizedDescription)"
        case .lowConfidence(let conf): return "low_confidence: \(conf)"
        }
    }
}

enum AIError: LocalizedError {
    case brokerError(String)

    var errorDescription: String? {
        switch self {
        case .brokerError(let message):
            return "Broker error: \(message)"
        }
    }
}

// MARK: - Helper Types

private struct EmptyResponse: Codable {}

private extension Date {
    func windowStamp(hours: Int) -> String {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: self)
        let hour = calendar.component(.hour, from: self)
        let bucket = max(1, hours)
        let window = hour / bucket
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: day))-\(window)"
    }
}

// MARK: - Manual Test Methods (DEBUG only)

#if DEBUG
extension AIOrchestrator {

    /// Test result for new AI surfaces
    struct NewAITestResult: Identifiable {
        let id: UUID = UUID()
        let surface: AISurface
        let timestamp: Date
        let latencyMs: Int
        let provider: String?
        let model: String?
        let reasoningTags: [String]
        let response: Any?
        let rawResponse: String?
        let error: String?

        var isSuccess: Bool { error == nil && response != nil }

        var summaryText: String {
            if let error = error {
                return "Error: \(error)"
            }
            if let response = response {
                if let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
                   let string = String(data: data, encoding: .utf8) {
                    return string
                }
                return String(describing: response)
            }
            return "No response"
        }
    }

    /// Manually trigger an insight bundle request for testing.
    func testInsightBundle(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> NewAITestResult {
        await testSurface(.insightBundle, profile: profile, recentEvents: recentEvents)
    }

    /// Manually trigger a notification policy request for testing.
    func testNotificationPolicy(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> NewAITestResult {
        await testSurface(.notificationPolicy, profile: profile, recentEvents: recentEvents)
    }

    /// Manually trigger a training guidance request for testing.
    func testTrainingGuidance(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> NewAITestResult {
        await testSurface(.trainingGuidance, profile: profile, recentEvents: recentEvents)
    }

    /// Manually trigger a potty analysis request for testing.
    func testPottyAnalysis(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> NewAITestResult {
        await testSurface(.pottyAnalysis, profile: profile, recentEvents: recentEvents)
    }

    /// Manually trigger a socialization guidance request for testing.
    func testSocializationGuidance(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> NewAITestResult {
        await testSurface(.socializationGuidance, profile: profile, recentEvents: recentEvents)
    }

    /// Manually trigger a health insights request for testing.
    func testHealthInsights(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> NewAITestResult {
        await testSurface(.healthInsights, profile: profile, recentEvents: recentEvents)
    }

    private func testSurface(
        _ surface: AISurface,
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> NewAITestResult {
        let start = Date()

        // Build context
        let contextPayload = contextBuilder.buildContext(
            for: surface,
            profile: profile,
            recentEvents: recentEvents
        )

        // Build request
        let request = AIInstructions.buildBrokerRequest(
            surface: surface,
            context: contextPayload,
            providerPolicy: AIVendorPolicy(preferredOrder: [.anthropic], allowFailover: true),
            shadowMode: false
        )

        do {
            // Encode and send request
            let jsonData = try JSONEncoder().encode(request)

            guard let baseURL = AINudgeRollout.brokerBaseURL else {
                throw AIError.brokerError("Invalid broker URL")
            }
            let brokerURL = baseURL.appendingPathComponent("ai/nudges/decide")

            var urlRequest = URLRequest(url: brokerURL)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(AINudgeRollout.brokerApiKey, forHTTPHeaderField: "X-API-Key")
            urlRequest.httpBody = jsonData
            urlRequest.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let body = String(data: data, encoding: .utf8) ?? ""
                throw AIError.brokerError("HTTP \(statusCode): \(body)")
            }

            let latency = Int(Date().timeIntervalSince(start) * 1000)

            // Parse response
            let brokerResponse = try JSONDecoder().decode(AIBrokerResponse.self, from: data)

            return NewAITestResult(
                surface: surface,
                timestamp: Date(),
                latencyMs: latency,
                provider: brokerResponse.providerUsed,
                model: brokerResponse.modelUsed,
                reasoningTags: brokerResponse.reasoningTags ?? [],
                response: brokerResponse.response.value,
                rawResponse: brokerResponse.rawResponse,
                error: brokerResponse.error
            )
        } catch {
            let latency = Int(Date().timeIntervalSince(start) * 1000)
            return NewAITestResult(
                surface: surface,
                timestamp: Date(),
                latencyMs: latency,
                provider: nil,
                model: nil,
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: error.localizedDescription
            )
        }
    }
}
#endif
