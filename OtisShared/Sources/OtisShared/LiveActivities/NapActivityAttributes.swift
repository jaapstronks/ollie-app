//
//  NapActivityAttributes.swift
//  OtisShared
//
//  ActivityAttributes definition for nap Live Activity
//  Shared between main app and widget extension
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Attributes for the nap Live Activity
@available(iOS 16.1, *)
public struct NapActivityAttributes: ActivityAttributes {
    /// Dynamic content state that updates during the activity
    public struct ContentState: Codable, Hashable {
        /// Whether the nap has ended (used for dismissal animation)
        public var hasEnded: Bool

        public init(hasEnded: Bool = false) {
            self.hasEnded = hasEnded
        }
    }

    /// Puppy's name for display
    public var puppyName: String

    /// When the nap started
    public var startTime: Date

    /// ID of the InProgressActivity for coordination
    public var activityId: UUID

    public init(puppyName: String, startTime: Date, activityId: UUID) {
        self.puppyName = puppyName
        self.startTime = startTime
        self.activityId = activityId
    }
}
#endif
