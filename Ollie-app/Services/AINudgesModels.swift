//
//  AINudgesModels.swift
//  Otis-app
//
//  Vendor-agnostic contracts for subtle AI nudges.
//

import Foundation
import OtisShared

enum AINudgeSurface: String, Codable {
    case insightBundle = "insight_bundle"
    case notificationPolicy = "notification_policy"
}

enum AIVendor: String, Codable {
    case anthropic
    case mistral
}

enum AINotificationKind: String, Codable {
    case pottyReminder = "potty_reminder"
    case walkReminder = "walk_reminder"
}

struct AIVendorPolicy: Codable {
    let preferredOrder: [AIVendor]
    let allowFailover: Bool
}

struct AINudgeContextSummary: Codable {
    let ageWeeks: Int
    let daysHome: Int
    let recentEventCount: Int
    let recentWalkCount: Int
    let recentMealCount: Int
    let recentPottyCount: Int
}

enum AILoggingCategory: String, Codable {
    case potty
    case walk
    case meal
    case training
    case socialization
}

struct AIDailyStatusDecision: Codable {
    let headline: String
    let subtitle: String?
    let confidence: Double
}

struct AIWalkOrderingDecision: Codable {
    let orderedIds: [String]
    let confidence: Double
}

struct AINotificationTimingDecision: Codable {
    let minutesDelta: Int
    let skip: Bool
    let confidence: Double
}

struct AINotificationPolicyDecision: Codable {
    let confidence: Double
    let validForMinutes: Int
    let pottyMinutesDelta: Int
    let walkMinutesDelta: Int
    let suppressPotty: Bool
    let suppressWalk: Bool
}

struct AILoggingCategoryRecommendation: Codable, Identifiable {
    var id: String { category.rawValue }
    let category: AILoggingCategory
    let recommendation: String
    let confidence: Double
}

struct AIInsightBundleDecision: Codable {
    let confidence: Double
    let dailyStatusDecision: AIDailyStatusDecision?
    let walkOrderingDecision: AIWalkOrderingDecision?
    let trainingProgressText: String?
    let socializationProgressText: String?
    let loggingRecommendations: [AILoggingCategoryRecommendation]
}

struct AINudgeBrokerRequest: Codable {
    let surface: AINudgeSurface
    let profileId: UUID
    let locale: String
    let policyVersion: String
    let promptVersion: String
    let providerPolicy: AIVendorPolicy
    let shadowMode: Bool
    let context: AINudgeContextSummary
    let payload: Payload

    struct Payload: Codable {
        let insightBundle: InsightBundlePayload?
        let notificationPolicy: NotificationPolicyPayload?
    }

    struct DailyStatusPayload: Codable {
        let baselineTitle: String
        let baselineSubtitle: String?
        let pottyUrgency: String
        let isSleeping: Bool
    }

    struct WalkSortingPayload: Codable {
        let actionable: [WalkSortItem]
        let upcoming: [WalkSortItem]
    }

    struct WalkSortItem: Codable {
        let id: String
        let itemType: String
        let label: String
        let minutesUntil: Int
        let state: String?
    }

    struct InsightBundlePayload: Codable {
        let dailyStatus: DailyStatusPayload
        let walkSorting: WalkSortingPayload
        let trainingProgressSummary: String?
        let socializationProgressSummary: String?
    }

    struct NotificationPolicyPayload: Codable {
        let baselinePottyMinutesDelta: Int
        let baselineWalkMinutesDelta: Int
        let staleCategories: [AILoggingCategory]
    }
}

struct AINudgeBrokerResponse: Codable {
    let providerUsed: String?
    let modelUsed: String?
    let reasoningTags: [String]?
    let insightBundleDecision: AIInsightBundleDecision?
    let notificationPolicyDecision: AINotificationPolicyDecision?
}

enum AINudgeRollout {
    private static let enabledKey = "ai.nudges.enabled"
    private static let rolloutPercentageKey = "ai.nudges.rolloutPercentage"
    private static let shadowModeKey = "ai.nudges.shadowMode"
    private static let brokerBaseURLKey = "ai.nudges.brokerBaseURL"
    private static let brokerApiKeyKey = "ai.nudges.brokerApiKey"
    private static let maxInsightCallsPerDayKey = "ai.nudges.maxInsightCallsPerDay"
    private static let maxNotificationCallsPerDayKey = "ai.nudges.maxNotificationCallsPerDay"
    private static let maxTotalCallsPerDayKey = "ai.nudges.maxTotalCallsPerDay"

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    static var rolloutPercentage: Int {
        let fallback = AppEnvironment.current.isBeta ? 100 : 0
        let raw = UserDefaults.standard.object(forKey: rolloutPercentageKey) as? Int ?? fallback
        return max(0, min(100, raw))
    }

    static var isShadowMode: Bool {
        UserDefaults.standard.object(forKey: shadowModeKey) as? Bool ?? AppEnvironment.current.isBeta
    }

    static var brokerBaseURL: URL? {
        guard let raw = UserDefaults.standard.string(forKey: brokerBaseURLKey),
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return URL(string: raw)
    }

    static var brokerApiKey: String? {
        guard let raw = UserDefaults.standard.string(forKey: brokerApiKeyKey),
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return raw
    }

    static var maxInsightCallsPerDay: Int {
        let fallback = 4
        let raw = UserDefaults.standard.object(forKey: maxInsightCallsPerDayKey) as? Int ?? fallback
        return max(0, raw)
    }

    static var maxNotificationCallsPerDay: Int {
        let fallback = 6
        let raw = UserDefaults.standard.object(forKey: maxNotificationCallsPerDayKey) as? Int ?? fallback
        return max(0, raw)
    }

    static var maxTotalCallsPerDay: Int {
        let fallback = 10
        let raw = UserDefaults.standard.object(forKey: maxTotalCallsPerDayKey) as? Int ?? fallback
        return max(0, raw)
    }
}
