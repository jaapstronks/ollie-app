//
//  TrainingPlan.swift
//  Ollie-app
//
//  Training plan data models - skills, categories, and weekly plans
//

import Foundation

// MARK: - Training Category

/// Categories for grouping training skills
enum TrainingCategory: String, Codable, CaseIterable, Identifiable {
    case fundamenten
    case basiscommandos
    case verzorging
    case veiligheid
    case impulscontrole

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fundamenten: return Strings.Training.categoryFoundations
        case .basiscommandos: return Strings.Training.categoryBasicCommands
        case .verzorging: return Strings.Training.categoryCare
        case .veiligheid: return Strings.Training.categorySafety
        case .impulscontrole: return Strings.Training.categoryImpulseControl
        }
    }

    var emoji: String {
        switch self {
        case .fundamenten: return "🧱"
        case .basiscommandos: return "📢"
        case .verzorging: return "🛁"
        case .veiligheid: return "🦺"
        case .impulscontrole: return "🧘"
        }
    }
}

// MARK: - Skill

/// A training skill that can be taught to a puppy
struct Skill: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let howTo: [String]
    let doneWhen: String
    let tips: [String]
    let category: TrainingCategory
    let week: Int
    let priority: Int
    let requires: [String]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Skill, rhs: Skill) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Week Plan

/// A weekly focus plan for training
struct WeekPlan: Codable, Identifiable {
    let week: Int
    let title: String
    let focusSkillIds: [String]

    var id: Int { week }
}

// MARK: - Training Plan

/// The complete training plan with all skills and weekly schedules
struct TrainingPlan: Codable {
    let skills: [Skill]
    let weekPlans: [WeekPlan]

    /// Get a skill by its ID
    func skill(withId id: String) -> Skill? {
        skills.first { $0.id == id }
    }

    /// Get all skills for a specific category
    func skills(for category: TrainingCategory) -> [Skill] {
        skills.filter { $0.category == category }
    }

    /// Get the week plan for a specific week
    func weekPlan(for week: Int) -> WeekPlan? {
        weekPlans.first { $0.week == week }
    }

    /// Get all focus skills for a specific week
    func focusSkills(for week: Int) -> [Skill] {
        guard let plan = weekPlan(for: week) else { return [] }
        return plan.focusSkillIds.compactMap { skill(withId: $0) }
    }

    /// Check if all requirements are met for a skill
    func requirementsMet(for skillId: String, masteredSkillIds: Set<String>, startedSkillIds: Set<String>) -> Bool {
        guard let skill = skill(withId: skillId) else { return false }

        // A skill is unlocked if all its requirements are either mastered or at least started
        for requiredId in skill.requires {
            if !masteredSkillIds.contains(requiredId) && !startedSkillIds.contains(requiredId) {
                return false
            }
        }
        return true
    }

    /// Get the skill IDs that are missing (requirements not met)
    func missingRequirements(for skillId: String, startedSkillIds: Set<String>) -> [Skill] {
        guard let skill = skill(withId: skillId) else { return [] }
        return skill.requires
            .filter { !startedSkillIds.contains($0) }
            .compactMap { self.skill(withId: $0) }
    }
}
