//
//  SkillStatus.swift
//  Ollie-app
//
//  Skill status tracking and calculations
//

import Foundation
import OllieShared
import SwiftUI

// MARK: - Skill Status

/// The current status of a training skill
enum SkillStatus: String, Codable {
    case notStarted
    case started      // < 4 sessions
    case practicing   // 4+ sessions
    case mastered     // manually marked by user

    var label: String {
        switch self {
        case .notStarted: return Strings.Training.statusNotStarted
        case .started: return Strings.Training.statusStarted
        case .practicing: return Strings.Training.statusPracticing
        case .mastered: return Strings.Training.statusMastered
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .secondary
        case .started: return .ollieInfo
        case .practicing: return .ollieWarning
        case .mastered: return .ollieSuccess
        }
    }

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .started: return "circle.dotted"
        case .practicing: return "circle.inset.filled"
        case .mastered: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Skill Status Calculations

/// Static methods for calculating skill status
enum SkillStatusCalculations {
    /// Minimum sessions required to move from "started" to "practicing"
    static let practicingThreshold = 4

    /// Calculate the status for a skill based on session count and mastery
    static func calculateStatus(
        sessionCount: Int,
        isMastered: Bool
    ) -> SkillStatus {
        if isMastered {
            return .mastered
        } else if sessionCount >= practicingThreshold {
            return .practicing
        } else if sessionCount > 0 {
            return .started
        } else {
            return .notStarted
        }
    }

    /// Check if a skill is locked (requirements not met)
    static func isLocked(
        skill: Skill,
        startedSkillIds: Set<String>,
        trainingPlan: TrainingPlan
    ) -> Bool {
        // A skill with no requirements is never locked
        if skill.requires.isEmpty {
            return false
        }

        // A skill is locked if any of its requirements have not been started
        return !trainingPlan.requirementsMet(
            for: skill.id,
            masteredSkillIds: [],  // We use started as the minimum requirement
            startedSkillIds: startedSkillIds
        )
    }

    /// Get progress stats for a category
    static func categoryProgress(
        category: TrainingCategory,
        skills: [Skill],
        sessionCounts: [String: Int],
        masteredSkillIds: Set<String>
    ) -> (started: Int, total: Int) {
        let categorySkills = skills.filter { $0.category == category }
        let startedCount = categorySkills.filter { skill in
            let count = sessionCounts[skill.id] ?? 0
            let status = calculateStatus(sessionCount: count, isMastered: masteredSkillIds.contains(skill.id))
            return status != .notStarted
        }.count

        return (startedCount, categorySkills.count)
    }

    /// Get overall progress percentage
    static func overallProgress(
        skills: [Skill],
        sessionCounts: [String: Int],
        masteredSkillIds: Set<String>
    ) -> Double {
        guard !skills.isEmpty else { return 0 }

        let totalStarted = skills.filter { skill in
            let count = sessionCounts[skill.id] ?? 0
            let status = calculateStatus(sessionCount: count, isMastered: masteredSkillIds.contains(skill.id))
            return status != .notStarted
        }.count

        return Double(totalStarted) / Double(skills.count)
    }
}
