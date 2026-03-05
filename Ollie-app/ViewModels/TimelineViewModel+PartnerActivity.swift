//
//  TimelineViewModel+PartnerActivity.swift
//  Otis-app
//
//  Partner activity summary (handoff card) extension for TimelineViewModel
//

import Combine
import Foundation
import OtisShared

extension TimelineViewModel {

    // MARK: - Partner Activity Summary

    /// Computed partner activity summary for the handoff card
    /// Returns nil if:
    /// - No household members configured
    /// - No current user set
    /// - No partner activity since last seen
    /// - Activity doesn't meet threshold (no highlights and < 3 events)
    var partnerActivitySummary: PartnerActivitySummary? {
        // Must be showing today
        guard isShowingToday else { return nil }

        // Must have household members configured
        guard let household = profileStore.activeProfile?.householdMembers,
              household.members.count > 1 else {
            return nil
        }

        // Must have current user set
        guard let currentUser = household.currentUser() else {
            return nil
        }

        // Get recent events (today and yesterday for cross-midnight tracking)
        let recentEvents = getRecentEvents()

        // Find user's last activity time
        let userLastActivity = PartnerActivityCalculations.findUserLastActivityTime(
            events: recentEvents,
            currentUserId: currentUser.id
        )

        // Get last seen timestamp
        let lastSeen = profileStore.lastSeenPartnerActivityTimestamp

        // Calculate partner activity summary
        return PartnerActivityCalculations.findPartnerActivity(
            events: recentEvents,
            currentUserId: currentUser.id,
            lastSeenTimestamp: lastSeen,
            householdMembers: household,
            userLastActivityTime: userLastActivity
        )
    }

    /// Household members container for display
    var householdMembersContainer: HouseholdMembers {
        profileStore.activeProfile?.householdMembers ?? HouseholdMembers.empty()
    }

    // MARK: - Actions

    /// Dismiss the partner activity summary card
    func dismissPartnerActivitySummary() {
        profileStore.markPartnerActivitySeen()
        // Trigger view update
        objectWillChange.send()
    }
}
