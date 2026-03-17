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

    // Historical comparison for smarter recommendations
    // Shows last 3 days vs prior 4 days (week comparison)
    let recentDaysWalkAvg: Double?       // Average walks per day in last 3 days
    let priorDaysWalkAvg: Double?        // Average walks per day in prior 4 days
    let recentDaysMealAvg: Double?       // Average meals per day in last 3 days
    let priorDaysMealAvg: Double?        // Average meals per day in prior 4 days
    let recentDaysPottyAvg: Double?      // Average potty breaks per day in last 3 days
    let priorDaysPottyAvg: Double?       // Average potty breaks per day in prior 4 days
    let recentDaysTrainingAvg: Double?   // Average training sessions per day in last 3 days
    let priorDaysTrainingAvg: Double?    // Average training sessions per day in prior 4 days
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

    /// Modern format fields - if provided, broker uses client instructions instead of hardcoded prompts
    let systemInstruction: String?
    let outputFormat: String?

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

    // Legacy format fields
    let insightBundleDecision: AIInsightBundleDecision?
    let notificationPolicyDecision: AINotificationPolicyDecision?

    // Modern format field (when systemInstruction/outputFormat are provided)
    let response: AIInsightBundleDecision?

    /// Get the insight decision from either modern or legacy response format
    var effectiveInsightDecision: AIInsightBundleDecision? {
        response ?? insightBundleDecision
    }
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
    private static let testModeKey = "ai.nudges.testMode"
    private static let defaultBrokerBaseURL = "https://ai.otis.pet"

    static func registerDefaults() {
        let isBeta = AppEnvironment.current.isBeta
        #if DEBUG
        // Reasonable limits for development - enough to test, not enough to burn budget
        // Use testMode=true in settings for unlimited local testing without API calls
        let insightLimit = 10
        let notificationLimit = 10
        let totalLimit = 15
        #else
        let insightLimit = 4
        let notificationLimit = 6
        let totalLimit = 10
        #endif
        UserDefaults.standard.register(defaults: [
            enabledKey: true,
            rolloutPercentageKey: isBeta ? 100 : 0,
            shadowModeKey: isBeta,
            brokerBaseURLKey: defaultBrokerBaseURL,
            maxInsightCallsPerDayKey: insightLimit,
            maxNotificationCallsPerDayKey: notificationLimit,
            maxTotalCallsPerDayKey: totalLimit
        ])
    }

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
        #if DEBUG
        let fallback = 100
        #else
        let fallback = 4
        #endif
        let raw = UserDefaults.standard.object(forKey: maxInsightCallsPerDayKey) as? Int ?? fallback
        return max(0, raw)
    }

    static var maxNotificationCallsPerDay: Int {
        #if DEBUG
        let fallback = 100
        #else
        let fallback = 6
        #endif
        let raw = UserDefaults.standard.object(forKey: maxNotificationCallsPerDayKey) as? Int ?? fallback
        return max(0, raw)
    }

    static var maxTotalCallsPerDay: Int {
        #if DEBUG
        let fallback = 200
        #else
        let fallback = 10
        #endif
        let raw = UserDefaults.standard.object(forKey: maxTotalCallsPerDayKey) as? Int ?? fallback
        return max(0, raw)
    }

    /// Test mode bypasses caching, budget limits, rollout checks, and forces shadow mode off
    /// for manual testing of AI decisions. Only available in DEBUG builds.
    static var isTestMode: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: testModeKey)
        #else
        return false
        #endif
    }
}

// MARK: - Test Results

/// Result from a manual AI test request
struct AITestResult: Identifiable {
    let id = UUID()
    let surface: AINudgeSurface
    let timestamp: Date
    let latencyMs: Int
    let provider: String?
    let model: String?
    let reasoningTags: [String]
    let rawResponse: AINudgeBrokerResponse
    let error: String?

    var isSuccess: Bool { error == nil }

    var summaryText: String {
        guard isSuccess else { return "Error: \(error ?? "Unknown")" }

        var lines: [String] = []
        lines.append("Provider: \(provider ?? "unknown") / \(model ?? "unknown")")
        lines.append("Latency: \(latencyMs)ms")

        if !reasoningTags.isEmpty {
            lines.append("Tags: \(reasoningTags.joined(separator: ", "))")
        }

        if let insight = rawResponse.insightBundleDecision {
            lines.append("")
            lines.append("--- Insight Bundle ---")
            lines.append("Confidence: \(String(format: "%.0f%%", insight.confidence * 100))")

            if let daily = insight.dailyStatusDecision {
                lines.append("")
                lines.append("Daily Status:")
                lines.append("  \"\(daily.headline)\"")
                if let sub = daily.subtitle {
                    lines.append("  \"\(sub)\"")
                }
                lines.append("  (conf: \(String(format: "%.0f%%", daily.confidence * 100)))")
            }

            if let walk = insight.walkOrderingDecision {
                lines.append("")
                lines.append("Walk Ordering: \(walk.orderedIds.count) items")
                lines.append("  (conf: \(String(format: "%.0f%%", walk.confidence * 100)))")
            }

            if !insight.loggingRecommendations.isEmpty {
                lines.append("")
                lines.append("Recommendations:")
                for rec in insight.loggingRecommendations {
                    lines.append("  [\(rec.category.rawValue)] \(rec.recommendation)")
                }
            }
        }

        if let notif = rawResponse.notificationPolicyDecision {
            lines.append("")
            lines.append("--- Notification Policy ---")
            lines.append("Confidence: \(String(format: "%.0f%%", notif.confidence * 100))")
            lines.append("Valid for: \(notif.validForMinutes) min")
            lines.append("Potty delta: \(notif.pottyMinutesDelta > 0 ? "+" : "")\(notif.pottyMinutesDelta) min")
            lines.append("Walk delta: \(notif.walkMinutesDelta > 0 ? "+" : "")\(notif.walkMinutesDelta) min")
            lines.append("Suppress potty: \(notif.suppressPotty)")
            lines.append("Suppress walk: \(notif.suppressWalk)")
        }

        return lines.joined(separator: "\n")
    }
}
