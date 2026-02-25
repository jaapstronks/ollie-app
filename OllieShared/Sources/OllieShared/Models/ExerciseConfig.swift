//
//  ExerciseConfig.swift
//  OllieShared
//

import Foundation

/// Configurable exercise limits for a puppy
/// Note: Walk scheduling has been consolidated into WalkSchedule.
/// Use WalkSchedule.walksPerDay instead of maxWalksPerDay.
/// Use WalkSchedule.maxDurationRule instead of minutesPerMonthOfAge for walk-specific limits.
public struct ExerciseConfig: Codable, Sendable {
    public var minutesPerMonthOfAge: Int

    /// Deprecated: Use WalkSchedule.walksPerDay instead.
    /// This field is kept for backward compatibility with existing profiles.
    @available(*, deprecated, message: "Use WalkSchedule.walksPerDay instead")
    public var maxWalksPerDay: Int?

    public init(minutesPerMonthOfAge: Int, maxWalksPerDay: Int? = nil) {
        self.minutesPerMonthOfAge = minutesPerMonthOfAge
        self.maxWalksPerDay = maxWalksPerDay
    }

    /// The widely-used "5 minutes per month of age" rule
    public static func defaultConfig() -> ExerciseConfig {
        ExerciseConfig(
            minutesPerMonthOfAge: 5,
            maxWalksPerDay: nil  // Now managed by WalkSchedule
        )
    }
}
