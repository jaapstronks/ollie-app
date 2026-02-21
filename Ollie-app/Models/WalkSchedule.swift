//
//  WalkSchedule.swift
//  Ollie-app
//

import Foundation

/// Configurable walk schedule for a puppy
struct WalkSchedule: Codable {
    var walks: [ScheduledWalk]

    struct ScheduledWalk: Codable, Identifiable {
        var id: UUID
        var label: String       // "Morning walk", "Afternoon walk", "Evening walk"
        var targetTime: String  // "08:00", "18:00"

        init(id: UUID = UUID(), label: String, targetTime: String) {
            self.id = id
            self.label = label
            self.targetTime = targetTime
        }
    }

    /// Default schedule with 9 walks per day for puppies (every 2 hours from 6:00 to 22:00)
    /// These serve as guidelines - the smart suggestion system adapts based on actual walk times
    static func defaultSchedule() -> WalkSchedule {
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
    func closestSlot(to date: Date) -> ScheduledWalk? {
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
    var firstWalkTime: String? {
        walks.first?.targetTime
    }

    /// Get the last scheduled walk of the day
    var lastWalkTime: String? {
        walks.last?.targetTime
    }
}
