//
//  TrainingPlan.swift
//  Ollie-app
//
//  Training plan data models - skills, categories, and weekly plans
//

import Foundation
import SwiftUI

// MARK: - Training Category

/// Categories for grouping training skills
enum TrainingCategory: String, Codable, CaseIterable, Identifiable {
    case foundations
    case basicCommands
    case care
    case safety
    case impulseControl

    var id: String { rawValue }

    var label: String {
        switch self {
        case .foundations: return Strings.Training.categoryFoundations
        case .basicCommands: return Strings.Training.categoryBasicCommands
        case .care: return Strings.Training.categoryCare
        case .safety: return Strings.Training.categorySafety
        case .impulseControl: return Strings.Training.categoryImpulseControl
        }
    }

    var icon: String {
        switch self {
        case .foundations: return "square.stack.3d.up.fill"
        case .basicCommands: return "megaphone.fill"
        case .care: return "heart.fill"
        case .safety: return "shield.checkered"
        case .impulseControl: return "brain.head.profile"
        }
    }

    /// Semantic color for each category
    /// - Foundations: Teal (building blocks, foundational info)
    /// - Basic Commands: Green (action, success)
    /// - Care: Rose (nurturing, love)
    /// - Safety: Gold (caution, attention)
    /// - Impulse Control: Purple (mental, focus)
    var color: Color {
        switch self {
        case .foundations: return .ollieInfo
        case .basicCommands: return .ollieSuccess
        case .care: return .ollieRose
        case .safety: return .ollieWarning
        case .impulseControl: return .olliePurple
        }
    }
}

// MARK: - Skill

/// A training skill that can be taught to a puppy
struct Skill: Codable, Identifiable, Hashable {
    let id: String
    let icon: String
    let category: TrainingCategory
    let week: Int
    let priority: Int
    let requires: [String]

    // Localized content - looked up by skill ID
    var name: String { SkillContent.name(for: id) }
    var description: String { SkillContent.description(for: id) }
    var howTo: [String] { SkillContent.howTo(for: id) }
    var doneWhen: String { SkillContent.doneWhen(for: id) }
    var tips: [String] { SkillContent.tips(for: id) }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Skill, rhs: Skill) -> Bool {
        lhs.id == rhs.id
    }

    // Custom coding keys - exclude computed properties
    enum CodingKeys: String, CodingKey {
        case id, icon, category, week, priority, requires
    }
}

// MARK: - Skill Content Lookup

/// Static lookup for localized skill content
enum SkillContent {
    static func name(for skillId: String) -> String {
        switch skillId {
        case "clicker": return Strings.Training.Skills.clickerName
        case "nameRecognition": return Strings.Training.Skills.nameRecognitionName
        case "luring": return Strings.Training.Skills.luringName
        case "handling": return Strings.Training.Skills.handlingName
        case "collarLeash": return Strings.Training.Skills.collarLeashName
        case "sit": return Strings.Training.Skills.sitName
        case "watchMe": return Strings.Training.Skills.watchMeName
        case "touch": return Strings.Training.Skills.touchName
        case "looseLeash": return Strings.Training.Skills.looseLeashName
        case "down": return Strings.Training.Skills.downName
        case "come": return Strings.Training.Skills.comeName
        case "wait": return Strings.Training.Skills.waitName
        case "place": return Strings.Training.Skills.placeName
        case "stay": return Strings.Training.Skills.stayName
        default: return skillId
        }
    }

    static func description(for skillId: String) -> String {
        switch skillId {
        case "clicker": return Strings.Training.Skills.clickerDescription
        case "nameRecognition": return Strings.Training.Skills.nameRecognitionDescription
        case "luring": return Strings.Training.Skills.luringDescription
        case "handling": return Strings.Training.Skills.handlingDescription
        case "collarLeash": return Strings.Training.Skills.collarLeashDescription
        case "sit": return Strings.Training.Skills.sitDescription
        case "watchMe": return Strings.Training.Skills.watchMeDescription
        case "touch": return Strings.Training.Skills.touchDescription
        case "looseLeash": return Strings.Training.Skills.looseLeashDescription
        case "down": return Strings.Training.Skills.downDescription
        case "come": return Strings.Training.Skills.comeDescription
        case "wait": return Strings.Training.Skills.waitDescription
        case "place": return Strings.Training.Skills.placeDescription
        case "stay": return Strings.Training.Skills.stayDescription
        default: return ""
        }
    }

    static func doneWhen(for skillId: String) -> String {
        switch skillId {
        case "clicker": return Strings.Training.Skills.clickerDoneWhen
        case "nameRecognition": return Strings.Training.Skills.nameRecognitionDoneWhen
        case "luring": return Strings.Training.Skills.luringDoneWhen
        case "handling": return Strings.Training.Skills.handlingDoneWhen
        case "collarLeash": return Strings.Training.Skills.collarLeashDoneWhen
        case "sit": return Strings.Training.Skills.sitDoneWhen
        case "watchMe": return Strings.Training.Skills.watchMeDoneWhen
        case "touch": return Strings.Training.Skills.touchDoneWhen
        case "looseLeash": return Strings.Training.Skills.looseLeashDoneWhen
        case "down": return Strings.Training.Skills.downDoneWhen
        case "come": return Strings.Training.Skills.comeDoneWhen
        case "wait": return Strings.Training.Skills.waitDoneWhen
        case "place": return Strings.Training.Skills.placeDoneWhen
        case "stay": return Strings.Training.Skills.stayDoneWhen
        default: return ""
        }
    }

    static func howTo(for skillId: String) -> [String] {
        switch skillId {
        case "clicker": return [
            Strings.Training.Skills.clickerHowTo1,
            Strings.Training.Skills.clickerHowTo2,
            Strings.Training.Skills.clickerHowTo3,
            Strings.Training.Skills.clickerHowTo4,
            Strings.Training.Skills.clickerHowTo5
        ]
        case "nameRecognition": return [
            Strings.Training.Skills.nameRecognitionHowTo1,
            Strings.Training.Skills.nameRecognitionHowTo2,
            Strings.Training.Skills.nameRecognitionHowTo3,
            Strings.Training.Skills.nameRecognitionHowTo4,
            Strings.Training.Skills.nameRecognitionHowTo5
        ]
        case "luring": return [
            Strings.Training.Skills.luringHowTo1,
            Strings.Training.Skills.luringHowTo2,
            Strings.Training.Skills.luringHowTo3,
            Strings.Training.Skills.luringHowTo4,
            Strings.Training.Skills.luringHowTo5
        ]
        case "handling": return [
            Strings.Training.Skills.handlingHowTo1,
            Strings.Training.Skills.handlingHowTo2,
            Strings.Training.Skills.handlingHowTo3,
            Strings.Training.Skills.handlingHowTo4,
            Strings.Training.Skills.handlingHowTo5
        ]
        case "collarLeash": return [
            Strings.Training.Skills.collarLeashHowTo1,
            Strings.Training.Skills.collarLeashHowTo2,
            Strings.Training.Skills.collarLeashHowTo3,
            Strings.Training.Skills.collarLeashHowTo4,
            Strings.Training.Skills.collarLeashHowTo5
        ]
        case "sit": return [
            Strings.Training.Skills.sitHowTo1,
            Strings.Training.Skills.sitHowTo2,
            Strings.Training.Skills.sitHowTo3,
            Strings.Training.Skills.sitHowTo4,
            Strings.Training.Skills.sitHowTo5
        ]
        case "watchMe": return [
            Strings.Training.Skills.watchMeHowTo1,
            Strings.Training.Skills.watchMeHowTo2,
            Strings.Training.Skills.watchMeHowTo3,
            Strings.Training.Skills.watchMeHowTo4,
            Strings.Training.Skills.watchMeHowTo5
        ]
        case "touch": return [
            Strings.Training.Skills.touchHowTo1,
            Strings.Training.Skills.touchHowTo2,
            Strings.Training.Skills.touchHowTo3,
            Strings.Training.Skills.touchHowTo4,
            Strings.Training.Skills.touchHowTo5
        ]
        case "looseLeash": return [
            Strings.Training.Skills.looseLeashHowTo1,
            Strings.Training.Skills.looseLeashHowTo2,
            Strings.Training.Skills.looseLeashHowTo3,
            Strings.Training.Skills.looseLeashHowTo4,
            Strings.Training.Skills.looseLeashHowTo5
        ]
        case "down": return [
            Strings.Training.Skills.downHowTo1,
            Strings.Training.Skills.downHowTo2,
            Strings.Training.Skills.downHowTo3,
            Strings.Training.Skills.downHowTo4,
            Strings.Training.Skills.downHowTo5
        ]
        case "come": return [
            Strings.Training.Skills.comeHowTo1,
            Strings.Training.Skills.comeHowTo2,
            Strings.Training.Skills.comeHowTo3,
            Strings.Training.Skills.comeHowTo4,
            Strings.Training.Skills.comeHowTo5
        ]
        case "wait": return [
            Strings.Training.Skills.waitHowTo1,
            Strings.Training.Skills.waitHowTo2,
            Strings.Training.Skills.waitHowTo3,
            Strings.Training.Skills.waitHowTo4,
            Strings.Training.Skills.waitHowTo5
        ]
        case "place": return [
            Strings.Training.Skills.placeHowTo1,
            Strings.Training.Skills.placeHowTo2,
            Strings.Training.Skills.placeHowTo3,
            Strings.Training.Skills.placeHowTo4,
            Strings.Training.Skills.placeHowTo5
        ]
        case "stay": return [
            Strings.Training.Skills.stayHowTo1,
            Strings.Training.Skills.stayHowTo2,
            Strings.Training.Skills.stayHowTo3,
            Strings.Training.Skills.stayHowTo4,
            Strings.Training.Skills.stayHowTo5
        ]
        default: return []
        }
    }

    static func tips(for skillId: String) -> [String] {
        switch skillId {
        case "clicker": return [
            Strings.Training.Skills.clickerTip1,
            Strings.Training.Skills.clickerTip2,
            Strings.Training.Skills.clickerTip3,
            Strings.Training.Skills.clickerTip4
        ]
        case "nameRecognition": return [
            Strings.Training.Skills.nameRecognitionTip1,
            Strings.Training.Skills.nameRecognitionTip2,
            Strings.Training.Skills.nameRecognitionTip3,
            Strings.Training.Skills.nameRecognitionTip4
        ]
        case "luring": return [
            Strings.Training.Skills.luringTip1,
            Strings.Training.Skills.luringTip2,
            Strings.Training.Skills.luringTip3,
            Strings.Training.Skills.luringTip4
        ]
        case "handling": return [
            Strings.Training.Skills.handlingTip1,
            Strings.Training.Skills.handlingTip2,
            Strings.Training.Skills.handlingTip3,
            Strings.Training.Skills.handlingTip4
        ]
        case "collarLeash": return [
            Strings.Training.Skills.collarLeashTip1,
            Strings.Training.Skills.collarLeashTip2,
            Strings.Training.Skills.collarLeashTip3,
            Strings.Training.Skills.collarLeashTip4
        ]
        case "sit": return [
            Strings.Training.Skills.sitTip1,
            Strings.Training.Skills.sitTip2,
            Strings.Training.Skills.sitTip3,
            Strings.Training.Skills.sitTip4
        ]
        case "watchMe": return [
            Strings.Training.Skills.watchMeTip1,
            Strings.Training.Skills.watchMeTip2,
            Strings.Training.Skills.watchMeTip3,
            Strings.Training.Skills.watchMeTip4
        ]
        case "touch": return [
            Strings.Training.Skills.touchTip1,
            Strings.Training.Skills.touchTip2,
            Strings.Training.Skills.touchTip3,
            Strings.Training.Skills.touchTip4
        ]
        case "looseLeash": return [
            Strings.Training.Skills.looseLeashTip1,
            Strings.Training.Skills.looseLeashTip2,
            Strings.Training.Skills.looseLeashTip3,
            Strings.Training.Skills.looseLeashTip4
        ]
        case "down": return [
            Strings.Training.Skills.downTip1,
            Strings.Training.Skills.downTip2,
            Strings.Training.Skills.downTip3,
            Strings.Training.Skills.downTip4
        ]
        case "come": return [
            Strings.Training.Skills.comeTip1,
            Strings.Training.Skills.comeTip2,
            Strings.Training.Skills.comeTip3,
            Strings.Training.Skills.comeTip4
        ]
        case "wait": return [
            Strings.Training.Skills.waitTip1,
            Strings.Training.Skills.waitTip2,
            Strings.Training.Skills.waitTip3,
            Strings.Training.Skills.waitTip4
        ]
        case "place": return [
            Strings.Training.Skills.placeTip1,
            Strings.Training.Skills.placeTip2,
            Strings.Training.Skills.placeTip3,
            Strings.Training.Skills.placeTip4
        ]
        case "stay": return [
            Strings.Training.Skills.stayTip1,
            Strings.Training.Skills.stayTip2,
            Strings.Training.Skills.stayTip3,
            Strings.Training.Skills.stayTip4
        ]
        default: return []
        }
    }
}

// MARK: - Week Plan

/// A weekly focus plan for training
struct WeekPlan: Codable, Identifiable {
    let week: Int
    let focusSkillIds: [String]

    var id: Int { week }

    /// Localized title for the week
    var title: String {
        Strings.Training.WeekTitles.title(for: week)
    }

    // Custom coding keys - exclude computed properties
    enum CodingKeys: String, CodingKey {
        case week, focusSkillIds
    }
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
