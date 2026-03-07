//
//  AIContext+Core.swift
//  Ollie-app
//
//  Core AI context components: Dog Identity and Household
//

import Foundation
import OtisShared

// MARK: - Dog Identity Context

/// Core identity information about the dog (always included).
/// Uses pseudonymized name for privacy.
struct DogIdentityContext: AIContextComponent {
    static let componentKey = "dog_identity"
    static let estimatedTokens = 80

    /// Pseudonymized identifier (first letter + last letter of name)
    let pseudonym: String

    /// Age in weeks
    let ageWeeks: Int

    /// Age in months (for easier LLM interpretation)
    let ageMonths: Int

    /// Days since coming home (attachment/adjustment context)
    let daysHome: Int

    /// Size category affects exercise limits, feeding, etc.
    let sizeCategory: String

    /// Breed group for breed-specific considerations (nil if unknown)
    let breedGroup: String?

    /// Lifecycle phase for app personality/terminology (puppy, teenage, adult, senior)
    let lifecyclePhase: String

    /// Whether to use "puppy" or "dog" in responses.
    let usesPuppyTerminology: Bool

    /// Life stage for fine-grained age-appropriate recommendations
    let lifeStage: String

    /// Pronouns to use when referring to this dog.
    let pronouns: PronounSet

    /// Pronoun set for referring to the dog
    struct PronounSet: Codable, Sendable {
        let subject: String
        let object: String
        let possessive: String
        let reflexive: String
    }

    init(profile: PuppyProfile) {
        // Pseudonymize: first + last letter (e.g., "Luna" -> "La")
        let name = profile.name.trimmingCharacters(in: .whitespaces)
        let first = name.first.map(String.init) ?? "X"
        let last = name.last.map(String.init) ?? "X"
        self.pseudonym = "\(first)\(last)"

        self.ageWeeks = profile.ageInWeeks
        self.ageMonths = profile.ageInMonths
        self.daysHome = profile.daysHome
        self.sizeCategory = profile.sizeCategory.rawValue
        self.breedGroup = profile.breed

        self.lifecyclePhase = profile.lifecyclePhase.rawValue
        self.usesPuppyTerminology = profile.lifecyclePhase.usesPuppyTerminology

        // Determine fine-grained life stage
        if profile.ageInWeeks < 8 {
            self.lifeStage = "neonatal"
        } else if profile.ageInWeeks < 12 {
            self.lifeStage = "early_puppy"
        } else if profile.ageInWeeks < 24 {
            self.lifeStage = "puppy"
        } else if profile.ageInMonths < 12 {
            self.lifeStage = "adolescent"
        } else if profile.ageInMonths < 18 {
            self.lifeStage = "young_adult"
        } else if profile.lifecyclePhase == .senior {
            self.lifeStage = "senior"
        } else {
            self.lifeStage = "adult"
        }

        self.pronouns = PronounSet(
            subject: profile.gender.subjectPronoun,
            object: profile.gender.objectPronoun,
            possessive: profile.gender.possessivePronoun,
            reflexive: profile.gender.reflexivePronoun
        )
    }
}

// MARK: - Household Context

/// Information about household members involved in puppy care.
struct HouseholdContext: AIContextComponent {
    static let componentKey = "household"
    static let estimatedTokens = 30

    /// Number of household members involved
    let memberCount: Int

    /// Pseudonymized member roles
    let memberRoles: [String: String]

    init(profile: PuppyProfile) {
        let members = profile.householdMembers.members
        self.memberCount = members.count

        var roles: [String: String] = [:]
        for (index, member) in members.enumerated() {
            let key = "M\(index + 1)"
            roles[key] = member.isCurrentUser ? "primary" : "member"
        }
        self.memberRoles = roles
    }
}
