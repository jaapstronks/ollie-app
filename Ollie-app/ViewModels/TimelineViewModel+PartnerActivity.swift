//
//  TimelineViewModel+PartnerActivity.swift
//  Otis-app
//
//  Partner activity summary (handoff card) extension for TimelineViewModel
//  Updated to use CloudKit-based identity (UserIdentityStore) instead of HouseholdMembers
//

import Combine
import Foundation
import OtisShared

extension TimelineViewModel {

    // MARK: - Partner Activity Summary

    /// Cached partner activity summary for the handoff card
    /// PERFORMANCE: Now returns cached value instead of synchronous Core Data fetch
    /// Cache is updated asynchronously when events change
    var partnerActivitySummary: PartnerActivitySummary? {
        // Must be showing today for the summary to be relevant
        guard isShowingToday else { return nil }
        return partnerActivitySummaryCache
    }

    /// Calculate partner activity summary from provided events (used by async refresh)
    /// This is a pure function that doesn't do any fetching
    func calculatePartnerActivitySummary(from recentEvents: [PuppyEvent]) -> PartnerActivitySummary? {
        // Must have current user CloudKit ID
        guard let currentUserRecordID = UserIdentityStore.shared.currentUserRecordID else {
            return nil
        }

        // Find user's last activity time
        let userLastActivity = PartnerActivityCalculations.findUserLastActivityTimeByRecordID(
            events: recentEvents,
            currentUserRecordID: currentUserRecordID
        )

        // Get last seen timestamp
        let lastSeen = profileStore.lastSeenPartnerActivityTimestamp

        // Get puppy name for natural language summary
        let puppyName = profileStore.profile?.name

        // Calculate partner activity summary using CloudKit record IDs
        return PartnerActivityCalculations.findPartnerActivityByRecordID(
            events: recentEvents,
            currentUserRecordID: currentUserRecordID,
            lastSeenTimestamp: lastSeen,
            userLastActivityTime: userLastActivity,
            puppyName: puppyName,
            partnerNameResolver: { recordID in
                ParticipantResolver.shared.resolve(cloudKitRecordID: recordID).displayName
            }
        )
    }

    // MARK: - Actions

    /// Dismiss the partner activity summary card
    func dismissPartnerActivitySummary() {
        profileStore.markPartnerActivitySeen()
        // Clear the cache immediately so the card disappears
        clearPartnerActivityCache()
    }
}
