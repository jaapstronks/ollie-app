//
//  WatchSyncService.swift
//  Ollie-app
//
//  Syncs data from iPhone to Apple Watch via WatchConnectivity
//
//  IMPORTANT: Apple recommends activating WCSession as early as possible in app lifecycle.
//  This service is initialized in AppDelegate.didFinishLaunchingWithOptions.

import Foundation
import Combine
import WatchConnectivity
import OllieShared
import CoreData
import os

/// Service to sync puppy data to paired Apple Watch
final class WatchSyncService: NSObject {
    static let shared = WatchSyncService()

    private var session: WCSession?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Ollie", category: "WatchSync")
    private let eventStore = CoreDataEventStore()

    // MARK: - Sync Status

    /// Whether the watch is currently connected and reachable
    @Published private(set) var isWatchReachable: Bool = false

    /// Whether the watch app is installed
    @Published private(set) var isWatchAppInstalled: Bool = false

    /// Last successful sync time
    @Published private(set) var lastSyncTime: Date?

    /// Current sync state
    @Published private(set) var syncState: SyncState = .idle

    enum SyncState {
        case idle
        case syncing
        case success
        case failed(Error)
    }

    // MARK: - Retry Configuration

    private var retryCount = 0
    private let maxRetries = 3
    private var retryWorkItem: DispatchWorkItem?

    // MARK: - Persistence Keys

    private static let lastSyncTimeKey = "WatchSync_lastSuccessfulSyncTime"
    private static let pendingSyncKey = "WatchSync_pendingSync"

    override init() {
        super.init()
        loadPersistedState()
        setupSession()
    }

    // MARK: - Setup

    private func setupSession() {
        guard WCSession.isSupported() else {
            logger.info("WatchConnectivity not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
        logger.info("WCSession activation requested")
    }

    // MARK: - State Persistence

    private func loadPersistedState() {
        let timestamp = UserDefaults.standard.double(forKey: Self.lastSyncTimeKey)
        if timestamp > 0 {
            lastSyncTime = Date(timeIntervalSince1970: timestamp)
        }
    }

    private func persistSyncTime(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.lastSyncTimeKey)
        lastSyncTime = date
    }

    private func markPendingSync() {
        UserDefaults.standard.set(true, forKey: Self.pendingSyncKey)
    }

    private func clearPendingSync() {
        UserDefaults.standard.set(false, forKey: Self.pendingSyncKey)
    }

    private var hasPendingSync: Bool {
        UserDefaults.standard.bool(forKey: Self.pendingSyncKey)
    }

    // MARK: - Public Methods

    /// Sync current data to Watch
    /// Call this after logging events, on app launch, and periodically
    func syncToWatch() {
        guard let session = session,
              session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else {
            logger.debug("Cannot sync - session not ready or watch not available")
            return
        }

        // Cancel any pending retry
        retryWorkItem?.cancel()
        retryWorkItem = nil

        syncState = .syncing
        markPendingSync()

        Task {
            let data = await buildSyncData()

            // Always update application context for eventual delivery
            do {
                try session.updateApplicationContext(data)
                logger.debug("Updated application context for Watch")

                // Mark sync as successful
                let now = Date()
                persistSyncTime(now)
                clearPendingSync()
                retryCount = 0
                syncState = .success

                // Reset to idle after a moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if case .success = self.syncState {
                        self.syncState = .idle
                    }
                }
            } catch {
                logger.error("Failed to update context: \(error.localizedDescription)")
                handleSyncError(error)
            }

            // Also send real-time message if watch is reachable for immediate update
            if session.isReachable {
                var messageData = data
                messageData["action"] = "syncUpdate"
                session.sendMessage(messageData, replyHandler: { _ in
                    self.logger.debug("Real-time sync delivered to Watch")
                }, errorHandler: { error in
                    self.logger.warning("Real-time sync failed: \(error.localizedDescription)")
                    // Don't trigger retry for real-time failures - applicationContext is the reliable path
                })
            }
        }
    }

    // MARK: - Retry Logic

    private func handleSyncError(_ error: Error) {
        self.syncState = .failed(error)

        guard self.retryCount < self.maxRetries else {
            self.logger.error("Sync failed after \(self.maxRetries) retries")
            self.retryCount = 0
            return
        }

        self.retryCount += 1

        // Exponential backoff: 2s, 4s, 8s
        let delay = pow(2.0, Double(self.retryCount))
        self.logger.info("Scheduling sync retry \(self.retryCount)/\(self.maxRetries) in \(delay)s")

        let workItem = DispatchWorkItem { [weak self] in
            self?.syncToWatch()
        }
        self.retryWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    /// Force a sync attempt, clearing retry state
    func forceSyncToWatch() {
        retryCount = 0
        retryWorkItem?.cancel()
        retryWorkItem = nil
        syncToWatch()
    }

    /// Retry sync if there's a pending sync that failed
    func retryPendingSyncIfNeeded() {
        if hasPendingSync {
            logger.info("Retrying pending sync")
            syncToWatch()
        }
    }

    // MARK: - Build Sync Data

    private func buildSyncData() async -> [String: Any] {
        let events = loadRecentEvents()
        let profile = loadProfile()

        // Calculate derived values
        let lastPeeTime = events.pee().reverseChronological().first?.time
        let lastPoopTime = events.poop().reverseChronological().first?.time
        let streak = StreakCalculations.calculateCurrentStreak(events: events)
        let sleepState = SleepCalculations.currentSleepState(events: events)

        var data: [String: Any] = [
            "puppyName": profile?.name ?? "Puppy",
            "streak": streak,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let lastPee = lastPeeTime {
            data["lastPeeTime"] = lastPee.timeIntervalSince1970
        }

        if let lastPoop = lastPoopTime {
            data["lastPoopTime"] = lastPoop.timeIntervalSince1970
        }

        switch sleepState {
        case .sleeping(let since, _):
            data["isSleeping"] = true
            data["sleepStartTime"] = since.timeIntervalSince1970
        case .awake, .unknown:
            data["isSleeping"] = false
        }

        return data
    }

    private func loadRecentEvents() -> [PuppyEvent] {
        let today = Date()
        var events: [PuppyEvent] = []

        // Load today + yesterday for accurate calculations
        events.append(contentsOf: eventStore.readEvents(for: today))
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
            events.append(contentsOf: eventStore.readEvents(for: yesterday))
        }

        return events
    }

    private func loadProfile() -> PuppyProfile? {
        // Load profile from Core Data
        let context = PersistenceController.shared.viewContext
        let cdProfile = CDPuppyProfile.fetchProfile(in: context)
        return cdProfile?.toPuppyProfile()
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            logger.info("WatchConnectivity activated, paired: \(session.isPaired), installed: \(session.isWatchAppInstalled), reachable: \(session.isReachable)")

            // Update published state
            isWatchReachable = session.isReachable
            isWatchAppInstalled = session.isWatchAppInstalled

            // Sync immediately and retry any pending sync
            syncToWatch()
            retryPendingSyncIfNeeded()
        } else if let error = error {
            logger.error("WatchConnectivity activation failed: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Required for iOS
        logger.debug("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Required for iOS - reactivate for watch switching
        logger.debug("WCSession deactivated, reactivating...")
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        logger.info("Watch state changed - paired: \(session.isPaired), installed: \(session.isWatchAppInstalled)")

        isWatchAppInstalled = session.isWatchAppInstalled

        if session.isPaired && session.isWatchAppInstalled {
            syncToWatch()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("Watch reachability changed: \(session.isReachable)")

        isWatchReachable = session.isReachable

        if session.isReachable {
            // Watch became reachable - retry any pending sync
            retryPendingSyncIfNeeded()
        }
    }

    // Handle sync requests and events from Watch (real-time delivery)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["request"] as? String == "sync" {
            syncToWatch()
        } else if message["action"] as? String == "logEvent" {
            // Handle real-time event delivery (same logic as didReceiveUserInfo)
            handleReceivedEvent(from: message)
        }
    }

    // Handle real-time messages with reply
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if message["action"] as? String == "logEvent" {
            handleReceivedEvent(from: message)
            replyHandler(["status": "received"])
        } else if message["request"] as? String == "sync" {
            syncToWatch()
            replyHandler(["status": "syncing"])
        } else {
            replyHandler(["status": "unknown"])
        }
    }

    /// Process an event received from Watch (either via message or userInfo)
    private func handleReceivedEvent(from data: [String: Any]) {
        guard let eventJSON = data["event"] as? String,
              let eventData = eventJSON.data(using: .utf8) else {
            logger.error("Invalid event data from Watch")
            return
        }

        // Decode the event
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = Date.fromISO8601(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        guard let event = try? decoder.decode(PuppyEvent.self, from: eventData) else {
            logger.error("Failed to decode event from Watch")
            return
        }

        // Store the event on main actor since Core Data context requires it
        Task { @MainActor in
            do {
                try eventStore.saveEvent(event)
                logger.info("Received and stored event from Watch: \(event.type.rawValue)")
            } catch {
                logger.error("Failed to save event from Watch: \(error.localizedDescription)")
            }

            // Sync updated data back to watch
            syncToWatch()

            // Notify the app that data changed
            NotificationCenter.default.post(name: .watchEventReceived, object: event)
        }
    }

    // Handle events transferred from Watch (guaranteed delivery / queued)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard userInfo["action"] as? String == "logEvent" else { return }
        handleReceivedEvent(from: userInfo)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchEventReceived = Notification.Name("watchEventReceived")
}
