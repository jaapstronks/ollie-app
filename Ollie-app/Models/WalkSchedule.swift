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
        var label: String       // "Ochtendwandeling", "Middagwandeling", "Avondwandeling"
        var targetTime: String  // "08:00", "18:00"

        init(id: UUID = UUID(), label: String, targetTime: String) {
            self.id = id
            self.label = label
            self.targetTime = targetTime
        }
    }

    /// Default schedule with 3 walks per day
    static func defaultSchedule() -> WalkSchedule {
        WalkSchedule(walks: [
            ScheduledWalk(label: Strings.Walks.morningWalk, targetTime: "08:00"),
            ScheduledWalk(label: Strings.Walks.afternoonWalk, targetTime: "12:30"),
            ScheduledWalk(label: Strings.Walks.eveningWalk, targetTime: "18:00")
        ])
    }
}
