//
//  WalkSchedule.swift
//  OllieShared
//

import Foundation

// MARK: - Walk Schedule Mode

/// How walk times are determined
public enum WalkScheduleMode: String, Codable, CaseIterable, Sendable {
    /// Walk times are calculated based on when the last walk happened
    /// `nextWalk = lastWalk + intervalMinutes`
    case flexible

    /// Walk times are fixed to the scheduled times
    case strict

    public var label: String {
        switch self {
        case .flexible: return Strings.WalkSchedule.modeFlexible
        case .strict: return Strings.WalkSchedule.modeStrict
        }
    }

    public var description: String {
        switch self {
        case .flexible: return Strings.WalkSchedule.modeFlexibleDescription
        case .strict: return Strings.WalkSchedule.modeStrictDescription
        }
    }
}

// MARK: - Max Duration Rule

/// Rule for calculating maximum walk duration
public enum MaxDurationRule: Codable, Sendable, Equatable {
    /// Minutes per month of age (e.g., "5 min per month")
    case minutesPerMonth(Int)

    /// Fixed maximum duration in minutes
    case fixedMinutes(Int)

    public var label: String {
        switch self {
        case .minutesPerMonth(let minutes):
            return Strings.WalkSchedule.minutesPerMonthRule(minutes)
        case .fixedMinutes(let minutes):
            return Strings.WalkSchedule.fixedMinutesRule(minutes)
        }
    }

    /// Calculate max duration for a given age in months
    public func maxDuration(ageInMonths: Int) -> Int {
        switch self {
        case .minutesPerMonth(let minutesPerMonth):
            return max(1, ageInMonths) * minutesPerMonth
        case .fixedMinutes(let minutes):
            return minutes
        }
    }
}

// MARK: - Walk Schedule

/// Configurable walk schedule for a puppy
public struct WalkSchedule: Codable, Sendable {
    public var mode: WalkScheduleMode
    public var walks: [ScheduledWalk]
    public var intervalMinutes: Int
    public var dayStartHour: Int
    public var dayEndHour: Int
    public var maxDurationRule: MaxDurationRule

    /// Number of walks per day (derived from schedule)
    public var walksPerDay: Int { walks.count }

    public init(
        mode: WalkScheduleMode = .flexible,
        walks: [ScheduledWalk],
        intervalMinutes: Int = 120,
        dayStartHour: Int = 6,
        dayEndHour: Int = 22,
        maxDurationRule: MaxDurationRule = .minutesPerMonth(5)
    ) {
        self.mode = mode
        self.walks = walks
        self.intervalMinutes = intervalMinutes
        self.dayStartHour = dayStartHour
        self.dayEndHour = dayEndHour
        self.maxDurationRule = maxDurationRule
    }

    public struct ScheduledWalk: Codable, Identifiable, Sendable {
        public var id: UUID
        public var label: String
        public var targetTime: String

        public init(id: UUID = UUID(), label: String, targetTime: String) {
            self.id = id
            self.label = label
            self.targetTime = targetTime
        }
    }

    // MARK: - Codable (backward compatible)

    private enum CodingKeys: String, CodingKey {
        case mode, walks, intervalMinutes, dayStartHour, dayEndHour, maxDurationRule
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required field
        walks = try container.decode([ScheduledWalk].self, forKey: .walks)

        // New fields with backward-compatible defaults
        mode = try container.decodeIfPresent(WalkScheduleMode.self, forKey: .mode) ?? .flexible
        intervalMinutes = try container.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? 120
        dayStartHour = try container.decodeIfPresent(Int.self, forKey: .dayStartHour) ?? 6
        dayEndHour = try container.decodeIfPresent(Int.self, forKey: .dayEndHour) ?? 24
        maxDurationRule = try container.decodeIfPresent(MaxDurationRule.self, forKey: .maxDurationRule) ?? .minutesPerMonth(5)
    }

    // MARK: - Default Schedules

    /// Default schedule (backward compatible - 9 walks for young puppies)
    public static func defaultSchedule() -> WalkSchedule {
        defaultSchedule(ageWeeks: 8)  // Default to young puppy
    }

    /// Age-aware default schedule
    public static func defaultSchedule(ageWeeks: Int) -> WalkSchedule {
        let walks: [ScheduledWalk]
        let interval: Int

        switch ageWeeks {
        case 0..<12:  // < 3 months - frequent potty breaks
            walks = generateEvenlySpaced(count: 8, from: 6, to: 24)
            interval = 120 // 2 hours
        case 12..<24: // 3-6 months
            walks = generateEvenlySpaced(count: 6, from: 6, to: 24)
            interval = 120 // 2 hours
        case 24..<52: // 6-12 months
            walks = generateEvenlySpaced(count: 4, from: 6, to: 24)
            interval = 180 // 3 hours
        default:      // 12+ months (adult)
            walks = generateEvenlySpaced(count: 3, from: 6, to: 24)
            interval = 240 // 4 hours
        }

        return WalkSchedule(
            mode: .flexible,
            walks: walks,
            intervalMinutes: interval,
            dayStartHour: 6,
            dayEndHour: 24,  // Midnight - puppies can't hold bladders long
            maxDurationRule: .minutesPerMonth(5)
        )
    }

    /// Generate evenly spaced walks between start and end hours
    private static func generateEvenlySpaced(count: Int, from startHour: Int, to endHour: Int) -> [ScheduledWalk] {
        guard count > 0 else { return [] }

        let totalMinutes = (endHour - startHour) * 60
        let interval = count > 1 ? totalMinutes / (count - 1) : 0

        var walks: [ScheduledWalk] = []
        for i in 0..<count {
            let minutesFromStart = i * interval
            let hour = startHour + minutesFromStart / 60
            let minute = minutesFromStart % 60
            let timeString = String(format: "%02d:%02d", hour, minute)
            let label = labelForIndex(i, of: count)
            walks.append(ScheduledWalk(label: label, targetTime: timeString))
        }
        return walks
    }

    /// Generate a default label for a walk at a given index
    private static func labelForIndex(_ index: Int, of total: Int) -> String {
        // Use descriptive labels for common positions
        if total <= 4 {
            switch index {
            case 0: return Strings.Walks.morningWalk
            case 1 where total == 2: return Strings.Walks.eveningWalk
            case 1 where total >= 3: return Strings.Walks.afternoonWalk
            case 2 where total == 3: return Strings.Walks.eveningWalk
            case 2 where total == 4: return Strings.Walks.lateAfternoon
            case 3: return Strings.Walks.eveningWalk
            default: return Strings.WalkSchedule.walkNumber(index + 1)
            }
        } else {
            // For many walks, use time-based labels
            switch index {
            case 0: return Strings.Walks.earlyMorning
            case 1: return Strings.Walks.morningWalk
            case 2: return Strings.Walks.midMorning
            case 3: return Strings.Walks.lunchWalk
            case 4: return Strings.Walks.earlyAfternoon
            case 5: return Strings.Walks.afternoonWalk
            case 6: return Strings.Walks.eveningWalk
            case 7: return Strings.Walks.lateEvening
            case 8: return Strings.Walks.nightWalk
            default: return Strings.WalkSchedule.walkNumber(index + 1)
            }
        }
    }

    /// Find the closest scheduled walk slot to a given time
    public func closestSlot(to date: Date) -> ScheduledWalk? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute

        var closestWalk: ScheduledWalk?
        var smallestDiff = Int.max

        for walk in walks {
            let parts = walk.targetTime.split(separator: ":")
            guard parts.count >= 2,
                  let h = Int(parts[0]),
                  let m = Int(parts[1]) else { continue }
            let walkMinutes = h * 60 + m
            let diff = abs(walkMinutes - currentMinutes)
            if diff < smallestDiff {
                smallestDiff = diff
                closestWalk = walk
            }
        }

        return closestWalk
    }

    /// Get the first scheduled walk of the day
    public var firstWalkTime: String? {
        walks.first?.targetTime
    }

    /// Get the last scheduled walk of the day
    public var lastWalkTime: String? {
        walks.last?.targetTime
    }
}
