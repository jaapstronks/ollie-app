//
//  ActivityBlock.swift
//  OllieShared
//
//  Model for visual timeline blocks representing puppy activities

import Foundation

// MARK: - Activity Block Type

/// Types of activity blocks for the visual timeline
public enum ActivityBlockType: Equatable, Sendable {
    case sleep              // Blue bar - sleeping/napping
    case walk               // Green bar - on a walk
    case potty(outdoor: Bool)  // Tick mark - green outdoor, red indoor
    case meal               // Orange dot - eating/drinking
    case awake              // Background - no explicit block rendered

    /// SF Symbol icon for this block type
    public var icon: String {
        switch self {
        case .sleep: return "moon.zzz.fill"
        case .walk: return "figure.walk"
        case .potty(let outdoor): return outdoor ? "checkmark.circle.fill" : "xmark.circle.fill"
        case .meal: return "fork.knife"
        case .awake: return "sun.max.fill"
        }
    }

    /// Whether this block type has duration (vs point-in-time)
    public var hasDuration: Bool {
        switch self {
        case .sleep, .walk, .awake: return true
        case .potty, .meal: return false
        }
    }
}

// MARK: - Activity Block

/// A block of activity on the visual timeline
public struct ActivityBlock: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let type: ActivityBlockType
    public let startTime: Date
    public let endTime: Date
    public let containedEventIds: [UUID]
    public let isOngoing: Bool

    public init(
        id: UUID = UUID(),
        type: ActivityBlockType,
        startTime: Date,
        endTime: Date,
        containedEventIds: [UUID] = [],
        isOngoing: Bool = false
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.containedEventIds = containedEventIds
        self.isOngoing = isOngoing
    }

    /// Duration of this block in minutes
    public var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// Formatted duration string
    public var durationString: String {
        let minutes = durationMinutes
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

    /// Start time formatted as "HH:mm"
    public var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startTime)
    }

    /// End time formatted as "HH:mm"
    public var endTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endTime)
    }

    /// Time range formatted as "HH:mm - HH:mm"
    public var timeRangeString: String {
        if isOngoing {
            return "\(startTimeString) - now"
        }
        return "\(startTimeString) - \(endTimeString)"
    }
}

// MARK: - Activity Block Summary

/// Summary statistics for a day's activity blocks
public struct ActivityBlockSummary: Equatable, Sendable {
    public let totalSleepMinutes: Int
    public let walkCount: Int
    public let totalWalkMinutes: Int
    public let outdoorPottyCount: Int
    public let indoorPottyCount: Int
    public let mealCount: Int

    public init(
        totalSleepMinutes: Int = 0,
        walkCount: Int = 0,
        totalWalkMinutes: Int = 0,
        outdoorPottyCount: Int = 0,
        indoorPottyCount: Int = 0,
        mealCount: Int = 0
    ) {
        self.totalSleepMinutes = totalSleepMinutes
        self.walkCount = walkCount
        self.totalWalkMinutes = totalWalkMinutes
        self.outdoorPottyCount = outdoorPottyCount
        self.indoorPottyCount = indoorPottyCount
        self.mealCount = mealCount
    }

    /// Total potty count (indoor + outdoor)
    public var totalPottyCount: Int {
        outdoorPottyCount + indoorPottyCount
    }

    /// Sleep formatted as "Xh Ym"
    public var sleepString: String {
        let hours = totalSleepMinutes / 60
        let mins = totalSleepMinutes % 60
        if hours == 0 {
            return "\(mins)m"
        } else if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }

    /// Potty success rate (outdoor / total)
    public var pottySuccessRate: Double {
        guard totalPottyCount > 0 else { return 1.0 }
        return Double(outdoorPottyCount) / Double(totalPottyCount)
    }

    /// Empty summary
    public static let empty = ActivityBlockSummary()
}
