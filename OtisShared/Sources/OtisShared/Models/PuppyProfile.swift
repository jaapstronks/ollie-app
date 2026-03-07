//
//  PuppyProfile.swift
//  OtisShared
//

import Foundation

/// Ownership type for multi-puppy support
/// - owned: Profile created by this user, stored in private CloudKit store
/// - shared: Profile received via share invitation, stored in shared CloudKit store
public enum ProfileOwnership: String, Codable, Sendable {
    case owned
    case shared
}

/// Lifecycle phase of a dog - determines UI terminology and feature emphasis
/// - puppy: 0-12 months - intensive care, potty training, socialization
/// - teenage: 8-18 months - training consolidation, behavior challenges
/// - adult: 18 months to senior threshold - maintenance mode
/// - senior: 7+ years (varies by size) - health monitoring focus
public enum LifecyclePhase: String, Codable, Sendable {
    case puppy
    case teenage
    case adult
    case senior

    /// User-facing label for the phase
    public var label: String {
        switch self {
        case .puppy: return Strings.Lifecycle.puppy
        case .teenage: return Strings.Lifecycle.teenage
        case .adult: return Strings.Lifecycle.adult
        case .senior: return Strings.Lifecycle.senior
        }
    }

    /// Whether this phase should use "puppy" terminology
    public var usesPuppyTerminology: Bool {
        self == .puppy
    }
}

/// Profile for a puppy, configurable by the user
public struct PuppyProfile: Codable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var breed: String?
    public var breedId: Int?  // TheDogAPI breed ID for breed-specific features
    public var birthDate: Date
    public var homeDate: Date
    public var sizeCategory: SizeCategory
    public var gender: Gender
    public var mealSchedule: MealSchedule
    public var exerciseConfig: ExerciseConfig
    public var predictionConfig: PredictionConfig
    public var walkSchedule: WalkSchedule
    public var notificationSettings: NotificationSettings
    public var medicationSchedule: MedicationSchedule
    public var webhookConfig: WebhookConfig
    public var householdMembers: HouseholdMembers
    public var behaviorInterventions: [BehaviorIntervention]
    public var modifiedAt: Date

    /// Last lifecycle phase the user acknowledged via transition sheet
    /// Used to show celebration sheet when dog enters new phase
    public var lastAcknowledgedPhase: LifecyclePhase?

    /// Profile photo filename (stored in ProfilePhotos directory)
    public var profilePhotoFilename: String?

    /// Date when the puppy passed away (nil if still alive)
    public var passedDate: Date?

    /// Ownership type: owned by this user or shared from another user
    /// This is a transient property not persisted in Core Data (determined by which store the profile came from)
    public var ownership: ProfileOwnership = .owned

    // MARK: - Legacy Migration
    /// Legacy one-time purchasers are grandfathered into Otis+
    /// This field is only used for migration from the old purchase model
    public var legacyPremiumUnlocked: Bool

    public enum SizeCategory: String, Codable, CaseIterable, Identifiable, Sendable {
        case small
        case medium
        case large
        case extraLarge

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .small: return Strings.SizeCategory.small
            case .medium: return Strings.SizeCategory.medium
            case .large: return Strings.SizeCategory.large
            case .extraLarge: return Strings.SizeCategory.extraLarge
            }
        }

        public var examples: String {
            switch self {
            case .small: return Strings.SizeCategory.smallExamples
            case .medium: return Strings.SizeCategory.mediumExamples
            case .large: return Strings.SizeCategory.largeExamples
            case .extraLarge: return Strings.SizeCategory.extraLargeExamples
            }
        }
    }

    /// Gender of the dog - used for pronouns throughout the app
    /// When unspecified, they/them pronouns are used
    public enum Gender: String, Codable, CaseIterable, Identifiable, Sendable {
        case male
        case female
        case unspecified

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .male: return Strings.Gender.male
            case .female: return Strings.Gender.female
            case .unspecified: return Strings.Gender.preferNotToSay
            }
        }

        /// Subject pronoun: he/she/they
        public var subjectPronoun: String {
            switch self {
            case .male: return Strings.Pronouns.he
            case .female: return Strings.Pronouns.she
            case .unspecified: return Strings.Pronouns.they
            }
        }

        /// Object pronoun: him/her/them
        public var objectPronoun: String {
            switch self {
            case .male: return Strings.Pronouns.him
            case .female: return Strings.Pronouns.her
            case .unspecified: return Strings.Pronouns.them
            }
        }

        /// Possessive pronoun: his/her/their
        public var possessivePronoun: String {
            switch self {
            case .male: return Strings.Pronouns.his
            case .female: return Strings.Pronouns.hers
            case .unspecified: return Strings.Pronouns.their
            }
        }

        /// Reflexive pronoun: himself/herself/themselves
        public var reflexivePronoun: String {
            switch self {
            case .male: return Strings.Pronouns.himself
            case .female: return Strings.Pronouns.herself
            case .unspecified: return Strings.Pronouns.themselves
            }
        }

        /// Whether this gender's pronouns require plural verb forms
        /// "they wake" (plural) vs "he/she wakes" (singular)
        /// Note: "they" takes plural verb conjugation even when used as singular
        public var usesPluralVerbForm: Bool {
            self == .unspecified
        }
    }

    // MARK: - Pronoun Convenience Accessors

    /// Subject pronoun for this dog: he/she/they
    public var subjectPronoun: String { gender.subjectPronoun }

    /// Object pronoun for this dog: him/her/them
    public var objectPronoun: String { gender.objectPronoun }

    /// Possessive pronoun for this dog: his/her/their
    public var possessivePronoun: String { gender.possessivePronoun }

    /// Reflexive pronoun for this dog: himself/herself/themselves
    public var reflexivePronoun: String { gender.reflexivePronoun }

    /// Whether this dog's pronouns require plural verb forms
    /// "they wake" vs "he/she wakes"
    public var usesPluralVerbForm: Bool { gender.usesPluralVerbForm }

    // MARK: - Age & Duration Computed Properties

    /// Age in weeks from birth date
    public var ageInWeeks: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: birthDate, to: Date())
        return components.weekOfYear ?? 0
    }

    /// Age in months (approximate)
    public var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        return components.month ?? 0
    }

    /// Days since coming home
    public var daysHome: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: homeDate, to: Date())
        return components.day ?? 0
    }

    /// Maximum exercise minutes based on age
    public var maxExerciseMinutes: Int {
        ageInMonths * exerciseConfig.minutesPerMonthOfAge
    }

    // MARK: - Lifecycle Phase

    /// Age threshold (in months) when dog becomes senior, varies by size
    /// Large breeds age faster and become seniors earlier
    public var seniorAgeMonths: Int {
        switch sizeCategory {
        case .small: return 120      // 10 years
        case .medium: return 96      // 8 years
        case .large: return 84       // 7 years
        case .extraLarge: return 72  // 6 years
        }
    }

    /// Current lifecycle phase based on age and size
    public var lifecyclePhase: LifecyclePhase {
        let months = ageInMonths

        // Deceased dogs are always shown in their last phase (typically senior)
        // but we still calculate based on age for historical accuracy
        if months >= seniorAgeMonths {
            return .senior
        } else if months >= 18 {
            return .adult
        } else if months >= 8 {
            return .teenage
        } else {
            return .puppy
        }
    }

    /// Whether the dog has passed away
    public var isDeceased: Bool {
        passedDate != nil
    }

    /// Returns "puppy" or "dog" based on lifecycle phase
    /// Use this for generic references like "your puppy" vs "your dog"
    public var petTerm: String {
        lifecyclePhase.usesPuppyTerminology ? Strings.Lifecycle.Terms.puppy : Strings.Lifecycle.Terms.dog
    }

    /// Returns possessive form: "puppy's" or "dog's" based on lifecycle phase
    public var petTermPossessive: String {
        lifecyclePhase.usesPuppyTerminology ? Strings.Lifecycle.Terms.puppyPossessive : Strings.Lifecycle.Terms.dogPossessive
    }


    /// Creates a default profile for onboarding
    public static func defaultProfile(name: String, birthDate: Date, homeDate: Date, size: SizeCategory, gender: Gender = .unspecified) -> PuppyProfile {
        let ageWeeks = Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 8

        return PuppyProfile(
            id: UUID(),
            name: name,
            breed: nil,
            breedId: nil,
            birthDate: birthDate,
            homeDate: homeDate,
            sizeCategory: size,
            gender: gender,
            mealSchedule: MealSchedule.defaultSchedule(ageWeeks: ageWeeks, size: size),
            exerciseConfig: ExerciseConfig.defaultConfig(),
            predictionConfig: PredictionConfig.defaultConfig(),
            walkSchedule: WalkSchedule.defaultSchedule(),
            notificationSettings: NotificationSettings.defaultSettings(),
            medicationSchedule: MedicationSchedule.empty(),
            webhookConfig: WebhookConfig.defaultConfig(),
            householdMembers: HouseholdMembers.empty(),
            modifiedAt: Date(),
            legacyPremiumUnlocked: false
        )
    }

    // MARK: - Initializers

    public init(
        id: UUID = UUID(),
        name: String,
        breed: String? = nil,
        breedId: Int? = nil,
        birthDate: Date,
        homeDate: Date,
        sizeCategory: SizeCategory,
        gender: Gender = .unspecified,
        mealSchedule: MealSchedule,
        exerciseConfig: ExerciseConfig,
        predictionConfig: PredictionConfig,
        walkSchedule: WalkSchedule,
        notificationSettings: NotificationSettings,
        medicationSchedule: MedicationSchedule = MedicationSchedule.empty(),
        webhookConfig: WebhookConfig = WebhookConfig.defaultConfig(),
        householdMembers: HouseholdMembers = HouseholdMembers.empty(),
        behaviorInterventions: [BehaviorIntervention] = [],
        modifiedAt: Date? = nil,
        lastAcknowledgedPhase: LifecyclePhase? = nil,
        profilePhotoFilename: String? = nil,
        passedDate: Date? = nil,
        ownership: ProfileOwnership = .owned,
        legacyPremiumUnlocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.breedId = breedId
        self.birthDate = birthDate
        self.homeDate = homeDate
        self.sizeCategory = sizeCategory
        self.gender = gender
        self.mealSchedule = mealSchedule
        self.exerciseConfig = exerciseConfig
        self.predictionConfig = predictionConfig
        self.walkSchedule = walkSchedule
        self.notificationSettings = notificationSettings
        self.medicationSchedule = medicationSchedule
        self.webhookConfig = webhookConfig
        self.householdMembers = householdMembers
        self.behaviorInterventions = behaviorInterventions
        self.modifiedAt = modifiedAt ?? Date()
        self.lastAcknowledgedPhase = lastAcknowledgedPhase
        self.profilePhotoFilename = profilePhotoFilename
        self.passedDate = passedDate
        self.ownership = ownership
        self.legacyPremiumUnlocked = legacyPremiumUnlocked
    }

    // MARK: - Codable

    public enum CodingKeys: String, CodingKey {
        case id
        case name, breed, breedId, birthDate, homeDate, sizeCategory, gender
        case mealSchedule, exerciseConfig, predictionConfig
        case walkSchedule, notificationSettings, medicationSchedule, webhookConfig
        case householdMembers, behaviorInterventions
        case modifiedAt
        case lastAcknowledgedPhase
        case profilePhotoFilename
        case passedDate
        // Legacy fields for migration (read old values)
        case freeStartDate, isPremiumUnlocked
        // New field
        case legacyPremiumUnlocked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        breed = try container.decodeIfPresent(String.self, forKey: .breed)
        breedId = try container.decodeIfPresent(Int.self, forKey: .breedId)
        birthDate = try container.decode(Date.self, forKey: .birthDate)
        homeDate = try container.decode(Date.self, forKey: .homeDate)
        sizeCategory = try container.decode(SizeCategory.self, forKey: .sizeCategory)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender) ?? .unspecified
        mealSchedule = try container.decode(MealSchedule.self, forKey: .mealSchedule)
        exerciseConfig = try container.decode(ExerciseConfig.self, forKey: .exerciseConfig)
        predictionConfig = try container.decode(PredictionConfig.self, forKey: .predictionConfig)
        walkSchedule = try container.decodeIfPresent(WalkSchedule.self, forKey: .walkSchedule) ?? WalkSchedule.defaultSchedule()
        notificationSettings = try container.decodeIfPresent(NotificationSettings.self, forKey: .notificationSettings) ?? NotificationSettings.defaultSettings()
        medicationSchedule = try container.decodeIfPresent(MedicationSchedule.self, forKey: .medicationSchedule) ?? MedicationSchedule.empty()
        webhookConfig = try container.decodeIfPresent(WebhookConfig.self, forKey: .webhookConfig) ?? WebhookConfig.defaultConfig()
        householdMembers = try container.decodeIfPresent(HouseholdMembers.self, forKey: .householdMembers) ?? HouseholdMembers.empty()
        behaviorInterventions = try container.decodeIfPresent([BehaviorIntervention].self, forKey: .behaviorInterventions) ?? []
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()
        lastAcknowledgedPhase = try container.decodeIfPresent(LifecyclePhase.self, forKey: .lastAcknowledgedPhase)
        profilePhotoFilename = try container.decodeIfPresent(String.self, forKey: .profilePhotoFilename)
        passedDate = try container.decodeIfPresent(Date.self, forKey: .passedDate)

        // Migration: check new field first, then fall back to old isPremiumUnlocked
        if let legacy = try container.decodeIfPresent(Bool.self, forKey: .legacyPremiumUnlocked) {
            legacyPremiumUnlocked = legacy
        } else if let oldPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremiumUnlocked) {
            // Migrate from old isPremiumUnlocked to new legacyPremiumUnlocked
            legacyPremiumUnlocked = oldPremium
        } else {
            legacyPremiumUnlocked = false
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(breed, forKey: .breed)
        try container.encodeIfPresent(breedId, forKey: .breedId)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(homeDate, forKey: .homeDate)
        try container.encode(sizeCategory, forKey: .sizeCategory)
        try container.encode(gender, forKey: .gender)
        try container.encode(mealSchedule, forKey: .mealSchedule)
        try container.encode(exerciseConfig, forKey: .exerciseConfig)
        try container.encode(predictionConfig, forKey: .predictionConfig)
        try container.encode(walkSchedule, forKey: .walkSchedule)
        try container.encode(notificationSettings, forKey: .notificationSettings)
        try container.encode(medicationSchedule, forKey: .medicationSchedule)
        try container.encode(webhookConfig, forKey: .webhookConfig)
        try container.encode(householdMembers, forKey: .householdMembers)
        try container.encode(behaviorInterventions, forKey: .behaviorInterventions)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encodeIfPresent(lastAcknowledgedPhase, forKey: .lastAcknowledgedPhase)
        try container.encodeIfPresent(profilePhotoFilename, forKey: .profilePhotoFilename)
        try container.encodeIfPresent(passedDate, forKey: .passedDate)
        try container.encode(legacyPremiumUnlocked, forKey: .legacyPremiumUnlocked)
        // Note: No longer writing freeStartDate or isPremiumUnlocked (subscription replaces these)
    }

    // MARK: - Mutation Helpers

    /// Returns a copy with updated modifiedAt timestamp
    public func withUpdatedTimestamp() -> PuppyProfile {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }
}
