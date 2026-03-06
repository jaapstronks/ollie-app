//
//  AIOrchestrator.swift
//  Ollie-app
//
//  Refactored AI orchestration using modular context components.
//  Handles caching, budget limits, rollout, and surface-specific logic.
//

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

    private var responseCache: [String: CacheEntry] = [:]
    private var inFlightTasks: [String: Task<Void, Never>] = [:]

    private struct CacheEntry {
        let surface: AISurface
        let response: AIBrokerResponse
        let timestamp: Date
    }

    // MARK: - Init

    private init(
        client: AIModelBrokerClientProtocol = AIModelBrokerClient(),
        subscriptionManager: SubscriptionManager = .shared
    ) {
        self.client = client
        self.subscriptionManager = subscriptionManager
        self.contextBuilder = AIContextBuilder()
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

        // Check cache
        let cacheKey = cacheKey(surface: surface, profileId: profile.id)
        if let cached = validCachedResponse(for: cacheKey, surface: surface) {
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

            // Cache response
            responseCache[cacheKey] = CacheEntry(
                surface: surface,
                response: response,
                timestamp: Date()
            )

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
        let cacheKey = cacheKey(surface: surface, profileId: profileId)
        guard let cached = validCachedResponse(for: cacheKey, surface: surface) else {
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
        let cacheKey = cacheKey(surface: surface, profileId: profile.id)

        // Already cached and fresh
        if validCachedResponse(for: cacheKey, surface: surface) != nil {
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
        responseCache.removeAll()
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

    func cacheKey(surface: AISurface, profileId: UUID) -> String {
        let window = Date().windowStamp(hours: surface.cacheDurationMinutes / 60)
        return "\(profileId.uuidString)-\(surface.rawValue)-\(window)"
    }

    func validCachedResponse(for key: String, surface: AISurface) -> AIBrokerResponse? {
        guard let entry = responseCache[key] else { return nil }
        let age = Date().timeIntervalSince(entry.timestamp)
        let maxAge = TimeInterval(surface.cacheDurationMinutes * 60)
        return age < maxAge ? entry.response : nil
    }

    func consumeBudgetIfAvailable(profileId: UUID, surface: AISurface) -> Bool {
        let day = Date().dayStamp()
        let key = "ai.budget.\(profileId.uuidString).\(day).\(surface.rawValue)"
        let current = UserDefaults.standard.integer(forKey: key)

        guard current < surface.maxCallsPerDay else { return false }

        // Check total daily budget
        let totalKey = "ai.budget.\(profileId.uuidString).\(day).total"
        let total = UserDefaults.standard.integer(forKey: totalKey)
        guard total < AINudgeRollout.maxTotalCallsPerDay else { return false }

        UserDefaults.standard.set(current + 1, forKey: key)
        UserDefaults.standard.set(total + 1, forKey: totalKey)
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
            recentPottyCount: 0
        )

        return AINudgeBrokerRequest(
            surface: legacySurface(request.surface),
            profileId: request.profileId,
            locale: request.locale,
            policyVersion: request.policyVersion,
            promptVersion: request.promptVersion,
            providerPolicy: request.providerPolicy,
            shadowMode: request.shadowMode,
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

enum AIError: Error {
    case brokerError(String)
}

// MARK: - Helper Types

private struct EmptyResponse: Codable {}

private extension Date {
    func dayStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

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
