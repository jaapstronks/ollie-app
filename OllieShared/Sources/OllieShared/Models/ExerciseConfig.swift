//
//  ExerciseConfig.swift
//  OllieShared
//

import Foundation

/// Configurable exercise limits for a puppy
public struct ExerciseConfig: Codable, Sendable {
    public var minutesPerMonthOfAge: Int
    public var maxWalksPerDay: Int?

    public init(minutesPerMonthOfAge: Int, maxWalksPerDay: Int? = nil) {
        self.minutesPerMonthOfAge = minutesPerMonthOfAge
        self.maxWalksPerDay = maxWalksPerDay
    }

    /// The widely-used "5 minutes per month of age" rule
    public static func defaultConfig() -> ExerciseConfig {
        ExerciseConfig(
            minutesPerMonthOfAge: 5,
            maxWalksPerDay: 2
        )
    }
}
