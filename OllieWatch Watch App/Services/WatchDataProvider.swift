//
//  WatchDataProvider.swift
//  OllieWatch
//
//  Receives data from iPhone via WatchConnectivity

import Foundation
import Combine
import WatchConnectivity
import WidgetKit
import OllieShared
import os

/// Provides data received from iPhone via WatchConnectivity
/// Also reads local events logged directly on Watch
@MainActor
final class WatchDataProvider: NSObject, ObservableObject {
    static let shared = WatchDataProvider()

    @Published var lastPeeTime: Date?
    @Published var lastPoopTime: Date?
    @Published var currentStreak: Int = 0
    @Published var isSleeping: Bool = false
    @Published var sleepStartTime: Date?
    @Published var puppyName: String = "Puppy"
    @Published var canLogEvents: Bool = true
    @Published var isConnected: Bool = false
    @Published var lastSyncTime: Date?

    private var session: WCSession?
    private let logger = Logger.ollieWatch(category: "WatchDataProvider")
    private let localDataStore = WatchIntentDataStore.shared

    // Widget data sharing
    private static let appGroupIdentifier = "group.jaapstronks.Ollie"
    private static let widgetDataKey = "widgetData"

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - WatchConnectivity Setup

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            logger.warning("WatchConnectivity not supported")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Public Methods

    /// Refresh data - merges iPhone data with locally logged events
    func refresh() {
        // Re-process any cached context
        if let context = session?.receivedApplicationContext, !context.isEmpty {
            processReceivedData(context)
        }

        // Also check local events logged on Watch
        mergeLocalEvents()
    }

    /// Request fresh data from iPhone
    func requestSync() {
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else {
            return
        }

        session.sendMessage(["request": "sync"], replyHandler: nil) { error in
            Task { @MainActor in
                self.logger.error("Failed to request sync: \(error.localizedDescription)")
            }
        }
    }

    /// Send a logged event to the iPhone for storage
    func sendEventToPhone(_ event: PuppyEvent) {
        guard let session = session,
              session.activationState == .activated else {
            logger.debug("Cannot send event to phone - session not activated")
            return
        }

        // Encode the event to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.iso8601String)
        }

        guard let eventData = try? encoder.encode(event),
              let eventJSON = String(data: eventData, encoding: .utf8) else {
            logger.error("Failed to encode event for phone sync")
            return
        }

        let message: [String: Any] = [
            "action": "logEvent",
            "event": eventJSON
        ]

        // Try real-time delivery first if phone is reachable
        if session.isReachable {
            session.sendMessage(message, replyHandler: { _ in
                Task { @MainActor in
                    self.logger.debug("Event sent to phone in real-time: \(event.type.rawValue)")
                }
            }, errorHandler: { error in
                Task { @MainActor in
                    self.logger.warning("Real-time send failed, using queued transfer: \(error.localizedDescription)")
                    // Fall back to guaranteed delivery
                    session.transferUserInfo(message)
                }
            })
        } else {
            // Use transferUserInfo for guaranteed delivery when phone is not reachable
            session.transferUserInfo(message)
            logger.debug("Queued event for transfer to phone: \(event.type.rawValue)")
        }
    }

    /// Format time since last pee for display
    func timeSinceLastPee() -> String {
        guard let lastPee = lastPeeTime else {
            return "--"
        }
        return formatTimeSince(lastPee)
    }

    /// Get urgency color based on time since last pee
    func urgencyLevel() -> UrgencyLevel {
        guard let lastPee = lastPeeTime else {
            return .unknown
        }

        let minutes = Int(Date().timeIntervalSince(lastPee) / 60)

        if minutes < 60 {
            return .good
        } else if minutes < 120 {
            return .attention
        } else if minutes < 180 {
            return .warning
        } else {
            return .urgent
        }
    }

    // MARK: - Private Methods

    private func processReceivedData(_ data: [String: Any]) {
        if let name = data["puppyName"] as? String {
            puppyName = name
        }

        if let lastPeeTimestamp = data["lastPeeTime"] as? TimeInterval {
            lastPeeTime = Date(timeIntervalSince1970: lastPeeTimestamp)
        }

        if let lastPoopTimestamp = data["lastPoopTime"] as? TimeInterval {
            lastPoopTime = Date(timeIntervalSince1970: lastPoopTimestamp)
        }

        if let streak = data["streak"] as? Int {
            currentStreak = streak
        }

        if let sleeping = data["isSleeping"] as? Bool {
            isSleeping = sleeping
            if sleeping, let sleepTimestamp = data["sleepStartTime"] as? TimeInterval {
                sleepStartTime = Date(timeIntervalSince1970: sleepTimestamp)
            } else {
                sleepStartTime = nil
            }
        }

        if let timestamp = data["timestamp"] as? TimeInterval {
            lastSyncTime = Date(timeIntervalSince1970: timestamp)
        }

        logger.debug("Processed sync data from iPhone")
    }

    /// Merge locally logged Watch events with iPhone data
    private func mergeLocalEvents() {
        let today = Date()
        var localEvents = localDataStore.readEvents(for: today)

        // Also check yesterday for events logged near midnight
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
            localEvents += localDataStore.readEvents(for: yesterday)
        }

        guard !localEvents.isEmpty else {
            // Still update widget data even with no local events
            // (to reflect data received from iPhone)
            updateWidgetData()
            return
        }

        // Find the most recent pee event
        if let mostRecentPee = localEvents.first(where: { $0.type == .plassen }) {
            if lastPeeTime == nil || mostRecentPee.time > lastPeeTime! {
                lastPeeTime = mostRecentPee.time
            }
        }

        // Find the most recent poop event
        if let mostRecentPoop = localEvents.first(where: { $0.type == .poepen }) {
            if lastPoopTime == nil || mostRecentPoop.time > lastPoopTime! {
                lastPoopTime = mostRecentPoop.time
            }
        }

        // Update sleep state from local events
        let sleepState = SleepCalculations.currentSleepState(events: localEvents)
        switch sleepState {
        case .sleeping(let since, _):
            // Only use local sleep state if it's more recent than iPhone sync
            if lastSyncTime == nil || since > lastSyncTime! {
                isSleeping = true
                sleepStartTime = since
            }
        case .awake:
            // Local wake-up - check if it's more recent
            if let wakeEvent = localEvents.first(where: { $0.type == .ontwaken }),
               lastSyncTime == nil || wakeEvent.time > lastSyncTime! {
                isSleeping = false
                sleepStartTime = nil
            }
        case .unknown:
            break
        }

        // Recalculate streak from local events
        let localStreak = StreakCalculations.calculateCurrentStreak(events: localEvents)
        if localStreak != currentStreak {
            // If there are local pee events, use the recalculated streak
            if localEvents.contains(where: { $0.type == .plassen }) {
                currentStreak = localStreak
            }
        }

        // Update widget data after merging local events
        updateWidgetData()
    }

    private func formatTimeSince(_ date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)

        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
    }

    // MARK: - Widget Data Sync

    /// Write current data to App Group UserDefaults for watch widgets
    private func updateWidgetData() {
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            logger.warning("Failed to access App Group UserDefaults for widgets")
            return
        }

        // Calculate last wake time if awake
        var lastWakeTime: Date? = nil
        if !isSleeping {
            // Try to find wake time from local events
            let today = Date()
            var localEvents = localDataStore.readEvents(for: today)
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
                localEvents += localDataStore.readEvents(for: yesterday)
            }
            if let wakeEvent = localEvents.first(where: { $0.type == .ontwaken }) {
                lastWakeTime = wakeEvent.time
            }
        }

        // Encode as JSON (matching the format WidgetDataProvider uses)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        // Create a Codable struct matching WatchWidgetData
        struct WidgetDataForEncoding: Codable {
            let lastPlasTime: Date?
            let lastPlasLocation: String?
            let currentStreak: Int
            let bestStreak: Int
            let todayPottyCount: Int
            let todayOutdoorCount: Int
            let isCurrentlySleeping: Bool
            let sleepStartTime: Date?
            let lastWakeTime: Date?
            let lastMealTime: Date?
            let nextScheduledMealTime: Date?
            let mealsLoggedToday: Int
            let mealsExpectedToday: Int
            let lastWalkTime: Date?
            let nextScheduledWalkTime: Date?
            let puppyName: String
            let lastUpdated: Date
        }

        let dataToEncode = WidgetDataForEncoding(
            lastPlasTime: lastPeeTime,
            lastPlasLocation: nil,
            currentStreak: currentStreak,
            bestStreak: 0,
            todayPottyCount: 0,
            todayOutdoorCount: 0,
            isCurrentlySleeping: isSleeping,
            sleepStartTime: sleepStartTime,
            lastWakeTime: lastWakeTime,
            lastMealTime: nil,
            nextScheduledMealTime: nil,
            mealsLoggedToday: 0,
            mealsExpectedToday: 3,
            lastWalkTime: nil,
            nextScheduledWalkTime: nil,
            puppyName: puppyName,
            lastUpdated: Date()
        )

        guard let encodedData = try? encoder.encode(dataToEncode) else {
            logger.error("Failed to encode widget data")
            return
        }

        sharedDefaults.set(encodedData, forKey: Self.widgetDataKey)
        logger.debug("Updated widget data in App Group")

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - WCSessionDelegate

extension WatchDataProvider: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isConnected = (activationState == .activated)

            if activationState == .activated {
                logger.info("WatchConnectivity activated")
                refresh()
            } else if let error = error {
                logger.error("WatchConnectivity failed: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            processReceivedData(applicationContext)
            // Always merge local events after receiving iPhone data
            // to ensure locally logged watch events take precedence
            mergeLocalEvents()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isConnected = session.isReachable
            if session.isReachable {
                requestSync()
            }
        }
    }

    // Handle real-time sync updates from iPhone
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if message["action"] as? String == "syncUpdate" {
                logger.debug("Received real-time sync update from iPhone")
                processReceivedData(message)
                mergeLocalEvents()
            }
        }
    }

    // Handle real-time sync with reply handler
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            if message["action"] as? String == "syncUpdate" {
                logger.debug("Received real-time sync update from iPhone (with reply)")
                processReceivedData(message)
                mergeLocalEvents()
                replyHandler(["status": "received"])
            } else {
                replyHandler(["status": "unknown"])
            }
        }
    }
}

// MARK: - Urgency Level

enum UrgencyLevel {
    case good
    case attention
    case warning
    case urgent
    case unknown
}
