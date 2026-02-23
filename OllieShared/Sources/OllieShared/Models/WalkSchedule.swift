//
//  WalkSchedule.swift
//  OllieShared
//

import Foundation

/// Configurable walk schedule for a puppy
public struct WalkSchedule: Codable, Sendable {
    public var walks: [ScheduledWalk]

    public init(walks: [ScheduledWalk]) {
        self.walks = walks
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

    /// Default schedule with 9 walks per day for puppies
    public static func defaultSchedule() -> WalkSchedule {
        WalkSchedule(walks: [
            ScheduledWalk(label: Strings.Walks.earlyMorning, targetTime: "06:00"),
            ScheduledWalk(label: Strings.Walks.morningWalk, targetTime: "08:00"),
            ScheduledWalk(label: Strings.Walks.midMorning, targetTime: "10:00"),
            ScheduledWalk(label: Strings.Walks.lunchWalk, targetTime: "12:00"),
            ScheduledWalk(label: Strings.Walks.earlyAfternoon, targetTime: "14:00"),
            ScheduledWalk(label: Strings.Walks.afternoonWalk, targetTime: "16:00"),
            ScheduledWalk(label: Strings.Walks.eveningWalk, targetTime: "18:00"),
            ScheduledWalk(label: Strings.Walks.lateEvening, targetTime: "20:00"),
            ScheduledWalk(label: Strings.Walks.nightWalk, targetTime: "22:00")
        ])
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
