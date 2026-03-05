//
//  PuppyProfile+Development.swift
//  OtisShared
//
//  Unified access layer for all development and socialization window calculations.
//  This extension provides a single, consistent API for development-related queries.
//

import Foundation

extension PuppyProfile {

    // MARK: - Development Stage (Canonical)

    /// The puppy's current developmental stage based on age
    public var currentDevelopmentStage: DevelopmentStage {
        DevelopmentStage.stage(for: ageInWeeks)
    }

    /// Progress through the current developmental stage (0.0 to 1.0)
    public var developmentStageProgress: Double {
        currentDevelopmentStage.progress(ageInWeeks: ageInWeeks)
    }

    // MARK: - Socialization Window (Single Source of Truth)

    /// Complete status of the socialization window
    /// Use this instead of calculating weeks remaining manually
    public var socializationWindowStatus: SocializationWindowStatus {
        SocializationWindowStatus(ageInWeeks: ageInWeeks)
    }

    /// Whether the puppy is currently in the socialization window (weeks 3-16)
    public var isInSocializationWindow: Bool {
        socializationWindowStatus.isOpen
    }

    /// Weeks remaining in socialization window, or nil if closed
    public var socializationWindowWeeksRemaining: Int? {
        SocializationWindowStatus.weeksRemaining(ageInWeeks: ageInWeeks)
    }

    // MARK: - Socialization Training Phase (UI Helper)

    /// Current phase for the socialization training UI
    /// This is a UI concern based on days home, distinct from the canonical development stage
    public var socializationTrainingPhase: SocializationPhase {
        SocializationPhase.current(daysHome: daysHome, ageInWeeks: ageInWeeks)
    }

    // MARK: - Fear Periods

    /// Whether the puppy is in the first fear period (weeks 8-11)
    public var isInFirstFearPeriod: Bool {
        ageInWeeks >= 8 && ageInWeeks <= 11
    }

    /// Whether the puppy is in the second fear period (varies, roughly weeks 18-24)
    public var isInSecondFearPeriod: Bool {
        ageInWeeks >= 18 && ageInWeeks <= 24
    }

    /// Whether the puppy is in any sensitive fear period
    public var isInFearPeriod: Bool {
        isInFirstFearPeriod || isInSecondFearPeriod
    }
}
