//
//  AINudgeOrchestrator+Budget.swift
//  Otis-app
//
//  Rate limiting and budget management for AI nudge orchestration.
//

import Foundation
import OtisShared
import os

// MARK: - Budget Management

extension AINudgeOrchestrator {

    static let callCountKeyPrefix = "ai.nudges.callCount"
    static let recommendationActionKeyPrefix = "ai.nudges.recommendationAction"
    static let recommendationShownTodayKeyPrefix = "ai.nudges.recommendationShownToday"

    var defaultProviderPolicy: AIVendorPolicy {
        .init(preferredOrder: [.anthropic, .mistral], allowFailover: true)
    }

    func canUseAI(for profile: PuppyProfile) -> Bool {
        // PERFORMANCE: Check debug toggle to disable AI nudges
        guard !PerformanceDebug.disableAINudges else {
            if PerformanceDebug.logExpensiveOperations {
                logger.info("[PERF] AI nudges disabled by toggle")
            }
            return false
        }
        guard AINudgeRollout.isEnabled else {
            return false
        }
        guard subscriptionManager.hasAccess(to: .aiNudges) else {
            return false
        }
        let bucket = abs(profile.id.uuidString.hashValue) % 100
        let rollout = AINudgeRollout.rolloutPercentage
        return bucket < rollout
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

    func callCount(profileID: UUID, dayStamp: String, kind: BundleKind) -> Int {
        UserDefaults.standard.integer(
            forKey: callCountKey(profileID: profileID, dayStamp: dayStamp, kind: kind)
        )
    }

    func callCountKey(profileID: UUID, dayStamp: String, kind: BundleKind) -> String {
        "\(Self.callCountKeyPrefix).\(profileID.uuidString).\(dayStamp).\(kind.rawValue)"
    }

    func markRecommendationAction(profileID: UUID, category: AILoggingCategory, action: String) {
        let day = Date().dayStamp()
        let key = recommendationActionKey(profileID: profileID, dayStamp: day, category: category)
        UserDefaults.standard.set(action, forKey: key)
    }

    func recommendationActionKey(profileID: UUID, dayStamp: String, category: AILoggingCategory) -> String {
        "\(Self.recommendationActionKeyPrefix).\(profileID.uuidString).\(dayStamp).\(category.rawValue)"
    }

    func markRecommendationShownToday(profileID: UUID) {
        let day = Date().dayStamp()
        let key = recommendationShownTodayKey(profileID: profileID, dayStamp: day)
        UserDefaults.standard.set(true, forKey: key)
    }

    func recommendationShownTodayKey(profileID: UUID, dayStamp: String) -> String {
        "\(Self.recommendationShownTodayKeyPrefix).\(profileID.uuidString).\(dayStamp)"
    }

    func wasRecommendationShownToday(profileID: UUID) -> Bool {
        let day = Date().dayStamp()
        let key = recommendationShownTodayKey(profileID: profileID, dayStamp: day)
        return UserDefaults.standard.bool(forKey: key)
    }

    func wasRecommendationActioned(profileID: UUID, category: AILoggingCategory) -> Bool {
        let day = Date().dayStamp()
        let key = recommendationActionKey(profileID: profileID, dayStamp: day, category: category)
        return UserDefaults.standard.string(forKey: key) != nil
    }
}
