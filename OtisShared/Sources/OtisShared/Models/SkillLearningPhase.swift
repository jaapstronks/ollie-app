//
//  SkillLearningPhase.swift
//  OtisShared
//
//  The lifecycle phase of a training skill
//  Based on professional dog training methodology (AKC, Susan Garrett, guide dog programs)
//

import Foundation

/// The lifecycle phase of a training skill
public enum SkillLearningPhase: String, Codable, CaseIterable, Sendable {
    /// Never practiced - skill not yet started
    case notStarted

    /// Learning the physical behavior through luring or shaping
    /// No verbal cue yet - dog is discovering the behavior
    case luring

    /// Pairing a verbal command and/or hand signal with the behavior
    /// Behavior is established, now adding the cue
    case addingCue

    /// Testing and reinforcing across the 3Ds: Duration, Distance, Distraction
    /// Only increase one D at a time
    case proofing

    /// Practicing in novel environments to ensure transfer
    /// Skill should work in multiple contexts
    case generalizing

    /// Skill is mastered, enters spaced repetition cycle
    /// Periodic maintenance checks with expanding intervals
    case maintaining

    /// Regression from maintenance - skill failed a check
    /// Gets highest priority until re-stabilized at 80%+
    case needsWork

    /// Display label key for the phase (localization handled by UI layer)
    public var labelKey: String {
        rawValue
    }

    /// SF Symbol icon name for the phase
    public var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .luring: return "hand.point.right.fill"
        case .addingCue: return "speaker.wave.2.fill"
        case .proofing: return "chart.bar.fill"
        case .generalizing: return "location.fill"
        case .maintaining: return "checkmark.seal.fill"
        case .needsWork: return "exclamationmark.triangle.fill"
        }
    }

    /// Whether this phase is considered "active learning"
    public var isActiveLearning: Bool {
        switch self {
        case .luring, .addingCue, .proofing, .generalizing:
            return true
        default:
            return false
        }
    }

    /// Whether this skill needs maintenance reviews
    public var requiresMaintenance: Bool {
        self == .maintaining
    }

    /// Whether this skill is in regression state
    public var isRegression: Bool {
        self == .needsWork
    }

    /// Sort order for priority (lower = higher priority)
    public var priorityOrder: Int {
        switch self {
        case .needsWork: return 1      // Highest priority
        case .luring: return 2
        case .addingCue: return 3
        case .proofing: return 4
        case .generalizing: return 5
        case .maintaining: return 6
        case .notStarted: return 7     // Lowest priority
        }
    }

    /// Whether confidence score should be displayed for this phase
    /// Early phases (luring, addingCue) focus on learning the behavior, not reliability
    /// Showing 100% confidence with 1-2 reps is misleading
    public var shouldShowConfidence: Bool {
        switch self {
        case .proofing, .generalizing, .maintaining, .needsWork:
            return true
        case .notStarted, .luring, .addingCue:
            return false
        }
    }
}
