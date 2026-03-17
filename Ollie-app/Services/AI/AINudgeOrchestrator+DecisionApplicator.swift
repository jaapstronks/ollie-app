//
//  AINudgeOrchestrator+DecisionApplicator.swift
//  Otis-app
//
//  Decision application logic for AI nudge orchestration.
//

import Foundation

// MARK: - Decision Application

extension AINudgeOrchestrator {

    func applyOrFallbackDailyStatus(
        _ decision: AIDailyStatusDecision?,
        baselineTitle: String,
        baselineSubtitle: String?
    ) -> (title: String, subtitle: String?) {
        guard let decision else {
            return (baselineTitle, baselineSubtitle)
        }
        // Note: Analytics is tracked when the decision is first fetched/cached,
        // not here (this runs on every view render)
        let canApply = !AINudgeRollout.isShadowMode && decision.confidence >= 0.65
        if canApply {
            // Language validation: if user's locale is non-English but AI returned
            // what looks like English, fall back to the localized baseline
            let currentLocale = Locale.current.language.languageCode?.identifier ?? "en"
            if currentLocale != "en" && looksLikeEnglish(decision.headline) {
                return (baselineTitle, baselineSubtitle)
            }
            return (decision.headline, decision.subtitle ?? baselineSubtitle)
        }
        return (baselineTitle, baselineSubtitle)
    }

    /// Simple heuristic to detect if AI-generated text is likely English
    /// when user expected a different language
    private func looksLikeEnglish(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        // Common English phrases that shouldn't appear in translated text
        let englishPatterns = [
            "needs to pee",
            "needs to go",
            "pee soon",
            "pee now",
            "just peed",
            "minutes ago",
            "hours ago",
            "time for",
            "ready for",
            "overdue"
        ]
        return englishPatterns.contains { lowercased.contains($0) }
    }

    func applyOrFallbackOrdering(
        decision: AIWalkOrderingDecision?,
        actionable: [ActionableItem],
        upcoming: [UpcomingItem]
    ) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        guard let decision else {
            return (actionable, upcoming)
        }
        // Note: Analytics is tracked when the decision is first fetched/cached,
        // not here (this runs on every view render)
        let canApply = !AINudgeRollout.isShadowMode && decision.confidence >= 0.65
        if !canApply {
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
}
