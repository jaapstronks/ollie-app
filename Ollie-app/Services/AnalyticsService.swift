//
//  AnalyticsService.swift
//  Ollie-app
//
//  Analytics event tracking for user behavior insights

import Foundation
import Sentry

/// Centralized analytics tracking
enum Analytics {

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

    /// Track week detail view
    static func trackWeekDetailViewed(weekNumber: Int, exposureCount: Int, isComplete: Bool) {
        track(.socializationWeekTapped, properties: [
            "week_number": weekNumber,
            "exposure_count": exposureCount,
            "is_complete": isComplete
        ])
    }
}
