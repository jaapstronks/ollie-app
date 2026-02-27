//
//  Constants.swift
//  OllieShared
//
//  App-wide constants (non-profile-specific)

import Foundation
import CoreGraphics
import OSLog

/// App-wide constants (non-profile-specific)
public enum Constants {
    // MARK: - App Identifiers

    /// Logger subsystem identifier
    public static let loggerSubsystem = "nl.jaapstronks.Ollie"

    /// Watch logger subsystem identifier
    public static let watchLoggerSubsystem = "nl.jaapstronks.Ollie.watchkitapp"

    /// App group identifier for shared data
    public static let appGroupIdentifier = "group.jaapstronks.Ollie"

    // MARK: - Storage

    /// Data directory name within app documents
    public static let dataDirectoryName = "data"

    /// Profile file name
    public static let profileFileName = "profile.json"

    /// Quick-log event types shown in the bottom bar
    /// Note: plassen/poepen are now combined in a "Toilet" button with modal selection
    /// slapen/ontwaken toggle based on current sleep state
    /// eten/uitlaten are shown conditionally based on schedule
    public static let quickLogTypes: [EventType] = [
        .eten,
        .slapen,
        .ontwaken,
        .uitlaten
    ]

    /// GitHub repo for data import
    public static let gitHubOwner = "jaapstronks"
    public static let gitHubRepo = "Ollie"
    public static let gitHubDataPath = "data"

    /// Media storage
    public static let mediaDirectoryName = "media"
    public static let thumbnailDirectoryName = "thumbnails"
    public static let thumbnailSize: CGFloat = 200
    public static let maxPhotoSize: CGFloat = 1920

    // MARK: - Time Windows

    /// Walk windows: morning (7-9), midday (12-14), evening (17-20)
    public static let walkWindows: [(start: Int, end: Int)] = [(7, 9), (12, 14), (17, 20)]

    /// Night time start hour (23:00)
    public static let nightStartHour = 23

    /// Night time end hour (06:00)
    public static let nightEndHour = 6

    // MARK: - Timing Thresholds

    /// Minutes before meal time to show meal icon
    public static let mealWindowBeforeMinutes = 30

    /// Minutes after meal time to allow logging
    public static let mealWindowAfterMinutes = 60

    /// Seconds since last walk to consider "recent" (2 hours)
    public static let recentWalkThresholdSeconds: TimeInterval = 7200

    /// Seconds for undo banner auto-dismiss (5 seconds)
    public static let undoBannerTimeoutSeconds: TimeInterval = 5

    /// Seconds for sheet transition delay (0.3 seconds)
    public static let sheetTransitionDelay: TimeInterval = 0.3

    // MARK: - UI Dimensions

    /// Estimated height for event rows in timeline list
    public static let eventRowEstimatedHeight: CGFloat = 80

    // MARK: - Helper Functions

    /// Check if given hour is during night time (23:00 - 06:00)
    public static func isNightTime(hour: Int) -> Bool {
        hour >= nightStartHour || hour < nightEndHour
    }

    /// Check if current time is during night hours
    public static func isNightTimeNow() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return isNightTime(hour: hour)
    }
}

// MARK: - Logger Extension

public extension Logger {
    /// Create a logger with the Ollie app subsystem
    /// - Parameter category: The logging category (e.g., "EventStore", "ProfileStore")
    /// - Returns: A configured Logger instance
    static func ollie(category: String) -> Logger {
        Logger(subsystem: Constants.loggerSubsystem, category: category)
    }

    /// Create a logger with the Ollie Watch subsystem
    /// - Parameter category: The logging category
    /// - Returns: A configured Logger instance for the watch app
    static func ollieWatch(category: String) -> Logger {
        Logger(subsystem: Constants.watchLoggerSubsystem, category: category)
    }
}
