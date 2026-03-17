//
//  AINudgeOrchestrator+Debug.swift
//  Otis-app
//
//  Debug and testing methods for AI nudge orchestration.
//

import Foundation
import OtisShared
import os

#if DEBUG
// MARK: - Manual Test Methods (DEBUG only)

extension AINudgeOrchestrator {

    /// Manually trigger an insight bundle request for testing.
    /// Bypasses caching, budget limits, and rollout checks.
    func testInsightBundle(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> AITestResult {
        let start = Date()

        // Build baseline data from current state
        let prediction = pottyPredictionFromEvents(recentEvents)
        let sleepState = SleepCalculations.currentSleepState(events: recentEvents)
        let baselineTitle = PredictionCalculations.displayText(for: prediction, puppyName: profile.name)
        let baselineSubtitle = PredictionCalculations.subtitleText(for: prediction)

        // Build mock actionable/upcoming items for testing
        let actionable: [AINudgeBrokerRequest.WalkSortItem] = []
        let upcoming: [AINudgeBrokerRequest.WalkSortItem] = [
            .init(id: "walk|morning|\(Date().timeIntervalSince1970)", itemType: "uitlaten", label: "Morning walk", minutesUntil: 30, state: nil),
            .init(id: "meal|lunch|\(Date().timeIntervalSince1970)", itemType: "eten", label: "Lunch", minutesUntil: 120, state: nil)
        ]

        let request = AINudgeBrokerRequest(
            surface: .insightBundle,
            profileId: profile.id,
            locale: profile.preferredLocale ?? Locale.current.identifier,
            policyVersion: "v1",
            promptVersion: "nudge_insight_bundle_v2",
            providerPolicy: defaultProviderPolicy,
            shadowMode: false, // Force shadow mode off for testing
            systemInstruction: AIInstructions.systemInstruction(for: AINudgeSurface.insightBundle),
            outputFormat: AIInstructions.outputFormat(for: AINudgeSurface.insightBundle),
            context: buildContext(profile: profile, recentEvents: recentEvents),
            payload: .init(
                insightBundle: .init(
                    dailyStatus: .init(
                        baselineTitle: baselineTitle,
                        baselineSubtitle: baselineSubtitle,
                        pottyUrgency: String(describing: prediction.urgency),
                        isSleeping: sleepState.isSleeping
                    ),
                    walkSorting: .init(
                        actionable: actionable,
                        upcoming: upcoming
                    ),
                    trainingProgressSummary: nil,
                    socializationProgressSummary: nil
                ),
                notificationPolicy: nil
            )
        )

        do {
            let response = try await client.decide(request)
            let latency = Int(Date().timeIntervalSince(start) * 1000)

            return AITestResult(
                surface: .insightBundle,
                timestamp: Date(),
                latencyMs: latency,
                provider: response.providerUsed,
                model: response.modelUsed,
                reasoningTags: response.reasoningTags ?? [],
                rawResponse: response,
                error: nil
            )
        } catch {
            let latency = Int(Date().timeIntervalSince(start) * 1000)
            return AITestResult(
                surface: .insightBundle,
                timestamp: Date(),
                latencyMs: latency,
                provider: nil,
                model: nil,
                reasoningTags: [],
                rawResponse: AINudgeBrokerResponse(
                    providerUsed: nil,
                    modelUsed: nil,
                    reasoningTags: nil,
                    insightBundleDecision: nil,
                    notificationPolicyDecision: nil,
                    response: nil
                ),
                error: error.localizedDescription
            )
        }
    }

    /// Manually trigger a notification policy request for testing.
    /// Bypasses caching, budget limits, and rollout checks.
    func testNotificationPolicy(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) async -> AITestResult {
        let start = Date()

        let staleCategories = inferStaleCategories(from: recentEvents)

        let request = AINudgeBrokerRequest(
            surface: .notificationPolicy,
            profileId: profile.id,
            locale: profile.preferredLocale ?? Locale.current.identifier,
            policyVersion: "v1",
            promptVersion: "nudge_notification_policy_v2",
            providerPolicy: defaultProviderPolicy,
            shadowMode: false, // Force shadow mode off for testing
            systemInstruction: AIInstructions.systemInstruction(for: AINudgeSurface.notificationPolicy),
            outputFormat: AIInstructions.outputFormat(for: AINudgeSurface.notificationPolicy),
            context: buildContext(profile: profile, recentEvents: recentEvents),
            payload: .init(
                insightBundle: nil,
                notificationPolicy: .init(
                    baselinePottyMinutesDelta: 0,
                    baselineWalkMinutesDelta: 0,
                    staleCategories: staleCategories
                )
            )
        )

        do {
            let response = try await client.decide(request)
            let latency = Int(Date().timeIntervalSince(start) * 1000)

            return AITestResult(
                surface: .notificationPolicy,
                timestamp: Date(),
                latencyMs: latency,
                provider: response.providerUsed,
                model: response.modelUsed,
                reasoningTags: response.reasoningTags ?? [],
                rawResponse: response,
                error: nil
            )
        } catch {
            let latency = Int(Date().timeIntervalSince(start) * 1000)
            return AITestResult(
                surface: .notificationPolicy,
                timestamp: Date(),
                latencyMs: latency,
                provider: nil,
                model: nil,
                reasoningTags: [],
                rawResponse: AINudgeBrokerResponse(
                    providerUsed: nil,
                    modelUsed: nil,
                    reasoningTags: nil,
                    insightBundleDecision: nil,
                    notificationPolicyDecision: nil,
                    response: nil
                ),
                error: error.localizedDescription
            )
        }
    }

    /// Clear all cached AI decisions (useful for re-testing)
    func clearCache() {
        insightCache.removeAll()
        notificationPolicyCache.removeAll()
        pendingRecommendations.removeAll()
    }

    /// Reset daily budget counters and recommendation limiters (useful for re-testing)
    func resetBudget() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(Self.callCountKeyPrefix) {
            defaults.removeObject(forKey: key)
        }
        // Also clear recommendation shown today keys and per-category action keys
        for key in allKeys where key.hasPrefix(Self.recommendationShownTodayKeyPrefix) {
            defaults.removeObject(forKey: key)
        }
        for key in allKeys where key.hasPrefix(Self.recommendationActionKeyPrefix) {
            defaults.removeObject(forKey: key)
        }
        logger.debug("resetBudget: cleared all budget counters and recommendation limiters")
    }
}
#endif
