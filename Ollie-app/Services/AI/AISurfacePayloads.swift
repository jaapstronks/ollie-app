//
//  AISurfacePayloads.swift
//  Ollie-app
//
//  Surface-specific request payloads that supplement the context components.
//  These contain surface-specific data that doesn't fit the general context model.
//

import Foundation
import OtisShared

// MARK: - Insight Bundle Payload

/// Additional data for insight bundle requests.
struct InsightBundlePayload: Codable, Sendable {

    /// Baseline status copy to potentially enhance
    let dailyStatus: DailyStatusBaseline

    /// Items that need ordering/prioritization
    let activitySorting: ActivitySortingPayload?

    struct DailyStatusBaseline: Codable, Sendable {
        let baselineTitle: String
        let baselineSubtitle: String?
        let pottyUrgency: String
        let isSleeping: Bool
    }

    struct ActivitySortingPayload: Codable, Sendable {
        let actionableItems: [SortableItem]
        let upcomingItems: [SortableItem]
    }

    struct SortableItem: Codable, Sendable, Identifiable {
        let id: String
        let itemType: String
        let label: String
        let minutesUntil: Int
        let state: String?  // "overdue", "due", "approaching", or nil
    }
}

// MARK: - Notification Policy Payload

/// Additional data for notification policy requests.
struct NotificationPolicyPayload: Codable, Sendable {
    /// Current baseline timing deltas (what the system would do without AI)
    let baselinePottyMinutesDelta: Int
    let baselineWalkMinutesDelta: Int

    /// Categories that appear stale based on logging patterns
    let staleCategories: [String]
}

// MARK: - Training Guidance Payload

/// Additional data for training guidance requests.
struct TrainingGuidancePayload: Codable, Sendable {
    /// Current session context (if in a session)
    let sessionContext: SessionContext?

    /// Specific question from user (if any)
    let userQuestion: String?

    struct SessionContext: Codable, Sendable {
        let skillInProgress: String?
        let sessionDurationMinutes: Int
        let repsCompleted: Int
        let successCount: Int
        let failCount: Int
    }
}

// MARK: - Payload Builders

extension InsightBundlePayload {

    /// Build from legacy UpcomingItem/ActionableItem types.
    static func build(
        baselineTitle: String,
        baselineSubtitle: String?,
        prediction: PottyPrediction?,
        sleepState: SleepState,
        actionableItems: [ActionableItem],
        upcomingItems: [UpcomingItem]
    ) -> InsightBundlePayload {

        let urgencyString: String
        if let prediction = prediction {
            switch prediction.urgency {
            case .justWent: urgencyString = "ok"
            case .normal: urgencyString = "normal"
            case .attention: urgencyString = "attention"
            case .soon: urgencyString = "soon"
            case .overdue: urgencyString = "overdue"
            case .postAccident: urgencyString = "post_accident"
            case .coverageGap: urgencyString = "coverage_gap"
            case .unknown: urgencyString = "unknown"
            }
        } else {
            urgencyString = "unknown"
        }

        let actionable = actionableItems.map { item in
            SortableItem(
                id: stableID(for: item.item),
                itemType: item.item.itemType.eventType.rawValue,
                label: item.item.localizedLabel,
                minutesUntil: item.item.minutesUntil,
                state: stateString(for: item.state)
            )
        }

        let upcoming = upcomingItems.map { item in
            SortableItem(
                id: stableID(for: item),
                itemType: item.itemType.eventType.rawValue,
                label: item.localizedLabel,
                minutesUntil: item.minutesUntil,
                state: nil
            )
        }

        return InsightBundlePayload(
            dailyStatus: .init(
                baselineTitle: baselineTitle,
                baselineSubtitle: baselineSubtitle,
                pottyUrgency: urgencyString,
                isSleeping: sleepState.isSleeping
            ),
            activitySorting: actionable.isEmpty && upcoming.isEmpty ? nil : .init(
                actionableItems: actionable,
                upcomingItems: upcoming
            )
        )
    }

    private static func stableID(for item: UpcomingItem) -> String {
        "\(item.itemType.eventType.rawValue)|\(Int(item.targetTime.timeIntervalSince1970))|\(item.label)"
    }

    private static func stateString(for state: ActionableItemState) -> String {
        switch state {
        case .overdue: return "overdue"
        case .due: return "due"
        case .approaching: return "approaching"
        }
    }
}

extension NotificationPolicyPayload {

    /// Build from recent events to detect stale categories.
    static func build(from events: [PuppyEvent]) -> NotificationPolicyPayload {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 3600)
        let recent = events.filter { $0.time >= oneDayAgo }

        var stale: [String] = []
        if recent.pee().isEmpty { stale.append("potty") }
        if recent.walks().isEmpty { stale.append("walk") }
        if recent.meals().isEmpty { stale.append("meal") }
        if recent.filter({ $0.type == .training }).isEmpty { stale.append("training") }
        if recent.filter({ $0.type == .sociaal }).isEmpty { stale.append("socialization") }

        return NotificationPolicyPayload(
            baselinePottyMinutesDelta: 0,
            baselineWalkMinutesDelta: 0,
            staleCategories: stale
        )
    }
}

// MARK: - Response Application

extension InsightBundleResponse {

    /// Apply daily status if confidence meets threshold.
    func applyDailyStatus(
        baselineTitle: String,
        baselineSubtitle: String?,
        confidenceThreshold: Double = 0.65,
        shadowMode: Bool
    ) -> (title: String, subtitle: String?) {
        guard let status = dailyStatusDecision,
              !shadowMode,
              status.confidence >= confidenceThreshold else {
            return (baselineTitle, baselineSubtitle)
        }
        return (status.headline, status.subtitle ?? baselineSubtitle)
    }

    /// Apply activity ordering if confidence meets threshold.
    func applyOrdering(
        actionable: [ActionableItem],
        upcoming: [UpcomingItem],
        confidenceThreshold: Double = 0.65,
        shadowMode: Bool
    ) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        guard let ordering = walkOrderingDecision,
              !shadowMode,
              ordering.confidence >= confidenceThreshold else {
            return (actionable, upcoming)
        }

        let orderMap = Dictionary(uniqueKeysWithValues: ordering.orderedIds.enumerated().map { ($1, $0) })

        // Reorder within urgency buckets for actionable
        let reorderedActionable = reorderWithinBuckets(actionable, orderMap: orderMap)

        // Reorder upcoming directly
        let reorderedUpcoming = upcoming.sorted { lhs, rhs in
            let lhsID = stableID(for: lhs)
            let rhsID = stableID(for: rhs)
            let lhsRank = orderMap[lhsID] ?? Int.max
            let rhsRank = orderMap[rhsID] ?? Int.max
            if lhsRank == rhsRank {
                return lhs.targetTime < rhs.targetTime
            }
            return lhsRank < rhsRank
        }

        return (reorderedActionable, reorderedUpcoming)
    }

    private func stableID(for item: UpcomingItem) -> String {
        "\(item.itemType.eventType.rawValue)|\(Int(item.targetTime.timeIntervalSince1970))|\(item.label)"
    }

    private func reorderWithinBuckets(
        _ items: [ActionableItem],
        orderMap: [String: Int]
    ) -> [ActionableItem] {
        // Group by urgency bucket
        let overdue = items.filter { if case .overdue = $0.state { return true }; return false }
        let due = items.filter { if case .due = $0.state { return true }; return false }
        let approaching = items.filter { if case .approaching = $0.state { return true }; return false }

        // Sort within each bucket
        func sortBucket(_ bucket: [ActionableItem]) -> [ActionableItem] {
            bucket.sorted { lhs, rhs in
                let lhsID = stableID(for: lhs.item)
                let rhsID = stableID(for: rhs.item)
                let lhsRank = orderMap[lhsID] ?? Int.max
                let rhsRank = orderMap[rhsID] ?? Int.max
                if lhsRank == rhsRank {
                    return lhs.item.targetTime < rhs.item.targetTime
                }
                return lhsRank < rhsRank
            }
        }

        return sortBucket(overdue) + sortBucket(due) + sortBucket(approaching)
    }
}

extension NotificationPolicyResponse {

    /// Apply policy adjustments with guardrails.
    func applyAdjustment(
        kind: AINotificationKind,
        baselineMinutesUntilFire: Int,
        isUrgent: Bool,
        allowSkip: Bool,
        confidenceThreshold: Double = 0.65,
        shadowMode: Bool
    ) -> (minutesUntilFire: Int, skip: Bool) {
        guard !shadowMode, confidence >= confidenceThreshold else {
            return (baselineMinutesUntilFire, false)
        }

        let minutesDelta: Int
        let shouldSuppress: Bool

        switch kind {
        case .pottyReminder:
            minutesDelta = pottyMinutesDelta
            shouldSuppress = suppressPotty
        case .walkReminder:
            minutesDelta = walkMinutesDelta
            shouldSuppress = suppressWalk
        }

        // Apply guardrails
        let maxDelta = isUrgent ? 10 : 30
        let safeDelta = max(-maxDelta, min(maxDelta, minutesDelta))
        let adjusted = max(1, min(24 * 60, baselineMinutesUntilFire + safeDelta))
        let skip = allowSkip && !isUrgent && shouldSuppress

        return (adjusted, skip)
    }
}
