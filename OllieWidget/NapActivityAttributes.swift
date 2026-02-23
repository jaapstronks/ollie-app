//
//  NapActivityAttributes.swift
//  OllieWidget
//
//  ActivityAttributes definition for nap Live Activity (widget extension copy)
//

import Foundation
import ActivityKit

/// Attributes for the nap Live Activity
struct NapActivityAttributes: ActivityAttributes {
    /// Dynamic content state that updates during the activity
    struct ContentState: Codable, Hashable {
        /// Whether the nap has ended (used for dismissal animation)
        var hasEnded: Bool
    }

    /// Puppy's name for display
    var puppyName: String

    /// When the nap started
    var startTime: Date

    /// ID of the InProgressActivity for coordination
    var activityId: UUID
}
