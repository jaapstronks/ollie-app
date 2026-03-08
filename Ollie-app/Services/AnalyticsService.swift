//
//  AnalyticsService.swift
//  Otis-app
//
//  Analytics event tracking for user behavior insights

import Foundation
import Sentry

/// Centralized analytics tracking
enum Analytics {
    nonisolated(unsafe) private static let defaults = UserDefaults.standard
    nonisolated(unsafe) private static let isoFormatter = ISO8601DateFormatter()

    // MARK: - Event Names

    enum Event: String {
        // Plan & Insights
        case thisWeekCardTapped = "this_week_card_tapped"
        case thisWeekCardViewed = "this_week_card_viewed"
        case insightsPlanSectionViewed = "insights_plan_section_viewed"

        // Milestones
        case milestoneCompleted = "milestone_completed"
        case milestoneCalendarAdded = "milestone_calendar_added"
        case milestoneCalendarRemoved = "milestone_calendar_removed"
        case customMilestoneCreated = "custom_milestone_created"
        case milestoneDetailViewed = "milestone_detail_viewed"

        // Socialization
        case socializationWeekTapped = "socialization_week_tapped"
        case socializationExposureLogged = "socialization_exposure_logged"
        case socializationWeeklyGoalMet = "socialization_weekly_goal_met"
        case socializationWindowClosing = "socialization_window_closing"

        // Health Timeline
        case healthTimelineViewed = "health_timeline_viewed"
        case healthTimelineFiltered = "health_timeline_filtered"

        // General
        case featureGated = "feature_gated"
        case premiumUpsellShown = "premium_upsell_shown"
        case premiumUpsellTapped = "premium_upsell_tapped"

        // Memories
        case memoriesCardViewed = "memories_card_viewed"

        // Partner Activity (Handoff)
        case partnerActivityCardViewed = "partner_activity_card_viewed"
        case partnerActivityCardDismissed = "partner_activity_card_dismissed"

        // Social / Likes
        case eventLiked = "event_liked"
        case eventUnliked = "event_unliked"

        // Contribution Stats
        case contributionStatsViewed = "contribution_stats_viewed"

        // Navigation
        case tabSelected = "tab_selected"
        case settingsOpened = "settings_opened"

        // Beta Feedback
        case feedbackSent = "feedback_sent"

        // Activation Funnel
        case profileCreated = "profile_created"
        case firstEventLogged = "first_event_logged"
        case day2Return = "day_2_return"
        case trialStarted = "trial_started"
        case trialConverted = "trial_converted"

        // Trial Touchpoints & Conversion
        case trialTouchpointShown = "trial_touchpoint_shown"
        case trialTouchpointDismissed = "trial_touchpoint_dismissed"
        case trialTouchpointSubscribeTapped = "trial_touchpoint_subscribe_tapped"
        case trialExpiredShown = "trial_expired_shown"
        case trialExpiredSubscribeTapped = "trial_expired_subscribe_tapped"
        case trialExpiredDismissed = "trial_expired_dismissed"

        // AI Nudges
        case aiNudgeDecision = "ai_nudge_decision"

        // Lifecycle
        case phaseTransitionAcknowledged = "phase_transition_acknowledged"

        // Sharing
        case shareAttempted = "share_attempted"
        case shareCompleted = "share_completed"
        case shareSavedToPhotos = "share_saved_to_photos"
        case shareSheetOpened = "share_sheet_opened"
        case shareSheetDismissed = "share_sheet_dismissed"
        case shareError = "share_error"
        case shareFormatSelected = "share_format_selected"
    }

    // MARK: - Tracking

    /// Track an analytics event
    static func track(_ event: Event, properties: [String: Any]? = nil) {
        #if DEBUG
        // Log to console in debug mode
        if let props = properties {
            print("[Analytics] \(event.rawValue): \(props)")
        } else {
            print("[Analytics] \(event.rawValue)")
        }
        #endif

        // Send to Sentry as breadcrumb (for debugging context)
        let crumb = Breadcrumb(level: .info, category: "analytics")
        crumb.message = event.rawValue
        crumb.data = properties
        SentrySDK.addBreadcrumb(crumb)

        // TODO: Add dedicated analytics service integration (e.g., Mixpanel, Amplitude, PostHog)
        // For now, we're just logging and adding breadcrumbs for debugging
    }

    /// Track a milestone completion event with category info
    static func trackMilestoneCompleted(category: String, isCustom: Bool, hasNotes: Bool, hasPhoto: Bool) {
        track(.milestoneCompleted, properties: [
            "category": category,
            "is_custom": isCustom,
            "has_notes": hasNotes,
            "has_photo": hasPhoto
        ])
    }

    /// Track calendar integration events
    static func trackCalendarEvent(added: Bool, milestoneCategory: String) {
        let event: Event = added ? .milestoneCalendarAdded : .milestoneCalendarRemoved
        track(event, properties: [
            "milestone_category": milestoneCategory
        ])
    }

    /// Track socialization exposure logged
    static func trackExposureLogged(category: String, reaction: String, weekNumber: Int) {
        track(.socializationExposureLogged, properties: [
            "category": category,
            "reaction": reaction,
            "week_number": weekNumber
        ])
    }

    /// Track premium feature gating
    static func trackFeatureGated(feature: String, action: String) {
        track(.featureGated, properties: [
            "feature": feature,
            "action": action
        ])
    }

    static func trackAIDecision(
        surface: AINudgeSurface,
        applied: Bool,
        fallbackReason: String?,
        confidence: Double?,
        provider: String?,
        model: String?,
        latencyMs: Int?,
        shadowMode: Bool
    ) {
        var props: [String: Any] = [
            "surface": surface.rawValue,
            "applied": applied,
            "shadow_mode": shadowMode
        ]
        if let fallbackReason {
            props["fallback_reason"] = fallbackReason
        }
        if let confidence {
            props["confidence"] = confidence
        }
        if let provider {
            props["provider"] = provider
        }
        if let model {
            props["model"] = model
        }
        if let latencyMs {
            props["latency_ms"] = latencyMs
        }
        track(.aiNudgeDecision, properties: props)
    }

    /// Track week detail view
    static func trackWeekDetailViewed(weekNumber: Int, exposureCount: Int, isComplete: Bool) {
        track(.socializationWeekTapped, properties: [
            "week_number": weekNumber,
            "exposure_count": exposureCount,
            "is_complete": isComplete
        ])
    }

    // MARK: - Activation Funnel Tracking

    @MainActor
    static func trackProfileCreated(
        profileId: UUID,
        hasBreed: Bool,
        hasPhoto: Bool,
        isExpecting: Bool,
        usedCustomBreed: Bool,
        onboardingVariant: String = "overwhelm_v1"
    ) {
        let now = Date()
        let nowIso = isoFormatter.string(from: now)
        let id = profileId.uuidString

        let properties: [String: Any] = [
            "profile_id": id,
            "has_breed": hasBreed,
            "has_photo": hasPhoto,
            "is_expecting": isExpecting,
            "used_custom_breed": usedCustomBreed,
            "onboarding_variant": onboardingVariant,
            "created_at": nowIso
        ]

        defaults.set(nowIso, forKey: onboardingCompletedAtKey(profileId: id))
        defaults.removeObject(forKey: day2ReturnTrackedKey(profileId: id))
        defaults.removeObject(forKey: firstEventTrackedKey(profileId: id))

        track(.profileCreated, properties: properties)
        OtisAnalytics.shared.track(Event.profileCreated.rawValue, properties: properties)
    }

    @MainActor
    static func trackFirstEventLogged(
        profileId: UUID?,
        eventType: String,
        hasLocation: Bool,
        hasNote: Bool,
        hasPhoto: Bool
    ) {
        let profileKey = profileId?.uuidString ?? "unknown"
        let firstEventKey = firstEventTrackedKey(profileId: profileKey)
        guard !defaults.bool(forKey: firstEventKey) else { return }
        defaults.set(true, forKey: firstEventKey)

        var properties: [String: Any] = [
            "profile_id": profileKey,
            "event_type": eventType,
            "has_location": hasLocation,
            "has_note": hasNote,
            "has_photo": hasPhoto
        ]

        if let completedAtIso = defaults.string(forKey: onboardingCompletedAtKey(profileId: profileKey)),
           let completedAt = isoFormatter.date(from: completedAtIso) {
            let elapsedHours = Date().timeIntervalSince(completedAt) / 3600
            properties["hours_since_profile_created"] = round(elapsedHours * 100) / 100
        }

        track(.firstEventLogged, properties: properties)
        OtisAnalytics.shared.track(Event.firstEventLogged.rawValue, properties: properties)
    }

    @MainActor
    static func trackDay2ReturnIfEligible(profileId: UUID?) {
        guard let profileId else { return }
        let profileKey = profileId.uuidString
        let trackedKey = day2ReturnTrackedKey(profileId: profileKey)
        guard !defaults.bool(forKey: trackedKey) else { return }
        guard let completedAtIso = defaults.string(forKey: onboardingCompletedAtKey(profileId: profileKey)),
              let completedAt = isoFormatter.date(from: completedAtIso) else { return }

        let calendar = Calendar.current
        let startCreated = calendar.startOfDay(for: completedAt)
        let startNow = calendar.startOfDay(for: Date())
        let dayDelta = calendar.dateComponents([.day], from: startCreated, to: startNow).day ?? 0

        if dayDelta == 1 {
            let properties: [String: Any] = [
                "profile_id": profileKey,
                "days_since_profile_created": dayDelta,
                "session_source": "app_active"
            ]
            defaults.set(true, forKey: trackedKey)
            track(.day2Return, properties: properties)
            OtisAnalytics.shared.track(Event.day2Return.rawValue, properties: properties)
        } else if dayDelta > 1 {
            // Prevent repeatedly checking once day-2 window has passed.
            defaults.set(true, forKey: trackedKey)
        }
    }

    @MainActor
    static func trackTrialStarted(transactionId: UInt64, productId: String, trialEndAt: Date?) {
        let key = trialStartedTrackedKey(transactionId: transactionId)
        guard !defaults.bool(forKey: key) else { return }

        var properties: [String: Any] = [
            "transaction_id": String(transactionId),
            "product_id": productId,
            "is_intro_offer": true
        ]
        if let trialEndAt {
            properties["trial_end_at"] = isoFormatter.string(from: trialEndAt)
        }

        defaults.set(true, forKey: key)
        track(.trialStarted, properties: properties)
        OtisAnalytics.shared.track(Event.trialStarted.rawValue, properties: properties)
    }

    @MainActor
    static func trackTrialConverted(activeUntil: Date) {
        let activeUntilIso = isoFormatter.string(from: activeUntil)
        let key = trialConvertedTrackedKey(activeUntil: activeUntilIso)
        guard !defaults.bool(forKey: key) else { return }

        let properties: [String: Any] = [
            "source_status": "trial",
            "target_status": "active",
            "active_until": activeUntilIso
        ]

        defaults.set(true, forKey: key)
        track(.trialConverted, properties: properties)
        OtisAnalytics.shared.track(Event.trialConverted.rawValue, properties: properties)
    }

    private static func onboardingCompletedAtKey(profileId: String) -> String {
        "analytics.onboardingCompletedAt.\(profileId)"
    }

    private static func firstEventTrackedKey(profileId: String) -> String {
        "analytics.firstEventTracked.\(profileId)"
    }

    private static func day2ReturnTrackedKey(profileId: String) -> String {
        "analytics.day2ReturnTracked.\(profileId)"
    }

    private static func trialStartedTrackedKey(transactionId: UInt64) -> String {
        "analytics.trialStartedTracked.\(transactionId)"
    }

    private static func trialConvertedTrackedKey(activeUntil: String) -> String {
        "analytics.trialConvertedTracked.\(activeUntil)"
    }
}
