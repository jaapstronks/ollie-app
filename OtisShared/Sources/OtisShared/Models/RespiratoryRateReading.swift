//
//  RespiratoryRateReading.swift
//  OtisShared
//
//  Resting respiratory rate tracking model for heart condition monitoring
//  Part of Brief 05: Senior Wellness
//

import Foundation

// MARK: - RRR Status

/// Status levels for resting respiratory rate readings
public enum RRRStatus: String, Codable, Sendable {
    case normal
    case elevated
    case emergency

    public var label: String {
        switch self {
        case .normal: return Strings.SeniorWellness.rrrStatusNormal
        case .elevated: return Strings.SeniorWellness.rrrStatusElevated
        case .emergency: return Strings.SeniorWellness.rrrStatusEmergency
        }
    }

    public var message: String {
        switch self {
        case .normal:
            return Strings.SeniorWellness.rrrMessageNormal
        case .elevated:
            return Strings.SeniorWellness.rrrMessageElevated
        case .emergency:
            return Strings.SeniorWellness.rrrMessageEmergency
        }
    }

    public var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .elevated: return "exclamationmark.circle.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        }
    }

    public var colorName: String {
        switch self {
        case .normal: return "otisSuccess"
        case .elevated: return "otisWarning"
        case .emergency: return "otisError"
        }
    }
}

// MARK: - Respiratory Rate Reading

/// A single resting respiratory rate measurement
public struct RespiratoryRateReading: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var breathsPerMinute: Int
    public var wasResting: Bool
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        breathsPerMinute: Int,
        wasResting: Bool = true,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.breathsPerMinute = max(0, breathsPerMinute)
        self.wasResting = wasResting
        self.note = note
        self.createdAt = createdAt
    }

    /// Factory method for creating from a 30-second count
    public static func fromHalfMinuteCount(_ breaths: Int, wasResting: Bool = true, note: String? = nil) -> RespiratoryRateReading {
        RespiratoryRateReading(
            breathsPerMinute: breaths * 2,
            wasResting: wasResting,
            note: note
        )
    }

    /// Status based on breaths per minute
    public var status: RRRStatus {
        switch breathsPerMinute {
        case 0..<20: return .normal
        case 20..<30: return .elevated
        default: return .emergency
        }
    }

    /// Whether this reading is concerning (elevated or emergency)
    public var isConcerning: Bool {
        status != .normal
    }

    /// Whether this is an emergency reading (≥30 bpm)
    public var isEmergency: Bool {
        status == .emergency
    }

    /// Days since this reading was recorded
    public var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    /// Whether this reading is from today
    public var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }

    /// Whether this reading is recent (within 24 hours)
    public var isRecent: Bool {
        daysAgo == 0
    }

    /// Formatted breaths per minute string
    public var formattedBPM: String {
        "\(breathsPerMinute) bpm"
    }
}

// MARK: - RRR Trend

/// Trend direction for respiratory rate over time
public enum RRRTrend: String, Codable, Sendable {
    case decreasing
    case stable
    case increasing

    public var label: String {
        switch self {
        case .decreasing: return Strings.SeniorWellness.rrrTrendDecreasing
        case .stable: return Strings.SeniorWellness.rrrTrendStable
        case .increasing: return Strings.SeniorWellness.rrrTrendIncreasing
        }
    }

    public var icon: String {
        switch self {
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .increasing: return "arrow.up.right"
        }
    }

    public var colorName: String {
        switch self {
        case .decreasing: return "otisSuccess"
        case .stable: return "otisInfo"
        case .increasing: return "otisWarning"
        }
    }
}

// MARK: - RRR State

/// Aggregated respiratory rate state for AI context
public struct RRRState: Codable, Sendable {
    public let latestReading: RespiratoryRateReading?
    public let trend: RRRTrend?
    public let averageBPM: Double?
    public let readingCount: Int
    public let elevatedReadingsThisWeek: Int
    public let hasHeartCondition: Bool

    public init(
        latestReading: RespiratoryRateReading? = nil,
        trend: RRRTrend? = nil,
        averageBPM: Double? = nil,
        readingCount: Int = 0,
        elevatedReadingsThisWeek: Int = 0,
        hasHeartCondition: Bool = false
    ) {
        self.latestReading = latestReading
        self.trend = trend
        self.averageBPM = averageBPM
        self.readingCount = readingCount
        self.elevatedReadingsThisWeek = elevatedReadingsThisWeek
        self.hasHeartCondition = hasHeartCondition
    }

    /// Whether respiratory data suggests concerns
    public var hasConcerns: Bool {
        guard let latest = latestReading else { return false }
        return latest.isConcerning || trend == .increasing || elevatedReadingsThisWeek >= 2
    }

    /// Whether daily tracking should be suggested (heart conditions)
    public var shouldSuggestDailyTracking: Bool {
        hasHeartCondition && (latestReading?.daysAgo ?? Int.max) > 0
    }
}

// MARK: - RRR Thresholds

/// Standard thresholds for resting respiratory rate
public enum RRRThreshold {
    /// Normal resting rate (< 20 bpm at rest)
    public static let normal = 20

    /// Elevated rate requiring monitoring (20-29 bpm)
    public static let elevated = 30

    /// Emergency threshold requiring immediate vet attention (≥ 30 bpm)
    public static let emergency = 30
}
