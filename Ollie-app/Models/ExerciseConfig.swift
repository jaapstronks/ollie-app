//
//  ExerciseConfig.swift
//  Ollie-app
//

import Foundation

/// Configurable exercise limits for a puppy
struct ExerciseConfig: Codable {
    var minutesPerMonthOfAge: Int
    var maxWalksPerDay: Int?

    /// The widely-used "5 minutes per month of age" rule
    static func defaultConfig() -> ExerciseConfig {
        ExerciseConfig(
            minutesPerMonthOfAge: 5,
            maxWalksPerDay: 2
        )
    }
}
