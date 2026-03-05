//
//  DevelopmentStage.swift
//  OtisShared
//
//  Canonical model for puppy developmental stages based on age.
//  This is the single source of truth for developmental period classification.
//

import Foundation

/// The six canonical developmental stages of a puppy's life.
/// Based on veterinary science and developmental research.
///
/// This is the primary model for development tracking. Use this instead of
/// creating parallel models. UI-specific adaptations (like SocializationPhase)
/// should be computed from this canonical model.
public enum DevelopmentStage: String, CaseIterable, Identifiable, Codable, Sendable {
    case neonatal
    case transitional
    case socialization
    case juvenile
    case adolescent
    case adult

    public var id: String { rawValue }

    // MARK: - Age Boundaries

    /// Start week for this developmental stage
    public var startWeek: Int {
        switch self {
        case .neonatal: return 0
        case .transitional: return 2
        case .socialization: return 3
        case .juvenile: return 16
        case .adolescent: return 26
        case .adult: return 78
        }
    }

    /// End week for this developmental stage (exclusive upper bound)
    public var endWeek: Int {
        switch self {
        case .neonatal: return 2
        case .transitional: return 3
        case .socialization: return 16
        case .juvenile: return 26
        case .adolescent: return 78
        case .adult: return 200  // Practical upper bound
        }
    }

    /// Duration in weeks for this stage
    public var durationWeeks: Int {
        endWeek - startWeek
    }

    // MARK: - Visual Properties

    /// SF Symbol icon for this stage
    public var icon: String {
        switch self {
        case .neonatal: return "heart.fill"
        case .transitional: return "eye.fill"
        case .socialization: return "person.3.fill"
        case .juvenile: return "figure.walk"
        case .adolescent: return "figure.run"
        case .adult: return "pawprint.fill"
        }
    }

    // MARK: - Stage Lookup

    /// Determines the developmental stage for a given age in weeks
    public static func stage(for ageInWeeks: Int) -> DevelopmentStage {
        switch ageInWeeks {
        case 0..<2: return .neonatal
        case 2..<3: return .transitional
        case 3..<16: return .socialization
        case 16..<26: return .juvenile
        case 26..<78: return .adolescent
        default: return .adult
        }
    }

    /// Progress through this stage (0.0 to 1.0) for a given age
    public func progress(ageInWeeks: Int) -> Double {
        guard endWeek > startWeek else { return 1.0 }

        if ageInWeeks < startWeek { return 0.0 }
        if ageInWeeks >= endWeek { return 1.0 }

        return Double(ageInWeeks - startWeek) / Double(endWeek - startWeek)
    }
}
