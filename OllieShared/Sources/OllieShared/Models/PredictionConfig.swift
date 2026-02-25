//
//  PredictionConfig.swift
//  OllieShared
//

import Foundation

/// Configurable prediction parameters for potty timing
public struct PredictionConfig: Codable, Sendable {
    /// Naps shorter than this don't trigger post-sleep potty predictions
    public var minNapDurationForPottyTrigger: Int

    /// Hour when bedtime starts (used for night sleep detection)
    public var bedtimeHour: Int

    /// Multiplier for expected gap after eating (shorter gaps expected)
    public var postMealGapMultiplier: Double

    /// Multiplier for expected gap after sleeping (shorter gaps expected)
    public var postSleepGapMultiplier: Double

    /// Default gap if no historical data available
    public var defaultGapMinutes: Int

    public init(
        minNapDurationForPottyTrigger: Int,
        bedtimeHour: Int,
        postMealGapMultiplier: Double,
        postSleepGapMultiplier: Double,
        defaultGapMinutes: Int
    ) {
        self.minNapDurationForPottyTrigger = minNapDurationForPottyTrigger
        self.bedtimeHour = bedtimeHour
        self.postMealGapMultiplier = postMealGapMultiplier
        self.postSleepGapMultiplier = postSleepGapMultiplier
        self.defaultGapMinutes = defaultGapMinutes
    }

    public static func defaultConfig() -> PredictionConfig {
        PredictionConfig(
            minNapDurationForPottyTrigger: 15,
            bedtimeHour: 22,
            postMealGapMultiplier: 0.75,
            postSleepGapMultiplier: 0.75,
            defaultGapMinutes: 90
        )
    }
}
