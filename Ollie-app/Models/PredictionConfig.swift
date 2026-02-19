//
//  PredictionConfig.swift
//  Ollie-app
//

import Foundation

/// Configurable prediction parameters for potty timing
struct PredictionConfig: Codable {
    /// Naps shorter than this don't trigger post-sleep potty predictions
    var minNapDurationForPottyTrigger: Int

    /// Hour when bedtime starts (used for night sleep detection)
    var bedtimeHour: Int

    /// Multiplier for expected gap after eating (shorter gaps expected)
    var postMealGapMultiplier: Double

    /// Multiplier for expected gap after sleeping (shorter gaps expected)
    var postSleepGapMultiplier: Double

    /// Default gap if no historical data available
    var defaultGapMinutes: Int

    static func defaultConfig() -> PredictionConfig {
        PredictionConfig(
            minNapDurationForPottyTrigger: 15,
            bedtimeHour: 22,
            postMealGapMultiplier: 0.75,
            postSleepGapMultiplier: 0.75,
            defaultGapMinutes: 90
        )
    }
}
