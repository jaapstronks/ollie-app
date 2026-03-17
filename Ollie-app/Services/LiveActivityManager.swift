//
//  LiveActivityManager.swift
//  Otis-app
//
//  Manages Live Activity lifecycle for nap and walk tracking
//  Handles starting, updating, and ending Live Activities
//

import ActivityKit
import Foundation
import os
import OtisShared

/// Manages Live Activities for activity tracking (naps and walks)
@available(iOS 16.1, *)
@MainActor
@Observable
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private let logger = Logger.otis(category: "LiveActivity")

    /// Currently active nap Live Activity
    private var napActivity: Activity<NapActivityAttributes>?

    /// Whether Live Activities are enabled on this device
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private init() {
        // Find any existing nap activity on launch
        napActivity = Activity<NapActivityAttributes>.activities.first
        if napActivity != nil {
            logger.info("Found existing nap Live Activity on launch")
        }
    }

    // MARK: - Nap Activity

    /// Start a nap Live Activity
    /// - Parameters:
    ///   - puppyName: Name of the puppy for display
    ///   - startTime: When the nap started
    ///   - activityId: UUID of the InProgressActivity for coordination
    func startNapActivity(puppyName: String, startTime: Date, activityId: UUID) {
        logger.info("startNapActivity called for \(puppyName)")

        guard areActivitiesEnabled else {
            logger.warning("Live Activities are disabled in system settings, skipping nap activity start")
            return
        }

        logger.info("Live Activities are enabled, proceeding...")

        // End any existing nap activity first
        if napActivity != nil {
            logger.info("Ending existing nap activity first")
            endNapActivity()
        }

        let attributes = NapActivityAttributes(
            puppyName: puppyName,
            startTime: startTime,
            activityId: activityId
        )
        let state = NapActivityAttributes.ContentState(hasEnded: false)

        do {
            napActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            logger.info("Successfully started nap Live Activity for \(puppyName), activity id: \(self.napActivity?.id ?? "nil")")
        } catch {
            logger.error("Failed to start nap Live Activity: \(error.localizedDescription)")
            logger.error("Error details: \(String(describing: error))")
        }
    }

    /// End the current nap Live Activity
    func endNapActivity() {
        guard let activity = napActivity else {
            logger.debug("No nap activity to end")
            return
        }

        // Clear the reference first
        napActivity = nil

        // End the activity asynchronously
        Task { @MainActor in
            let finalState = NapActivityAttributes.ContentState(hasEnded: true)
            let content = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(content, dismissalPolicy: .default)
        }

        logger.info("Ended nap Live Activity")
    }

    /// Check if there's an active nap Live Activity
    var hasActiveNapActivity: Bool {
        napActivity != nil
    }

    /// Get the activity ID of the current nap activity
    var currentNapActivityId: UUID? {
        napActivity?.attributes.activityId
    }

    // MARK: - Orphaned Activity Cleanup

    /// Clean up any orphaned Live Activities that don't match the current app state
    /// Call this on app launch to handle cases where app was force-quit during activity
    /// - Parameter currentInProgressActivityId: The UUID of the currently in-progress activity, if any
    func cleanupOrphanedActivities(currentInProgressActivityId: UUID?) {
        let activities = Activity<NapActivityAttributes>.activities

        // Find orphaned activities to end
        let orphanedActivities = activities.filter { activity in
            currentInProgressActivityId == nil ||
            activity.attributes.activityId != currentInProgressActivityId
        }

        // End orphaned activities in a Task
        for activity in orphanedActivities {
            logger.info("Cleaning up orphaned nap activity: \(activity.attributes.activityId)")
            Task { @MainActor in
                let finalState = NapActivityAttributes.ContentState(hasEnded: true)
                let content = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }

        // Update our reference to match the current state
        if let currentId = currentInProgressActivityId {
            napActivity = activities.first { $0.attributes.activityId == currentId }
        } else {
            napActivity = nil
        }
    }

    // MARK: - Pending Actions (from Widget Intent)

    /// Check for and handle pending wake-up actions from the Live Activity "Wake Up" button
    /// Call this when the app becomes active/foreground
    /// - Parameter onWakeUp: Closure to call with the activity ID if a pending wake-up is found
    func handlePendingWakeUp(onWakeUp: (UUID) -> Void) {
        guard let pending = LiveActivitySharedState.shared.consumePendingWakeUp(),
              let uuid = UUID(uuidString: pending.activityId) else {
            return
        }

        logger.info("Handling pending wake-up for activity: \(pending.activityId)")
        onWakeUp(uuid)

        // End the Live Activity
        endNapActivity()
    }
}

