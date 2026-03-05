//
//  AINudgeOrchestrator.swift
//  Otis-app
//
//  Central AI nudge orchestration with deterministic fallback.
//

import Foundation
import OtisShared

@MainActor
final class AINudgeOrchestrator {
    static let shared = AINudgeOrchestrator()

    private let client: AIModelBrokerClientProtocol
    private let subscriptionManager: SubscriptionManager

    private struct CacheEntry<T> {
        let value: T
        let updatedAt: Date
    }

    enum BundleKind: String {
        case insight
        case notificationPolicy
    }

    private var insightCache: [String: CacheEntry<AIInsightBundleDecision>] = [:]
    private var notificationPolicyCache: [String: CacheEntry<AINotificationPolicyDecision>] = [:]
    private var pendingRecommendations: [UUID: [AILoggingCategoryRecommendation]] = [:]
    private var inFlightRefreshTasks: [String: Task<Void, Never>] = [:]
    private static let callCountKeyPrefix = "ai.nudges.callCount"
    private static let recommendationActionKeyPrefix = "ai.nudges.recommendationAction"

    private init(
        client: AIModelBrokerClientProtocol = AIModelBrokerClient(),
        subscriptionManager: SubscriptionManager = .shared
    ) {
        self.client = client
        self.subscriptionManager = subscriptionManager
    }

    func dailyStatusCopy(
        profile: PuppyProfile,
        baselineTitle: String,
        baselineSubtitle: String?,
        prediction: PottyPrediction,
        sleepState: SleepState,
        recentEvents: [PuppyEvent]
    ) -> (title: String, subtitle: String?) {
        guard canUseAI(for: profile) else {
            return (baselineTitle, baselineSubtitle)
        }

        // Copy lookup is read-only to avoid network on card rendering.
        let cacheKey = insightCacheKey(profileID: profile.id)
        if let cached = insightCache[cacheKey] {
            return applyOrFallbackDailyStatus(
                cached.value.dailyStatusDecision,
                baselineTitle: baselineTitle,
                baselineSubtitle: baselineSubtitle
            )
        }

        return (baselineTitle, baselineSubtitle)
    }

    func reorderUpcomingItems(
        profile: PuppyProfile,
        actionable: [ActionableItem],
        upcoming: [UpcomingItem],
        recentEvents: [PuppyEvent]
    ) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        guard canUseAI(for: profile) else {
            return (actionable, upcoming)
        }

        let cacheKey = insightCacheKey(profileID: profile.id)
        if let cached = insightCache[cacheKey] {
            return applyOrFallbackOrdering(
                decision: cached.value.walkOrderingDecision,
                actionable: actionable,
                upcoming: upcoming
            )
        }

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
        let policy = notificationPolicyCache[cacheKey]?.value
        return applyNotificationPolicy(
            policy: policy,
            kind: kind,
            baselineMinutesUntilFire: baselineMinutesUntilFire,
            isUrgent: isUrgent,
            allowSkip: allowSkip
        )
    }

    func pendingLoggingRecommendations(for profileID: UUID) -> [AILoggingCategoryRecommendation] {
        let day = Date().dayStamp()
        return (pendingRecommendations[profileID] ?? []).filter { recommendation in
            let key = recommendationActionKey(profileID: profileID, dayStamp: day, category: recommendation.category)
            return UserDefaults.standard.string(forKey: key) == nil
        }
    }

    func markRecommendationApplied(profileID: UUID, category: AILoggingCategory) {
        markRecommendationAction(profileID: profileID, category: category, action: "applied")
        removePendingRecommendation(profileID: profileID, category: category)
    }

    func markRecommendationDismissed(profileID: UUID, category: AILoggingCategory) {
        markRecommendationAction(profileID: profileID, category: category, action: "dismissed")
        removePendingRecommendation(profileID: profileID, category: category)
    }
}

// MARK: - Private Helpers

private extension AINudgeOrchestrator {
    var defaultProviderPolicy: AIVendorPolicy {
        .init(preferredOrder: [.anthropic, .mistral], allowFailover: true)
    }

    func canUseAI(for profile: PuppyProfile) -> Bool {
        guard AINudgeRollout.isEnabled else { return false }
        guard subscriptionManager.hasAccess(to: .aiNudges) else { return false }
        let bucket = abs(profile.id.uuidString.hashValue) % 100
        return bucket < AINudgeRollout.rolloutPercentage
    }

    func isFresh(_ date: Date, maxAgeMinutes: Int) -> Bool {
        Date().timeIntervalSince(date) < Double(maxAgeMinutes * 60)
    }

    func buildContext(profile: PuppyProfile, recentEvents: [PuppyEvent]) -> AINudgeContextSummary {
        .init(
            ageWeeks: profile.ageInWeeks,
            daysHome: profile.daysHome,
            recentEventCount: recentEvents.count,
            recentWalkCount: recentEvents.walks().count,
            recentMealCount: recentEvents.meals().count,
            recentPottyCount: recentEvents.pee().count
        )
    }

    func applyOrFallbackDailyStatus(
        _ decision: AIDailyStatusDecision?,
        baselineTitle: String,
        baselineSubtitle: String?
    ) -> (title: String, subtitle: String?) {
        guard let decision else {
            return (baselineTitle, baselineSubtitle)
        }
        let canApply = !AINudgeRollout.isShadowMode && decision.confidence >= 0.65
        Analytics.trackAIDecision(
            surface: .insightBundle,
            applied: canApply,
            fallbackReason: canApply ? nil : "shadow_or_low_confidence",
            confidence: decision.confidence,
            provider: nil,
            model: nil,
            latencyMs: nil,
            shadowMode: AINudgeRollout.isShadowMode
        )
        if canApply {
            return (decision.headline, decision.subtitle ?? baselineSubtitle)
        }
        return (baselineTitle, baselineSubtitle)
    }

    func applyOrFallbackOrdering(
        decision: AIWalkOrderingDecision?,
        actionable: [ActionableItem],
        upcoming: [UpcomingItem]
    ) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        guard let decision else {
            return (actionable, upcoming)
        }
        let canApply = !AINudgeRollout.isShadowMode && decision.confidence >= 0.65
        if !canApply {
            Analytics.trackAIDecision(
                surface: .insightBundle,
                applied: false,
                fallbackReason: "shadow_or_low_confidence",
                confidence: decision.confidence,
                provider: nil,
                model: nil,
                latencyMs: nil,
                shadowMode: AINudgeRollout.isShadowMode
            )
            return (actionable, upcoming)
        }

        let orderMap = Dictionary(uniqueKeysWithValues: decision.orderedIds.enumerated().map { ($1, $0) })
        let reorderedActionable = reorderActionableWithGuardrails(actionable, orderMap: orderMap)
        let reorderedUpcoming = upcoming.sorted { lhs, rhs in
            let lhsRank = orderMap[stableUpcomingID(lhs)] ?? Int.max
            let rhsRank = orderMap[stableUpcomingID(rhs)] ?? Int.max
            if lhsRank == rhsRank {
                return lhs.targetTime < rhs.targetTime
            }
            return lhsRank < rhsRank
        }

        Analytics.trackAIDecision(
            surface: .insightBundle,
            applied: true,
            fallbackReason: nil,
            confidence: decision.confidence,
            provider: nil,
            model: nil,
            latencyMs: nil,
            shadowMode: AINudgeRollout.isShadowMode
        )
        return (reorderedActionable, reorderedUpcoming)
    }

    func reorderActionableWithGuardrails(
        _ actionable: [ActionableItem],
        orderMap: [String: Int]
    ) -> [ActionableItem] {
        let buckets: [[ActionableItem]] = [
            actionable.filter {
                if case .overdue = $0.state { return true }
                return false
            },
            actionable.filter {
                if case .due = $0.state { return true }
                return false
            },
            actionable.filter {
                if case .approaching = $0.state { return true }
                return false
            }
        ]

        return buckets.flatMap { bucket in
            bucket.sorted { lhs, rhs in
                let lhsRank = orderMap[stableUpcomingID(lhs.item)] ?? Int.max
                let rhsRank = orderMap[stableUpcomingID(rhs.item)] ?? Int.max
                if lhsRank == rhsRank {
                    return lhs.item.targetTime < rhs.item.targetTime
                }
                return lhsRank < rhsRank
            }
        }
    }

    func stableUpcomingID(_ item: UpcomingItem) -> String {
        "\(item.itemType.eventType.rawValue)|\(item.targetTime.timeIntervalSince1970)|\(item.label)"
    }

    func applyNotificationPolicy(
        policy: AINotificationPolicyDecision?,
        kind: AINotificationKind,
        baselineMinutesUntilFire: Int,
        isUrgent: Bool,
        allowSkip: Bool
    ) -> (minutesUntilFire: Int, skip: Bool) {
        guard let policy else {
            return (baselineMinutesUntilFire, false)
        }
        let minConfidence = 0.65
        let canApply = !AINudgeRollout.isShadowMode && policy.confidence >= minConfidence
        guard canApply else {
            return (baselineMinutesUntilFire, false)
        }

        let minutesDelta: Int
        let shouldSuppress: Bool
        switch kind {
        case .pottyReminder:
            minutesDelta = policy.pottyMinutesDelta
            shouldSuppress = policy.suppressPotty
        case .walkReminder:
            minutesDelta = policy.walkMinutesDelta
            shouldSuppress = policy.suppressWalk
        }

        let deltaClamp = isUrgent ? 10 : 30
        let safeDelta = max(-deltaClamp, min(deltaClamp, minutesDelta))
        let adjustedMinutes = max(1, min(24 * 60, baselineMinutesUntilFire + safeDelta))
        let skip = allowSkip && !isUrgent && shouldSuppress
        return (adjustedMinutes, skip)
    }

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
        if let cached = insightCache[cacheKey], isFresh(cached.updatedAt, maxAgeMinutes: 360) {
            return
        }

        let dedupeKey = "insight-\(profile.id.uuidString)-\(Date().windowStamp(hours: 6))"
        guard inFlightRefreshTasks[dedupeKey] == nil else { return }
        guard consumeBudgetIfAvailable(profileID: profile.id, kind: .insight) else {
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
                self.inFlightRefreshTasks[dedupeKey] = nil
            }
        }
        inFlightRefreshTasks[dedupeKey] = task
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
            locale: Locale.current.identifier,
            policyVersion: "v1",
            promptVersion: "nudge_insight_bundle_v2",
            providerPolicy: defaultProviderPolicy,
            shadowMode: AINudgeRollout.isShadowMode,
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

        let start = Date()
        do {
            let response = try await client.decide(request)
            if let decision = response.insightBundleDecision {
                insightCache[cacheKey] = CacheEntry(value: decision, updatedAt: Date())
                pendingRecommendations[profile.id] = decision.loggingRecommendations
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
            }
        } catch {
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
        if let cached = notificationPolicyCache[cacheKey], isFresh(cached.updatedAt, maxAgeMinutes: 240) {
            return
        }

        let dedupeKey = "notif-\(profile.id.uuidString)-\(Date().windowStamp(hours: 4))"
        guard inFlightRefreshTasks[dedupeKey] == nil else { return }
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
                self.inFlightRefreshTasks[dedupeKey] = nil
            }
        }
        inFlightRefreshTasks[dedupeKey] = task
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
            locale: Locale.current.identifier,
            policyVersion: "v1",
            promptVersion: "nudge_notification_policy_v2",
            providerPolicy: defaultProviderPolicy,
            shadowMode: AINudgeRollout.isShadowMode,
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
                notificationPolicyCache[cacheKey] = CacheEntry(value: policy, updatedAt: Date())
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

    func inferStaleCategories(from events: [PuppyEvent]) -> [AILoggingCategory] {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 3600)
        let recent = events.filter { $0.time >= oneDayAgo }
        var stale: [AILoggingCategory] = []

        if recent.pee().isEmpty { stale.append(.potty) }
        if recent.walks().isEmpty { stale.append(.walk) }
        if recent.meals().isEmpty { stale.append(.meal) }
        if recent.filter({ $0.type == .training }).isEmpty { stale.append(.training) }
        if recent.filter({ $0.type == .sociaal }).isEmpty { stale.append(.socialization) }
        return stale
    }

    func consumeBudgetIfAvailable(profileID: UUID, kind: BundleKind) -> Bool {
        let day = Date().dayStamp()
        let insightCount = callCount(profileID: profileID, dayStamp: day, kind: .insight)
        let notificationCount = callCount(profileID: profileID, dayStamp: day, kind: .notificationPolicy)
        let total = insightCount + notificationCount

        if total >= AINudgeRollout.maxTotalCallsPerDay {
            return false
        }

        switch kind {
        case .insight:
            guard insightCount < AINudgeRollout.maxInsightCallsPerDay else { return false }
        case .notificationPolicy:
            guard notificationCount < AINudgeRollout.maxNotificationCallsPerDay else { return false }
        }

        let key = callCountKey(profileID: profileID, dayStamp: day, kind: kind)
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
        return true
    }

    func markRecommendationAction(profileID: UUID, category: AILoggingCategory, action: String) {
        let day = Date().dayStamp()
        let key = recommendationActionKey(profileID: profileID, dayStamp: day, category: category)
        UserDefaults.standard.set(action, forKey: key)
    }

    func recommendationActionKey(profileID: UUID, dayStamp: String, category: AILoggingCategory) -> String {
        "\(Self.recommendationActionKeyPrefix).\(profileID.uuidString).\(dayStamp).\(category.rawValue)"
    }

    func removePendingRecommendation(profileID: UUID, category: AILoggingCategory) {
        guard var current = pendingRecommendations[profileID] else { return }
        current.removeAll { $0.category == category }
        pendingRecommendations[profileID] = current
    }

    func callCount(profileID: UUID, dayStamp: String, kind: BundleKind) -> Int {
        UserDefaults.standard.integer(
            forKey: callCountKey(profileID: profileID, dayStamp: dayStamp, kind: kind)
        )
    }

    func callCountKey(profileID: UUID, dayStamp: String, kind: BundleKind) -> String {
        "\(Self.callCountKeyPrefix).\(profileID.uuidString).\(dayStamp).\(kind.rawValue)"
    }

    func insightCacheKey(profileID: UUID) -> String {
        "\(profileID.uuidString)-insight-\(Date().windowStamp(hours: 6))"
    }

    func notificationPolicyCacheKey(profileID: UUID) -> String {
        "\(profileID.uuidString)-policy-\(Date().windowStamp(hours: 4))"
    }

    func pottyPredictionFromEvents(_ recentEvents: [PuppyEvent]) -> PottyPrediction {
        let config = PredictionConfig.defaultConfig()
        let gaps = GapCalculations.recentGaps(events: recentEvents, days: 7)
        let gapStats = GapCalculations.calculateGapStats(gaps: gaps)
        return PredictionCalculations.calculatePrediction(
            events: recentEvents,
            config: config,
            gapStats: gapStats
        )
    }

    func stateKey(_ state: ActionableItemState) -> String {
        switch state {
        case .overdue: return "overdue"
        case .due: return "due"
        case .approaching: return "approaching"
        }
    }
}

private extension Date {
    func millisecondsSince(_ start: Date) -> Int {
        Int(timeIntervalSince(start) * 1000)
    }

    func dayStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    func hourStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH"
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
