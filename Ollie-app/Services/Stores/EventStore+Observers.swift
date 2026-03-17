//
//  EventStore+Observers.swift
//  Ollie-app
//
//  Notification observers for CloudKit sync, Watch events, profile changes, and photo sync.
//

import Combine
import CoreData
import Foundation
import OtisShared
import os

extension EventStore {

    // MARK: - Observer Setup

    func setupAllObservers() {
        setupRemoteChangeObserver()
        setupWatchEventObserver()
        setupProfileChangeObserver()
        setupPhotoSyncObserver()
        setupNotificationActionObserver()
    }

    func setupRemoteChangeObserver() {
        // PERF: Register with centralized coordinator instead of individual listener
        // This reduces 12+ simultaneous reactions to 1 coordinated, debounced response
        CloudKitSyncCoordinator.shared.registerCallback(identifier: "EventStore") { [weak self] in
            self?.handleRemoteChange()
        }

        // Listen for share acceptance to reload data
        NotificationCenter.default.publisher(for: .cloudKitShareAccepted)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleShareAccepted()
            }
            .store(in: &cancellables)
    }

    func setupWatchEventObserver() {
        NotificationCenter.default.addObserver(
            forName: .watchEventReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            Task { @MainActor in
                self.logger.info("Received event from Apple Watch, reloading...")
                self.coreDataStore.invalidateCache(for: self.currentDate)
                self.loadEvents(for: self.currentDate)
            }
        }
    }

    func setupProfileChangeObserver() {
        // Listen for active profile changes to reload events
        NotificationCenter.default.publisher(for: .activeProfileChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleProfileChange()
            }
            .store(in: &cancellables)
    }

    func setupPhotoSyncObserver() {
        // Listen for photo upload completion to update event flags
        NotificationCenter.default.publisher(for: .photoUploadCompleted)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID else { return }
                // Extract owner name from upload result - this is critical for partner photo downloads
                let ownerName = notification.userInfo?["ownerName"] as? String
                self?.markPhotoAsSynced(eventId: eventId, ownerName: ownerName)
            }
            .store(in: &cancellables)

        // Listen for photo upload retry requests
        NotificationCenter.default.publisher(for: .photoUploadRetryRequested)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID,
                      let self = self else { return }
                // Fetch the event and retry upload
                if let event = self.coreDataStore.fetchEvent(byId: eventId) {
                    PhotoSyncService.shared.retryUpload(for: event)
                }
            }
            .store(in: &cancellables)

        // Listen for photo owner migration (backfill for existing photos)
        NotificationCenter.default.publisher(for: .photoOwnerMigrationNeeded)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID,
                      let ownerName = notification.userInfo?["ownerName"] as? String,
                      let self = self else { return }
                self.setPhotoOwner(eventId: eventId, ownerName: ownerName)
            }
            .store(in: &cancellables)

        // Listen for photo not found in cloud (EventMedia record doesn't exist)
        // This resets cloudPhotoSynced so the UI shows the correct state
        NotificationCenter.default.publisher(for: .photoNotFoundInCloud)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID,
                      let self = self else { return }
                self.markPhotoAsNotSynced(eventId: eventId)
            }
            .store(in: &cancellables)
    }

    func setupNotificationActionObserver() {
        // Handle like action from moment notification
        NotificationCenter.default.publisher(for: .likeMomentFromNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID,
                      let self = self else { return }
                self.handleLikeFromNotification(eventId: eventId)
            }
            .store(in: &cancellables)
    }

    // MARK: - Observer Handlers

    func handleProfileChange() {
        logger.info("Active profile changed - updating event store")
        updateActiveProfile()
        coreDataStore.invalidateAllCaches()

        if useFetchedResultsController {
            timelineFetchController.configure(
                for: currentDate,
                profile: profileStoreRef?.getActiveCDProfile()
            )
            do {
                try timelineFetchController.performFetch()
                events = timelineFetchController.fetchedEvents
                notifyEventsDidChange()
            } catch {
                logger.error("FRC fetch failed on profile change: \(error)")
                loadEvents(for: currentDate)
            }
        } else {
            loadEvents(for: currentDate)
        }
    }

    /// Timestamp of last remote sync (for incremental aggregate updates)
    private static var lastRemoteSyncTime: Date = Date.distantPast

    func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change")

        // Get current events before refresh for comparison
        let previousEventIds = Set(events.map { $0.id })

        // Invalidate ALL caches (stats, predictions still need this)
        // Sleep state calculations need recent events from multiple days
        coreDataStore.invalidateAllCaches()

        if useFetchedResultsController {
            // With FRC, the delegate will automatically be notified of changes
            // to the current day's events. We just need to:
            // 1. Invalidate caches (done above)
            // 2. Check for new moments from other users
            //
            // The FRC's controllerDidChangeContent delegate method will fire
            // if there are actual changes to the fetched results.

            // NOTE: Do NOT recompute aggregates here - it triggers a Core Data save
            // which sends another CloudKit notification, creating a loop.

            // Check for new moments from other users and send notifications
            Task {
                await checkForNewMomentsAndNotify(previousEventIds: previousEventIds)
            }
        } else {
            // Fallback: existing full-reload path
            let previousEventCount = events.count

            // Check if there are actually new/changed events before doing expensive work
            let freshEvents = coreDataStore.readEvents(for: currentDate)
            let freshEventIds = Set(freshEvents.map { $0.id })

            // Skip full refresh if nothing changed
            if freshEventIds == previousEventIds && freshEvents.count == previousEventCount {
                logger.debug("No actual changes detected, skipping full refresh")
                return
            }

            // Actual changes detected - do the full refresh
            logger.info("Remote changes detected: \(freshEventIds.subtracting(previousEventIds).count) new, \(previousEventIds.subtracting(freshEventIds).count) removed")
            loadEvents(for: currentDate)

            // NOTE: Do NOT recompute aggregates here - it triggers a Core Data save
            // which sends another CloudKit notification, creating a loop.
            // Aggregates will be recomputed lazily when accessed.

            // Check for new moments from other users and send notifications
            Task {
                await checkForNewMomentsAndNotify(previousEventIds: previousEventIds)
            }
        }
    }

    /// Handle incremental aggregate updates for CloudKit synced events
    private func handleIncrementalAggregateUpdate() async {
        guard let profileId = profileStoreRef?.profile?.id else { return }

        let context = PersistenceController.shared.viewContext

        // Find events modified since last sync
        let modifiedCDEvents = CDPuppyEvent.fetchEventsModified(
            after: Self.lastRemoteSyncTime,
            in: context
        )

        // Get affected dates
        let calendar = Calendar.current
        var affectedDates = Set<Date>()
        for cdEvent in modifiedCDEvents {
            if let time = cdEvent.time {
                affectedDates.insert(calendar.startOfDay(for: time))
            }
        }

        Self.lastRemoteSyncTime = Date()

        // Recompute aggregates for affected dates
        guard !affectedDates.isEmpty else { return }

        logger.debug("Recomputing aggregates for \(affectedDates.count) dates after CloudKit sync")

        for date in affectedDates {
            let rangeStart = calendar.date(byAdding: .day, value: -1, to: date)!
            let rangeEnd = calendar.date(byAdding: .day, value: 2, to: date)!
            let events = await getEventsAsync(from: rangeStart, to: rangeEnd)

            await dailyAggregateServiceRef?.recompute(
                date: date,
                profileId: profileId,
                events: events
            )
        }
    }

    /// Check for new moment events from CloudKit sync and send notifications
    func checkForNewMomentsAndNotify(previousEventIds: Set<UUID>) async {
        guard let profile = profileStoreRef?.profile else { return }

        // Get recent events (last 24 hours) to check for new moments
        let recentEvents = getEvents(from: Date.daysAgo(1), to: Date())

        // Find new events that weren't in our previous set
        let newEvents = recentEvents.filter { !previousEventIds.contains($0.id) }

        guard !newEvents.isEmpty else { return }

        // Send notifications for new moments from other users
        await MomentsNotificationHandler.shared.handleRemoteChanges(
            newEvents: newEvents,
            currentUserRecordID: UserIdentityStore.shared.currentUserRecordID,
            puppyName: profile.name,
            settings: profile.notificationSettings
        )
    }

    func handleShareAccepted() {
        logger.info("Share accepted - reloading data from shared store")
        coreDataStore.invalidateAllCaches()
        loadEvents(for: currentDate)
    }

    /// Handle like action triggered from a notification
    func handleLikeFromNotification(eventId: UUID) {
        // Fetch the event from Core Data
        guard let event = coreDataStore.fetchEvent(byId: eventId) else {
            logger.warning("Could not find event \(eventId) for notification like action")
            return
        }

        // Toggle the like
        if let updatedEvent = toggleLike(on: event) {
            logger.info("Liked event \(eventId) from notification: liked=\(updatedEvent.isLikedBy(UserIdentityStore.shared.currentUserRecordID ?? ""))")
        }
    }
}
