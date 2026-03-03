//
//  TrainingModels.swift
//  Otis-app
//
//  New training models for preparation phase, rules, and skill steps
//

import Foundation

// MARK: - Preparation Type

/// Type of preparation item
enum PreparationType: String, Codable, CaseIterable {
    case equipment  // Physical items (clicker, treats, leash)
    case concept    // Understanding items (operant vs classical, timing)
}

// MARK: - Preparation Item

/// A preparation item that must be completed before training unlocks
struct PreparationItem: Identifiable, Codable, Hashable {
    let id: String
    let type: PreparationType

    /// Localized name for the preparation item
    var name: String {
        PreparationItemContent.name(for: id)
    }

    /// Optional explanation text for concept items
    var explanation: String? {
        PreparationItemContent.explanation(for: id)
    }
}

// MARK: - Training Rule

/// A training rule introduced at a specific moment during skill training
struct TrainingRule: Identifiable, Codable, Hashable {
    let id: String
    let triggeredByStep: String?  // Step ID that triggers this rule (e.g., "clicker.understand"), nil = preparation phase

    /// Localized title for the rule
    var title: String {
        TrainingRuleContent.title(for: id)
    }

    /// Localized description for the rule
    var ruleDescription: String {
        TrainingRuleContent.description(for: id)
    }
}

// MARK: - Skill Step

/// A step within a skill that may require acknowledging a rule
struct SkillStep: Identifiable, Codable, Hashable {
    let id: String
    let prerequisiteRuleId: String?  // Rule to acknowledge before this step

    /// Combined ID for use in rule triggering (e.g., "clicker.understand")
    func fullId(skillId: String) -> String {
        "\(skillId).\(id)"
    }
}

// MARK: - Content Lookups

/// Static lookup for preparation item content
enum PreparationItemContent {
    static func name(for itemId: String) -> String {
        switch itemId {
        // Equipment
        case "clicker": return Strings.Training.Preparation.clicker
        case "treats": return Strings.Training.Preparation.treats
        case "quietSpace": return Strings.Training.Preparation.quietSpace
        // Concepts
        case "understandOperant": return Strings.Training.Preparation.understandOperant
        case "understandClassical": return Strings.Training.Preparation.understandClassical
        case "understandTiming": return Strings.Training.Preparation.understandTiming
        default: return itemId
        }
    }

    static func explanation(for itemId: String) -> String? {
        switch itemId {
        case "understandOperant": return Strings.Training.Preparation.operantExplanation
        case "understandClassical": return Strings.Training.Preparation.classicalExplanation
        case "understandTiming": return Strings.Training.Preparation.timingExplanation
        default: return nil
        }
    }
}

/// Static lookup for training rule content
enum TrainingRuleContent {
    static func title(for ruleId: String) -> String {
        switch ruleId {
        case "neverClickWithoutReward": return Strings.Training.Rules.neverClickWithoutRewardTitle
        case "wordMustMatchMoment": return Strings.Training.Rules.wordMustMatchMomentTitle
        case "clickEndsExercise": return Strings.Training.Rules.clickEndsExerciseTitle
        case "stepBackIfStruggling": return Strings.Training.Rules.stepBackIfStrugglingTitle
        default: return ruleId
        }
    }

    static func description(for ruleId: String) -> String {
        switch ruleId {
        case "neverClickWithoutReward": return Strings.Training.Rules.neverClickWithoutRewardDescription
        case "wordMustMatchMoment": return Strings.Training.Rules.wordMustMatchMomentDescription
        case "clickEndsExercise": return Strings.Training.Rules.clickEndsExerciseDescription
        case "stepBackIfStruggling": return Strings.Training.Rules.stepBackIfStrugglingDescription
        default: return ""
        }
    }
}

// MARK: - Skill Phase

/// A learning phase that groups howTo steps into logical stages for progressive disclosure
struct SkillPhase: Codable, Identifiable, Hashable {
    let id: String                    // e.g., "introduction"
    let howToStepIndices: [Int]       // Which howTo steps (0-indexed)
    let tipIndices: [Int]?            // Which tips (optional)

    /// Get the localized name for this phase
    func name(for skillId: String) -> String {
        SkillPhaseContent.name(skillId: skillId, phaseId: id)
    }

    /// Get the localized subtitle for this phase
    func subtitle(for skillId: String) -> String {
        SkillPhaseContent.subtitle(skillId: skillId, phaseId: id)
    }
}

/// Static lookup for skill phase content
enum SkillPhaseContent {
    static func name(skillId: String, phaseId: String) -> String {
        let key = "\(skillId).\(phaseId)"
        switch key {
        // Collar & Leash phases
        case "collarLeash.introduction": return Strings.Training.Phases.collarLeashIntroductionName
        case "collarLeash.buildDuration": return Strings.Training.Phases.collarLeashBuildDurationName
        case "collarLeash.leashWork": return Strings.Training.Phases.collarLeashLeashWorkName
        // Watch Me phases
        case "watchMe.captureAttention": return Strings.Training.Phases.watchMeCaptureAttentionName
        case "watchMe.positionProgression": return Strings.Training.Phases.watchMePositionProgressionName
        case "watchMe.addCue": return Strings.Training.Phases.watchMeAddCueName
        case "watchMe.proof": return Strings.Training.Phases.watchMeProofName
        // Loose Leash Walking phases
        case "looseLeash.capturePosition": return Strings.Training.Phases.looseLeashCapturePositionName
        case "looseLeash.buildDuration": return Strings.Training.Phases.looseLeashBuildDurationName
        case "looseLeash.addCue": return Strings.Training.Phases.looseLeashAddCueName
        case "looseLeash.proofEnvironments": return Strings.Training.Phases.looseLeashProofEnvironmentsName
        // Come (Recall) phases
        case "come.foundation": return Strings.Training.Phases.comeFoundationName
        case "come.frontPosition": return Strings.Training.Phases.comeFrontPositionName
        case "come.buildDistance": return Strings.Training.Phases.comeBuildDistanceName
        case "come.proofDistractions": return Strings.Training.Phases.comeProofDistractionsName
        // Sit phases
        case "sit.lureToPosition": return Strings.Training.Phases.sitLureToPositionName
        case "sit.captureAndStrengthen": return Strings.Training.Phases.sitCaptureAndStrengthenName
        case "sit.addVerbalCue": return Strings.Training.Phases.sitAddVerbalCueName
        case "sit.proofThreeDs": return Strings.Training.Phases.sitProofThreeDsName
        // Fallback for single-phase skills
        case _ where phaseId == "all": return Strings.Training.Phases.allSteps
        default: return phaseId.capitalized
        }
    }

    static func subtitle(skillId: String, phaseId: String) -> String {
        let key = "\(skillId).\(phaseId)"
        switch key {
        // Collar & Leash phases
        case "collarLeash.introduction": return Strings.Training.Phases.collarLeashIntroductionSubtitle
        case "collarLeash.buildDuration": return Strings.Training.Phases.collarLeashBuildDurationSubtitle
        case "collarLeash.leashWork": return Strings.Training.Phases.collarLeashLeashWorkSubtitle
        // Watch Me phases
        case "watchMe.captureAttention": return Strings.Training.Phases.watchMeCaptureAttentionSubtitle
        case "watchMe.positionProgression": return Strings.Training.Phases.watchMePositionProgressionSubtitle
        case "watchMe.addCue": return Strings.Training.Phases.watchMeAddCueSubtitle
        case "watchMe.proof": return Strings.Training.Phases.watchMeProofSubtitle
        // Loose Leash Walking phases
        case "looseLeash.capturePosition": return Strings.Training.Phases.looseLeashCapturePositionSubtitle
        case "looseLeash.buildDuration": return Strings.Training.Phases.looseLeashBuildDurationSubtitle
        case "looseLeash.addCue": return Strings.Training.Phases.looseLeashAddCueSubtitle
        case "looseLeash.proofEnvironments": return Strings.Training.Phases.looseLeashProofEnvironmentsSubtitle
        // Come (Recall) phases
        case "come.foundation": return Strings.Training.Phases.comeFoundationSubtitle
        case "come.frontPosition": return Strings.Training.Phases.comeFrontPositionSubtitle
        case "come.buildDistance": return Strings.Training.Phases.comeBuildDistanceSubtitle
        case "come.proofDistractions": return Strings.Training.Phases.comeProofDistractionsSubtitle
        // Sit phases
        case "sit.lureToPosition": return Strings.Training.Phases.sitLureToPositionSubtitle
        case "sit.captureAndStrengthen": return Strings.Training.Phases.sitCaptureAndStrengthenSubtitle
        case "sit.addVerbalCue": return Strings.Training.Phases.sitAddVerbalCueSubtitle
        case "sit.proofThreeDs": return Strings.Training.Phases.sitProofThreeDsSubtitle
        default: return ""
        }
    }
}
