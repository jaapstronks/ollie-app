//
//  LiveActivitySharedState.swift
//  OtisShared
//
//  Shared state for Live Activity communication between widget extension and main app
//  Uses App Groups UserDefaults since NotificationCenter doesn't work across processes
//

import Foundation

/// Keys for App Groups UserDefaults communication
public enum LiveActivityUserDefaultsKey {
    /// Key for pending wake-up data
    public static let pendingWakeUp = "pendingWakeUp"
    /// Key for pending walk end data
    public static let pendingWalkEnd = "pendingWalkEnd"
}

/// Represents a pending wake-up action from the Live Activity "Wake Up" button
public struct PendingWakeUp: Codable {
    /// The activity ID that should be ended
    public let activityId: String
    /// When the wake-up was triggered
    public let timestamp: Date

    public init(activityId: String, timestamp: Date = Date()) {
        self.activityId = activityId
        self.timestamp = timestamp
    }
}

/// Represents a pending walk end action from the Live Activity "End Walk" button
public struct PendingWalkEnd: Codable {
    /// The activity ID that should be ended
    public let activityId: String
    /// When the walk end was triggered
    public let timestamp: Date

    public init(activityId: String, timestamp: Date = Date()) {
        self.activityId = activityId
        self.timestamp = timestamp
    }
}

/// Shared state manager for Live Activity communication
/// Writes to App Groups UserDefaults for cross-process communication
public final class LiveActivitySharedState: @unchecked Sendable {
    public static let shared = LiveActivitySharedState()

    /// App Group identifier (must match entitlements)
    private let appGroupId = "group.jaapstronks.Otis"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private init() {}

    // MARK: - Wake Up

    /// Write a pending wake-up action (called from widget intent)
    public func writePendingWakeUp(activityId: String) {
        let pending = PendingWakeUp(activityId: activityId)
        guard let data = try? JSONEncoder().encode(pending) else { return }
        userDefaults?.set(data, forKey: LiveActivityUserDefaultsKey.pendingWakeUp)
    }

    /// Read and clear the pending wake-up action (called from main app)
    /// Returns nil if no pending action exists
    public func consumePendingWakeUp() -> PendingWakeUp? {
        guard let data = userDefaults?.data(forKey: LiveActivityUserDefaultsKey.pendingWakeUp),
              let pending = try? JSONDecoder().decode(PendingWakeUp.self, from: data) else {
            return nil
        }

        // Clear the pending action
        userDefaults?.removeObject(forKey: LiveActivityUserDefaultsKey.pendingWakeUp)

        // Only process if recent (within 5 minutes)
        if Date().timeIntervalSince(pending.timestamp) < 300 {
            return pending
        }

        return nil
    }

    /// Check if there's a pending wake-up without consuming it
    public func hasPendingWakeUp() -> Bool {
        userDefaults?.data(forKey: LiveActivityUserDefaultsKey.pendingWakeUp) != nil
    }

    // MARK: - Walk End

    /// Write a pending walk end action (called from widget intent)
    public func writePendingWalkEnd(activityId: String) {
        let pending = PendingWalkEnd(activityId: activityId)
        guard let data = try? JSONEncoder().encode(pending) else { return }
        userDefaults?.set(data, forKey: LiveActivityUserDefaultsKey.pendingWalkEnd)
    }

    /// Read and clear the pending walk end action (called from main app)
    /// Returns nil if no pending action exists
    public func consumePendingWalkEnd() -> PendingWalkEnd? {
        guard let data = userDefaults?.data(forKey: LiveActivityUserDefaultsKey.pendingWalkEnd),
              let pending = try? JSONDecoder().decode(PendingWalkEnd.self, from: data) else {
            return nil
        }

        // Clear the pending action
        userDefaults?.removeObject(forKey: LiveActivityUserDefaultsKey.pendingWalkEnd)

        // Only process if recent (within 5 minutes)
        if Date().timeIntervalSince(pending.timestamp) < 300 {
            return pending
        }

        return nil
    }
}
