//
//  AINudgeOrchestrator.swift
//  Otis-app
//
//  Central AI nudge orchestration with deterministic fallback.
//

import Foundation
import os
import OtisShared

private let aiLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.otis", category: "AINudgeOrchestrator")

@MainActor
final class AINudgeOrchestrator {
    static let shared = AINudgeOrchestrator()

    let client: AIModelBrokerClientProtocol
    let subscriptionManager: SubscriptionManager
    let logger = aiLogger

    enum BundleKind: String {
        case insight
        case notificationPolicy
    }

    // MARK: - Internal Storage (accessible by extensions)

    var insightCache: [String: CacheEntry<AIInsightBundleDecision>] = [:]
    var notificationPolicyCache: [String: CacheEntry<AINotificationPolicyDecision>] = [:]
    var pendingRecommendations: [UUID: [AILoggingCategoryRecommendation]] = [:]
    var inFlightRefreshTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Initialization

    private init(
        client: AIModelBrokerClientProtocol = AIModelBrokerClient(),
        subscriptionManager: SubscriptionManager = .shared
    ) {
        self.client = client
        self.subscriptionManager = subscriptionManager
    }

    // MARK: - Public API

    func dailyStatusCopy(
        profile: PuppyProfile,
        baselineTitle: String,
        baselineSubtitle: String?,
        prediction: PottyPrediction,
        sleepState: SleepState,
        recentEvents: [PuppyEvent]
    ) -> (title: String, subtitle: String?) {
        guard canUseAI(for: profile) else {
            logger.debug("dailyStatusCopy: canUseAI returned false")
            return (baselineTitle, baselineSubtitle)
        }

        let cacheKey = insightCacheKey(profileID: profile.id)
        logger.debug("dailyStatusCopy: checking cache key \(cacheKey)")
        if let cached = getCachedInsight(for: cacheKey) {
            logger.debug("dailyStatusCopy: cache HIT, headline=\(cached.value.dailyStatusDecision?.headline ?? "nil")")
            return applyOrFallbackDailyStatus(
                cached.value.dailyStatusDecision,
                baselineTitle: baselineTitle,
                baselineSubtitle: baselineSubtitle
            )
        }

        logger.debug("dailyStatusCopy: cache MISS, returning baseline")
        return (baselineTitle, baselineSubtitle)
    }

    func reorderUpcomingItems(
        profile: PuppyProfile,
        actionable: [ActionableItem],
        upcoming: [UpcomingItem],
        recentEvents: [PuppyEvent]
    ) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        guard canUseAI(for: profile) else {
            logger.debug("reorderUpcomingItems: canUseAI returned false")
            return (actionable, upcoming)
        }

        let cacheKey = insightCacheKey(profileID: profile.id)
        logger.debug("reorderUpcomingItems: checking cache key \(cacheKey)")
        if let cached = getCachedInsight(for: cacheKey) {
            logger.debug("reorderUpcomingItems: cache HIT")
            return applyOrFallbackOrdering(
                decision: cached.value.walkOrderingDecision,
                actionable: actionable,
                upcoming: upcoming
            )
        }

        logger.debug("reorderUpcomingItems: cache MISS, scheduling refresh")
        scheduleInsightRefreshIfNeeded(
            profile: profile,
            baselineTitle: PredictionCalculations.displayText(for: pottyPredictionFromEvents(recentEvents), puppyName: profile.name),
            baselineSubtitle: PredictionCalculations.subtitleText(for: pottyPredictionFromEvents(recentEvents)),
            prediction: pottyPredictionFromEvents(recentEvents),
            sleepState: SleepCalculations.currentSleepState(events: recentEvents),
            actionable: actionable,
            upcoming: upcoming,
            recentEvents: recentEvents
        )

        return (actionable, upcoming)
    }

    func notificationPolicyAdjustment(
        kind: AINotificationKind,
        baselineMinutesUntilFire: Int,
        profile: PuppyProfile,
        recentEvents: [PuppyEvent],
        isUrgent: Bool,
        allowSkip: Bool
    ) -> (minutesUntilFire: Int, skip: Bool) {
        guard canUseAI(for: profile) else {
            return (baselineMinutesUntilFire, false)
        }

        scheduleNotificationPolicyRefreshIfNeeded(profile: profile, recentEvents: recentEvents)

        let cacheKey = notificationPolicyCacheKey(profileID: profile.id)
        let policy = getCachedNotificationPolicy(for: cacheKey)?.value
        return applyNotificationPolicy(
            policy: policy,
            kind: kind,
            baselineMinutesUntilFire: baselineMinutesUntilFire,
            isUrgent: isUrgent,
            allowSkip: allowSkip
        )
    }

    func pendingLoggingRecommendations(for profileID: UUID) -> [AILoggingCategoryRecommendation] {
        // Only show one recommendation per day total (not per category)
        guard !wasRecommendationShownToday(profileID: profileID) else {
            return []
        }

        // Filter out categories that were already actioned today
        return getPendingRecommendations(for: profileID).filter { recommendation in
            !wasRecommendationActioned(profileID: profileID, category: recommendation.category)
        }
    }

    func markRecommendationApplied(profileID: UUID, category: AILoggingCategory) {
        markRecommendationAction(profileID: profileID, category: category, action: "applied")
        markRecommendationShownToday(profileID: profileID)
        removePendingRecommendation(profileID: profileID, category: category)
    }

    func markRecommendationDismissed(profileID: UUID, category: AILoggingCategory) {
        markRecommendationAction(profileID: profileID, category: category, action: "dismissed")
        markRecommendationShownToday(profileID: profileID)
        removePendingRecommendation(profileID: profileID, category: category)
    }
}

// MARK: - Background Refresh Tasks

extension AINudgeOrchestrator {

    func scheduleInsightRefreshIfNeeded(
        profile: PuppyProfile,
        baselineTitle: String,
        baselineSubtitle: String?,
        prediction: PottyPrediction,
        sleepState: SleepState,
        actionable: [ActionableItem],
        upcoming: [UpcomingItem],
        recentEvents: [PuppyEvent]
    ) {
        let cacheKey = insightCacheKey(profileID: profile.id)
        if let cached = getCachedInsight(for: cacheKey), isFresh(cached.updatedAt, maxAgeMinutes: 360) {
            logger.debug("scheduleInsightRefreshIfNeeded: cache is fresh, skipping")
            return
        }

        let dedupeKey = "insight-\(profile.id.uuidString)-\(Date().windowStamp(hours: 6))"
        guard !hasInFlightTask(for: dedupeKey) else {
            logger.debug("scheduleInsightRefreshIfNeeded: already in-flight, skipping")
            return
        }
        guard consumeBudgetIfAvailable(profileID: profile.id, kind: .insight) else {
            logger.debug("scheduleInsightRefreshIfNeeded: budget exhausted")
            Analytics.trackAIDecision(
                surface: .insightBundle,
                applied: false,
                fallbackReason: "budget_exhausted",
                confidence: nil,
                provider: nil,
                model: nil,
                latencyMs: nil,
                shadowMode: AINudgeRollout.isShadowMode
            )
            return
        }

        logger.debug("scheduleInsightRefreshIfNeeded: starting background refresh task")
        let task = Task { [weak self] in
            guard let self else { return }
            await self.refreshInsightBundle(
                profile: profile,
                cacheKey: cacheKey,
                baselineTitle: baselineTitle,
                baselineSubtitle: baselineSubtitle,
                prediction: prediction,
                sleepState: sleepState,
                actionable: actionable,
                upcoming: upcoming,
                recentEvents: recentEvents
            )
            await MainActor.run {
                self.clearInFlightTask(for: dedupeKey)
            }
        }
        setInFlightTask(task, for: dedupeKey)
    }

    func refreshInsightBundle(
        profile: PuppyProfile,
        cacheKey: String,
        baselineTitle: String,
        baselineSubtitle: String?,
        prediction: PottyPrediction,
        sleepState: SleepState,
        actionable: [ActionableItem],
        upcoming: [UpcomingItem],
        recentEvents: [PuppyEvent]
    ) async {
        let actionablePayload = actionable.map {
            AINudgeBrokerRequest.WalkSortItem(
                id: stableUpcomingID($0.item),
                itemType: $0.item.itemType.eventType.rawValue,
                label: $0.item.localizedLabel,
                minutesUntil: $0.item.minutesUntil,
                state: stateKey($0.state)
            )
        }
        let upcomingPayload = upcoming.map {
            AINudgeBrokerRequest.WalkSortItem(
                id: stableUpcomingID($0),
                itemType: $0.itemType.eventType.rawValue,
                label: $0.localizedLabel,
                minutesUntil: $0.minutesUntil,
                state: nil
            )
        }

        let request = AINudgeBrokerRequest(
            surface: .insightBundle,
            profileId: profile.id,
            locale: profile.preferredLocale ?? Locale.current.identifier,
            policyVersion: "v1",
            promptVersion: "nudge_insight_bundle_v2",
            providerPolicy: defaultProviderPolicy,
            shadowMode: AINudgeRollout.isShadowMode,
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
                        actionable: actionablePayload,
                        upcoming: upcomingPayload
                    ),
                    trainingProgressSummary: nil,
                    socializationProgressSummary: nil
                ),
                notificationPolicy: nil
            )
        )

        let rawURL = UserDefaults.standard.string(forKey: "ai.nudges.brokerBaseURL")
        let rawKey = UserDefaults.standard.string(forKey: "ai.nudges.brokerApiKey")
        logger.debug("refreshInsightBundle: rawURL=\(rawURL ?? "nil"), rawKeyLen=\(rawKey?.count ?? 0)")
        logger.debug("refreshInsightBundle: brokerBaseURL=\(AINudgeRollout.brokerBaseURL?.absoluteString ?? "nil")")
        logger.debug("refreshInsightBundle: sending request to broker")
        let start = Date()
        do {
            let response = try await client.decide(request)
            logger.debug("refreshInsightBundle: got response, provider=\(response.providerUsed ?? "nil"), hasDecision=\(response.effectiveInsightDecision != nil)")
            if let decision = response.effectiveInsightDecision {
                logger.debug("refreshInsightBundle: decision confidence=\(decision.confidence), headline=\(decision.dailyStatusDecision?.headline ?? "nil")")
                setCachedInsight(decision, for: cacheKey)
                setPendingRecommendations(decision.loggingRecommendations, for: profile.id)
                Analytics.trackAIDecision(
                    surface: .insightBundle,
                    applied: !AINudgeRollout.isShadowMode && decision.confidence >= 0.65,
                    fallbackReason: nil,
                    confidence: decision.confidence,
                    provider: response.providerUsed,
                    model: response.modelUsed,
                    latencyMs: Date().millisecondsSince(start),
                    shadowMode: AINudgeRollout.isShadowMode
                )
                logger.debug("refreshInsightBundle: cached decision successfully")
            } else {
                logger.debug("refreshInsightBundle: response had no insightBundleDecision")
            }
        } catch let brokerError as AIModelBrokerError {
            switch brokerError {
            case .brokerNotConfigured:
                logger.error("refreshInsightBundle: BROKER NOT CONFIGURED (but URL was: \(rawURL ?? "nil"))")
            case .brokerKeyNotConfigured:
                logger.error("refreshInsightBundle: BROKER KEY NOT CONFIGURED")
            case .invalidResponse(let statusCode, let body):
                logger.error("refreshInsightBundle: INVALID RESPONSE HTTP \(statusCode): \(body.prefix(200))")
            case .decodingFailed(let decodingError, let rawBody):
                logger.error("refreshInsightBundle: DECODING FAILED: \(decodingError.localizedDescription), raw: \(rawBody.prefix(500))")
            }
            Analytics.trackAIDecision(
                surface: .insightBundle,
                applied: false,
                fallbackReason: "request_failed",
                confidence: nil,
                provider: nil,
                model: nil,
                latencyMs: Date().millisecondsSince(start),
                shadowMode: AINudgeRollout.isShadowMode
            )
        } catch {
            logger.error("refreshInsightBundle: OTHER ERROR: \(type(of: error)) - \(error.localizedDescription)")
            Analytics.trackAIDecision(
                surface: .insightBundle,
                applied: false,
                fallbackReason: "request_failed",
                confidence: nil,
                provider: nil,
                model: nil,
                latencyMs: Date().millisecondsSince(start),
                shadowMode: AINudgeRollout.isShadowMode
            )
        }
    }

    func scheduleNotificationPolicyRefreshIfNeeded(
        profile: PuppyProfile,
        recentEvents: [PuppyEvent]
    ) {
        let cacheKey = notificationPolicyCacheKey(profileID: profile.id)
        if let cached = getCachedNotificationPolicy(for: cacheKey), isFresh(cached.updatedAt, maxAgeMinutes: 240) {
            return
        }

        let dedupeKey = "notif-\(profile.id.uuidString)-\(Date().windowStamp(hours: 4))"
        guard !hasInFlightTask(for: dedupeKey) else { return }
        guard consumeBudgetIfAvailable(profileID: profile.id, kind: .notificationPolicy) else {
            Analytics.trackAIDecision(
                surface: .notificationPolicy,
                applied: false,
                fallbackReason: "budget_exhausted",
                confidence: nil,
                provider: nil,
                model: nil,
                latencyMs: nil,
                shadowMode: AINudgeRollout.isShadowMode
            )
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            await self.refreshNotificationPolicy(profile: profile, cacheKey: cacheKey, recentEvents: recentEvents)
            await MainActor.run {
                self.clearInFlightTask(for: dedupeKey)
            }
        }
        setInFlightTask(task, for: dedupeKey)
    }

    func refreshNotificationPolicy(
        profile: PuppyProfile,
        cacheKey: String,
        recentEvents: [PuppyEvent]
    ) async {
        let staleCategories = inferStaleCategories(from: recentEvents)

        let request = AINudgeBrokerRequest(
            surface: .notificationPolicy,
            profileId: profile.id,
            locale: profile.preferredLocale ?? Locale.current.identifier,
            policyVersion: "v1",
            promptVersion: "nudge_notification_policy_v2",
            providerPolicy: defaultProviderPolicy,
            shadowMode: AINudgeRollout.isShadowMode,
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

        let start = Date()
        do {
            let response = try await client.decide(request)
            if let policy = response.notificationPolicyDecision {
                setCachedNotificationPolicy(policy, for: cacheKey)
                Analytics.trackAIDecision(
                    surface: .notificationPolicy,
                    applied: !AINudgeRollout.isShadowMode && policy.confidence >= 0.65,
                    fallbackReason: nil,
                    confidence: policy.confidence,
                    provider: response.providerUsed,
                    model: response.modelUsed,
                    latencyMs: Date().millisecondsSince(start),
                    shadowMode: AINudgeRollout.isShadowMode
                )
            }
        } catch {
            Analytics.trackAIDecision(
                surface: .notificationPolicy,
                applied: false,
                fallbackReason: "request_failed",
                confidence: nil,
                provider: nil,
                model: nil,
                latencyMs: Date().millisecondsSince(start),
                shadowMode: AINudgeRollout.isShadowMode
            )
        }
    }
}
