//
//  TrainingPlan.swift
//  Otis-app
//
//  Training plan data models - skills, categories, and weekly plans
//

import Foundation
import OtisShared
import SwiftUI

// MARK: - Training Method

/// The conditioning approach used to teach a skill
enum TrainingMethod: String, Codable, CaseIterable {
    case operant    // Passive - dog self-discovers behavior (deeper learning)
    case classical  // Active - trainer guides with lure (faster initial learning)

    var label: String {
        switch self {
        case .operant: return Strings.Training.methodOperant
        case .classical: return Strings.Training.methodClassical
        }
    }

    var shortDescription: String {
        switch self {
        case .operant: return Strings.Training.methodOperantShort
        case .classical: return Strings.Training.methodClassicalShort
        }
    }

    var icon: String {
        switch self {
        case .operant: return "brain.head.profile"
        case .classical: return "hand.draw"
        }
    }
}

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
        case .foundations: return .otisInfo
        case .basicCommands: return .otisSuccess
        case .care: return .otisRose
        case .safety: return .otisWarning
        case .impulseControl: return .otisPurple
        }
    }
}

// MARK: - Skill

/// A training skill that can be taught to a puppy
struct Skill: Codable, Identifiable, Hashable {
    let id: String
    let icon: String
    let category: TrainingCategory
    let sortOrder: Int           // Linear order for progression (replaces week/priority)
    let requires: [String]       // Skill IDs that must be mastered first
    let method: TrainingMethod?
    let durationMinutes: Int?
    let sessionsPerDay: Int?
    let steps: [SkillStep]?      // Ordered steps with rule gates
    let phases: [SkillPhase]?    // Learning phases for progressive disclosure

    // Localized content - looked up by skill ID
    var name: String { SkillContent.name(for: id) }
    var description: String { SkillContent.description(for: id) }
    var howTo: [String] { SkillContent.howTo(for: id) }
    var doneWhen: String { SkillContent.doneWhen(for: id) }
    var tips: [String] { SkillContent.tips(for: id) }
    var mistakes: [String] { SkillContent.mistakes(for: id) }

    /// Formatted session recommendation string (e.g., "2-3 min, 3x daily")
    var sessionRecommendation: String? {
        guard let duration = durationMinutes, let sessions = sessionsPerDay else { return nil }
        return Strings.Training.sessionRecommendation(minutes: duration, timesPerDay: sessions)
    }

    /// Get effective phases - returns defined phases or a single fallback phase with all steps
    var effectivePhases: [SkillPhase] {
        if let phases = phases, !phases.isEmpty { return phases }
        // Fallback: single phase with all steps
        return [SkillPhase(id: "all", howToStepIndices: Array(0..<howTo.count), tipIndices: nil)]
    }

    /// Whether this skill has multiple learning phases defined
    var hasMultiplePhases: Bool {
        guard let phases = phases else { return false }
        return phases.count > 1
    }

    /// Whether this skill uses the clicker during training sessions
    /// - Clicker skill itself: yes (practicing the clicker)
    /// - Operant/classical method skills: yes (marking behavior)
    /// - No-method skills (handling, collarLeash): no
    var usesClicker: Bool {
        id == "clicker" || method != nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Skill, rhs: Skill) -> Bool {
        lhs.id == rhs.id
    }

    // Custom coding keys - exclude computed properties
    enum CodingKeys: String, CodingKey {
        case id, icon, category, sortOrder, requires, method, durationMinutes, sessionsPerDay, steps, phases
    }
}

// MARK: - Skill Content Lookup

/// Metadata container for all localized content related to a skill
private struct SkillMetadata {
    let name: String
    let description: String
    let doneWhen: String
    let howTo: [String]
    let tips: [String]
    let mistakes: [String]
}

/// Static lookup for localized skill content using dictionary for O(1) access
enum SkillContent {
    // Single source of truth: one entry per skill with all content
    private static let metadata: [String: SkillMetadata] = [
        "clicker": SkillMetadata(
            name: Strings.Training.Skills.clickerName,
            description: Strings.Training.Skills.clickerDescription,
            doneWhen: Strings.Training.Skills.clickerDoneWhen,
            howTo: [
                Strings.Training.Skills.clickerHowTo1,
                Strings.Training.Skills.clickerHowTo2,
                Strings.Training.Skills.clickerHowTo3,
                Strings.Training.Skills.clickerHowTo4,
                Strings.Training.Skills.clickerHowTo5
            ],
            tips: [
                Strings.Training.Skills.clickerTip1,
                Strings.Training.Skills.clickerTip2,
                Strings.Training.Skills.clickerTip3,
                Strings.Training.Skills.clickerTip4
            ],
            mistakes: [
                Strings.Training.Skills.clickerMistake1,
                Strings.Training.Skills.clickerMistake2,
                Strings.Training.Skills.clickerMistake3
            ]
        ),
        "nameRecognition": SkillMetadata(
            name: Strings.Training.Skills.nameRecognitionName,
            description: Strings.Training.Skills.nameRecognitionDescription,
            doneWhen: Strings.Training.Skills.nameRecognitionDoneWhen,
            howTo: [
                Strings.Training.Skills.nameRecognitionHowTo1,
                Strings.Training.Skills.nameRecognitionHowTo2,
                Strings.Training.Skills.nameRecognitionHowTo3,
                Strings.Training.Skills.nameRecognitionHowTo4,
                Strings.Training.Skills.nameRecognitionHowTo5
            ],
            tips: [
                Strings.Training.Skills.nameRecognitionTip1,
                Strings.Training.Skills.nameRecognitionTip2,
                Strings.Training.Skills.nameRecognitionTip3,
                Strings.Training.Skills.nameRecognitionTip4
            ],
            mistakes: []
        ),
        "luring": SkillMetadata(
            name: Strings.Training.Skills.luringName,
            description: Strings.Training.Skills.luringDescription,
            doneWhen: Strings.Training.Skills.luringDoneWhen,
            howTo: [
                Strings.Training.Skills.luringHowTo1,
                Strings.Training.Skills.luringHowTo2,
                Strings.Training.Skills.luringHowTo3,
                Strings.Training.Skills.luringHowTo4,
                Strings.Training.Skills.luringHowTo5
            ],
            tips: [
                Strings.Training.Skills.luringTip1,
                Strings.Training.Skills.luringTip2,
                Strings.Training.Skills.luringTip3,
                Strings.Training.Skills.luringTip4
            ],
            mistakes: [
                Strings.Training.Skills.luringMistake1,
                Strings.Training.Skills.luringMistake2
            ]
        ),
        "handling": SkillMetadata(
            name: Strings.Training.Skills.handlingName,
            description: Strings.Training.Skills.handlingDescription,
            doneWhen: Strings.Training.Skills.handlingDoneWhen,
            howTo: [
                Strings.Training.Skills.handlingHowTo1,
                Strings.Training.Skills.handlingHowTo2,
                Strings.Training.Skills.handlingHowTo3,
                Strings.Training.Skills.handlingHowTo4,
                Strings.Training.Skills.handlingHowTo5
            ],
            tips: [
                Strings.Training.Skills.handlingTip1,
                Strings.Training.Skills.handlingTip2,
                Strings.Training.Skills.handlingTip3,
                Strings.Training.Skills.handlingTip4
            ],
            mistakes: []
        ),
        "collarLeash": SkillMetadata(
            name: Strings.Training.Skills.collarLeashName,
            description: Strings.Training.Skills.collarLeashDescription,
            doneWhen: Strings.Training.Skills.collarLeashDoneWhen,
            howTo: [
                Strings.Training.Skills.collarLeashHowTo1,
                Strings.Training.Skills.collarLeashHowTo2,
                Strings.Training.Skills.collarLeashHowTo3,
                Strings.Training.Skills.collarLeashHowTo4,
                Strings.Training.Skills.collarLeashHowTo5
            ],
            tips: [
                Strings.Training.Skills.collarLeashTip1,
                Strings.Training.Skills.collarLeashTip2,
                Strings.Training.Skills.collarLeashTip3,
                Strings.Training.Skills.collarLeashTip4
            ],
            mistakes: []
        ),
        "sit": SkillMetadata(
            name: Strings.Training.Skills.sitName,
            description: Strings.Training.Skills.sitDescription,
            doneWhen: Strings.Training.Skills.sitDoneWhen,
            howTo: [
                Strings.Training.Skills.sitHowTo1,
                Strings.Training.Skills.sitHowTo2,
                Strings.Training.Skills.sitHowTo3,
                Strings.Training.Skills.sitHowTo4,
                Strings.Training.Skills.sitHowTo5,
                Strings.Training.Skills.sitHowTo6,
                Strings.Training.Skills.sitHowTo7,
                Strings.Training.Skills.sitHowTo8,
                Strings.Training.Skills.sitHowTo9,
                Strings.Training.Skills.sitHowTo10,
                Strings.Training.Skills.sitHowTo11
            ],
            tips: [
                Strings.Training.Skills.sitTip1,
                Strings.Training.Skills.sitTip2,
                Strings.Training.Skills.sitTip3,
                Strings.Training.Skills.sitTip4,
                Strings.Training.Skills.sitTip5,
                Strings.Training.Skills.sitTip6
            ],
            mistakes: [
                Strings.Training.Skills.sitMistake1,
                Strings.Training.Skills.sitMistake2,
                Strings.Training.Skills.sitMistake3,
                Strings.Training.Skills.sitMistake4
            ]
        ),
        "watchMe": SkillMetadata(
            name: Strings.Training.Skills.watchMeName,
            description: Strings.Training.Skills.watchMeDescription,
            doneWhen: Strings.Training.Skills.watchMeDoneWhen,
            howTo: [
                Strings.Training.Skills.watchMeHowTo1,
                Strings.Training.Skills.watchMeHowTo2,
                Strings.Training.Skills.watchMeHowTo3,
                Strings.Training.Skills.watchMeHowTo4,
                Strings.Training.Skills.watchMeHowTo5,
                Strings.Training.Skills.watchMeHowTo6,
                Strings.Training.Skills.watchMeHowTo7,
                Strings.Training.Skills.watchMeHowTo8,
                Strings.Training.Skills.watchMeHowTo9,
                Strings.Training.Skills.watchMeHowTo10
            ],
            tips: [
                Strings.Training.Skills.watchMeTip1,
                Strings.Training.Skills.watchMeTip2,
                Strings.Training.Skills.watchMeTip3,
                Strings.Training.Skills.watchMeTip4
            ],
            mistakes: [
                Strings.Training.Skills.watchMeMistake1,
                Strings.Training.Skills.watchMeMistake2,
                Strings.Training.Skills.watchMeMistake3
            ]
        ),
        "touch": SkillMetadata(
            name: Strings.Training.Skills.touchName,
            description: Strings.Training.Skills.touchDescription,
            doneWhen: Strings.Training.Skills.touchDoneWhen,
            howTo: [
                Strings.Training.Skills.touchHowTo1,
                Strings.Training.Skills.touchHowTo2,
                Strings.Training.Skills.touchHowTo3,
                Strings.Training.Skills.touchHowTo4,
                Strings.Training.Skills.touchHowTo5
            ],
            tips: [
                Strings.Training.Skills.touchTip1,
                Strings.Training.Skills.touchTip2,
                Strings.Training.Skills.touchTip3,
                Strings.Training.Skills.touchTip4
            ],
            mistakes: []
        ),
        "looseLeash": SkillMetadata(
            name: Strings.Training.Skills.looseLeashName,
            description: Strings.Training.Skills.looseLeashDescription,
            doneWhen: Strings.Training.Skills.looseLeashDoneWhen,
            howTo: [
                Strings.Training.Skills.looseLeashHowTo1,
                Strings.Training.Skills.looseLeashHowTo2,
                Strings.Training.Skills.looseLeashHowTo3,
                Strings.Training.Skills.looseLeashHowTo4,
                Strings.Training.Skills.looseLeashHowTo5,
                Strings.Training.Skills.looseLeashHowTo6,
                Strings.Training.Skills.looseLeashHowTo7,
                Strings.Training.Skills.looseLeashHowTo8,
                Strings.Training.Skills.looseLeashHowTo9,
                Strings.Training.Skills.looseLeashHowTo10
            ],
            tips: [
                Strings.Training.Skills.looseLeashTip1,
                Strings.Training.Skills.looseLeashTip2,
                Strings.Training.Skills.looseLeashTip3,
                Strings.Training.Skills.looseLeashTip4
            ],
            mistakes: [
                Strings.Training.Skills.looseLeashMistake1,
                Strings.Training.Skills.looseLeashMistake2
            ]
        ),
        "down": SkillMetadata(
            name: Strings.Training.Skills.downName,
            description: Strings.Training.Skills.downDescription,
            doneWhen: Strings.Training.Skills.downDoneWhen,
            howTo: [
                Strings.Training.Skills.downHowTo1,
                Strings.Training.Skills.downHowTo2,
                Strings.Training.Skills.downHowTo3,
                Strings.Training.Skills.downHowTo4,
                Strings.Training.Skills.downHowTo5
            ],
            tips: [
                Strings.Training.Skills.downTip1,
                Strings.Training.Skills.downTip2,
                Strings.Training.Skills.downTip3,
                Strings.Training.Skills.downTip4
            ],
            mistakes: [
                Strings.Training.Skills.downMistake1,
                Strings.Training.Skills.downMistake2,
                Strings.Training.Skills.downMistake3
            ]
        ),
        "come": SkillMetadata(
            name: Strings.Training.Skills.comeName,
            description: Strings.Training.Skills.comeDescription,
            doneWhen: Strings.Training.Skills.comeDoneWhen,
            howTo: [
                Strings.Training.Skills.comeHowTo1,
                Strings.Training.Skills.comeHowTo2,
                Strings.Training.Skills.comeHowTo3,
                Strings.Training.Skills.comeHowTo4,
                Strings.Training.Skills.comeHowTo5,
                Strings.Training.Skills.comeHowTo6,
                Strings.Training.Skills.comeHowTo7,
                Strings.Training.Skills.comeHowTo8,
                Strings.Training.Skills.comeHowTo9,
                Strings.Training.Skills.comeHowTo10,
                Strings.Training.Skills.comeHowTo11,
                Strings.Training.Skills.comeHowTo12
            ],
            tips: [
                Strings.Training.Skills.comeTip1,
                Strings.Training.Skills.comeTip2,
                Strings.Training.Skills.comeTip3,
                Strings.Training.Skills.comeTip4,
                Strings.Training.Skills.comeTip5,
                Strings.Training.Skills.comeTip6
            ],
            mistakes: [
                Strings.Training.Skills.comeMistake1,
                Strings.Training.Skills.comeMistake2,
                Strings.Training.Skills.comeMistake3,
                Strings.Training.Skills.comeMistake4
            ]
        ),
        "wait": SkillMetadata(
            name: Strings.Training.Skills.waitName,
            description: Strings.Training.Skills.waitDescription,
            doneWhen: Strings.Training.Skills.waitDoneWhen,
            howTo: [
                Strings.Training.Skills.waitHowTo1,
                Strings.Training.Skills.waitHowTo2,
                Strings.Training.Skills.waitHowTo3,
                Strings.Training.Skills.waitHowTo4,
                Strings.Training.Skills.waitHowTo5
            ],
            tips: [
                Strings.Training.Skills.waitTip1,
                Strings.Training.Skills.waitTip2,
                Strings.Training.Skills.waitTip3,
                Strings.Training.Skills.waitTip4
            ],
            mistakes: []
        ),
        "place": SkillMetadata(
            name: Strings.Training.Skills.placeName,
            description: Strings.Training.Skills.placeDescription,
            doneWhen: Strings.Training.Skills.placeDoneWhen,
            howTo: [
                Strings.Training.Skills.placeHowTo1,
                Strings.Training.Skills.placeHowTo2,
                Strings.Training.Skills.placeHowTo3,
                Strings.Training.Skills.placeHowTo4,
                Strings.Training.Skills.placeHowTo5
            ],
            tips: [
                Strings.Training.Skills.placeTip1,
                Strings.Training.Skills.placeTip2,
                Strings.Training.Skills.placeTip3,
                Strings.Training.Skills.placeTip4
            ],
            mistakes: []
        ),
        "stay": SkillMetadata(
            name: Strings.Training.Skills.stayName,
            description: Strings.Training.Skills.stayDescription,
            doneWhen: Strings.Training.Skills.stayDoneWhen,
            howTo: [
                Strings.Training.Skills.stayHowTo1,
                Strings.Training.Skills.stayHowTo2,
                Strings.Training.Skills.stayHowTo3,
                Strings.Training.Skills.stayHowTo4,
                Strings.Training.Skills.stayHowTo5
            ],
            tips: [
                Strings.Training.Skills.stayTip1,
                Strings.Training.Skills.stayTip2,
                Strings.Training.Skills.stayTip3,
                Strings.Training.Skills.stayTip4
            ],
            mistakes: []
        )
    ]

    // MARK: - Public API (unchanged interface)

    static func name(for skillId: String) -> String {
        metadata[skillId]?.name ?? skillId
    }

    static func description(for skillId: String) -> String {
        metadata[skillId]?.description ?? ""
    }

    static func doneWhen(for skillId: String) -> String {
        metadata[skillId]?.doneWhen ?? ""
    }

    static func howTo(for skillId: String) -> [String] {
        metadata[skillId]?.howTo ?? []
    }

    static func tips(for skillId: String) -> [String] {
        metadata[skillId]?.tips ?? []
    }

    static func mistakes(for skillId: String) -> [String] {
        metadata[skillId]?.mistakes ?? []
    }
}

// MARK: - Training Plan

/// The complete training plan with all skills, preparation items, and rules
struct TrainingPlan: Codable {
    let skills: [Skill]
    let preparationItems: [PreparationItem]
    let rules: [TrainingRule]

    /// Get a skill by its ID
    func skill(withId id: String) -> Skill? {
        skills.first { $0.id == id }
    }

    /// Get all skills for a specific category
    func skills(for category: TrainingCategory) -> [Skill] {
        skills.filter { $0.category == category }
    }

    /// Get all skills sorted by their linear order
    var allSkillsOrdered: [Skill] {
        skills.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Get a rule by its ID
    func rule(withId id: String) -> TrainingRule? {
        rules.first { $0.id == id }
    }

    /// Get a preparation item by its ID
    func preparationItem(withId id: String) -> PreparationItem? {
        preparationItems.first { $0.id == id }
    }

    /// Get all equipment items
    var equipmentItems: [PreparationItem] {
        preparationItems.filter { $0.type == .equipment }
    }

    /// Get all concept items
    var conceptItems: [PreparationItem] {
        preparationItems.filter { $0.type == .concept }
    }

    /// Get rules triggered by a specific step
    func rules(triggeredByStep stepId: String) -> [TrainingRule] {
        rules.filter { $0.triggeredByStep == stepId }
    }

    /// Check if all requirements are met for a skill (based on mastery)
    func requirementsMet(for skillId: String, masteredSkillIds: Set<String>) -> Bool {
        guard let skill = skill(withId: skillId) else { return false }
        return skill.requires.allSatisfy { masteredSkillIds.contains($0) }
    }

    /// Get the skill IDs that are missing (requirements not mastered)
    func missingRequirements(for skillId: String, masteredSkillIds: Set<String>) -> [Skill] {
        guard let skill = skill(withId: skillId) else { return [] }
        return skill.requires
            .filter { !masteredSkillIds.contains($0) }
            .compactMap { self.skill(withId: $0) }
    }
}
