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

/// Metadata for preparation items (name + optional explanation)
private struct PreparationMetadata {
    let name: String
    let explanation: String?
}

/// Static lookup for preparation item content using dictionary
enum PreparationItemContent {
    private static let metadata: [String: PreparationMetadata] = [
        // Equipment
        "clicker": PreparationMetadata(name: Strings.Training.Preparation.clicker, explanation: nil),
        "treats": PreparationMetadata(name: Strings.Training.Preparation.treats, explanation: nil),
        "quietSpace": PreparationMetadata(name: Strings.Training.Preparation.quietSpace, explanation: nil),
        // Concepts
        "understandOperant": PreparationMetadata(
            name: Strings.Training.Preparation.understandOperant,
            explanation: Strings.Training.Preparation.operantExplanation
        ),
        "understandClassical": PreparationMetadata(
            name: Strings.Training.Preparation.understandClassical,
            explanation: Strings.Training.Preparation.classicalExplanation
        ),
        "understandTiming": PreparationMetadata(
            name: Strings.Training.Preparation.understandTiming,
            explanation: Strings.Training.Preparation.timingExplanation
        )
    ]

    static func name(for itemId: String) -> String {
        metadata[itemId]?.name ?? itemId
    }

    static func explanation(for itemId: String) -> String? {
        metadata[itemId]?.explanation
    }
}

/// Metadata for training rules (title + description)
private struct RuleMetadata {
    let title: String
    let description: String
}

/// Static lookup for training rule content using dictionary
enum TrainingRuleContent {
    private static let metadata: [String: RuleMetadata] = [
        "neverClickWithoutReward": RuleMetadata(
            title: Strings.Training.Rules.neverClickWithoutRewardTitle,
            description: Strings.Training.Rules.neverClickWithoutRewardDescription
        ),
        "wordMustMatchMoment": RuleMetadata(
            title: Strings.Training.Rules.wordMustMatchMomentTitle,
            description: Strings.Training.Rules.wordMustMatchMomentDescription
        ),
        "clickEndsExercise": RuleMetadata(
            title: Strings.Training.Rules.clickEndsExerciseTitle,
            description: Strings.Training.Rules.clickEndsExerciseDescription
        ),
        "stepBackIfStruggling": RuleMetadata(
            title: Strings.Training.Rules.stepBackIfStrugglingTitle,
            description: Strings.Training.Rules.stepBackIfStrugglingDescription
        )
    ]

    static func title(for ruleId: String) -> String {
        metadata[ruleId]?.title ?? ruleId
    }

    static func description(for ruleId: String) -> String {
        metadata[ruleId]?.description ?? ""
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

/// Metadata for skill phases (name + subtitle)
private struct PhaseMetadata {
    let name: String
    let subtitle: String
}

/// Static lookup for skill phase content using dictionary
enum SkillPhaseContent {
    private static let metadata: [String: PhaseMetadata] = [
        // Collar & Leash phases
        "collarLeash.introduction": PhaseMetadata(
            name: Strings.Training.Phases.collarLeashIntroductionName,
            subtitle: Strings.Training.Phases.collarLeashIntroductionSubtitle
        ),
        "collarLeash.buildDuration": PhaseMetadata(
            name: Strings.Training.Phases.collarLeashBuildDurationName,
            subtitle: Strings.Training.Phases.collarLeashBuildDurationSubtitle
        ),
        "collarLeash.leashWork": PhaseMetadata(
            name: Strings.Training.Phases.collarLeashLeashWorkName,
            subtitle: Strings.Training.Phases.collarLeashLeashWorkSubtitle
        ),
        // Watch Me phases
        "watchMe.captureAttention": PhaseMetadata(
            name: Strings.Training.Phases.watchMeCaptureAttentionName,
            subtitle: Strings.Training.Phases.watchMeCaptureAttentionSubtitle
        ),
        "watchMe.positionProgression": PhaseMetadata(
            name: Strings.Training.Phases.watchMePositionProgressionName,
            subtitle: Strings.Training.Phases.watchMePositionProgressionSubtitle
        ),
        "watchMe.addCue": PhaseMetadata(
            name: Strings.Training.Phases.watchMeAddCueName,
            subtitle: Strings.Training.Phases.watchMeAddCueSubtitle
        ),
        "watchMe.proof": PhaseMetadata(
            name: Strings.Training.Phases.watchMeProofName,
            subtitle: Strings.Training.Phases.watchMeProofSubtitle
        ),
        // Loose Leash Walking phases
        "looseLeash.capturePosition": PhaseMetadata(
            name: Strings.Training.Phases.looseLeashCapturePositionName,
            subtitle: Strings.Training.Phases.looseLeashCapturePositionSubtitle
        ),
        "looseLeash.buildDuration": PhaseMetadata(
            name: Strings.Training.Phases.looseLeashBuildDurationName,
            subtitle: Strings.Training.Phases.looseLeashBuildDurationSubtitle
        ),
        "looseLeash.addCue": PhaseMetadata(
            name: Strings.Training.Phases.looseLeashAddCueName,
            subtitle: Strings.Training.Phases.looseLeashAddCueSubtitle
        ),
        "looseLeash.proofEnvironments": PhaseMetadata(
            name: Strings.Training.Phases.looseLeashProofEnvironmentsName,
            subtitle: Strings.Training.Phases.looseLeashProofEnvironmentsSubtitle
        ),
        // Come (Magic Recall) phases
        "come.chooseMagicWord": PhaseMetadata(
            name: Strings.Training.Phases.comeChooseMagicWordName,
            subtitle: Strings.Training.Phases.comeChooseMagicWordSubtitle
        ),
        "come.buildAssociation": PhaseMetadata(
            name: Strings.Training.Phases.comeBuildAssociationName,
            subtitle: Strings.Training.Phases.comeBuildAssociationSubtitle
        ),
        "come.partnerExercise": PhaseMetadata(
            name: Strings.Training.Phases.comePartnerExerciseName,
            subtitle: Strings.Training.Phases.comePartnerExerciseSubtitle
        ),
        "come.proofAndProgress": PhaseMetadata(
            name: Strings.Training.Phases.comeProofAndProgressName,
            subtitle: Strings.Training.Phases.comeProofAndProgressSubtitle
        ),
        // Sit phases
        "sit.lureToPosition": PhaseMetadata(
            name: Strings.Training.Phases.sitLureToPositionName,
            subtitle: Strings.Training.Phases.sitLureToPositionSubtitle
        ),
        "sit.captureAndStrengthen": PhaseMetadata(
            name: Strings.Training.Phases.sitCaptureAndStrengthenName,
            subtitle: Strings.Training.Phases.sitCaptureAndStrengthenSubtitle
        ),
        "sit.addVerbalCue": PhaseMetadata(
            name: Strings.Training.Phases.sitAddVerbalCueName,
            subtitle: Strings.Training.Phases.sitAddVerbalCueSubtitle
        ),
        "sit.proofThreeDs": PhaseMetadata(
            name: Strings.Training.Phases.sitProofThreeDsName,
            subtitle: Strings.Training.Phases.sitProofThreeDsSubtitle
        )
    ]

    static func name(skillId: String, phaseId: String) -> String {
        // Fallback for single-phase skills
        if phaseId == "all" { return Strings.Training.Phases.allSteps }
        let key = "\(skillId).\(phaseId)"
        return metadata[key]?.name ?? phaseId.capitalized
    }

    static func subtitle(skillId: String, phaseId: String) -> String {
        let key = "\(skillId).\(phaseId)"
        return metadata[key]?.subtitle ?? ""
    }
}
