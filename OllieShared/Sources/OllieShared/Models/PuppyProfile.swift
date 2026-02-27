//
//  PuppyProfile.swift
//  OllieShared
//

import Foundation

/// Profile for a puppy, configurable by the user
public struct PuppyProfile: Codable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var breed: String?
    public var birthDate: Date
    public var homeDate: Date
    public var sizeCategory: SizeCategory
    public var mealSchedule: MealSchedule
    public var exerciseConfig: ExerciseConfig
    public var predictionConfig: PredictionConfig
    public var walkSchedule: WalkSchedule
    public var notificationSettings: NotificationSettings
    public var medicationSchedule: MedicationSchedule
    public var modifiedAt: Date

    /// Profile photo filename (stored in ProfilePhotos directory)
    public var profilePhotoFilename: String?

    // MARK: - Legacy Migration
    /// Legacy one-time purchasers are grandfathered into Ollie+
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


    /// Creates a default profile for onboarding
    public static func defaultProfile(name: String, birthDate: Date, homeDate: Date, size: SizeCategory) -> PuppyProfile {
        let ageWeeks = Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 8

        return PuppyProfile(
            id: UUID(),
            name: name,
            breed: nil,
            birthDate: birthDate,
            homeDate: homeDate,
            sizeCategory: size,
            mealSchedule: MealSchedule.defaultSchedule(ageWeeks: ageWeeks, size: size),
            exerciseConfig: ExerciseConfig.defaultConfig(),
            predictionConfig: PredictionConfig.defaultConfig(),
            walkSchedule: WalkSchedule.defaultSchedule(),
            notificationSettings: NotificationSettings.defaultSettings(),
            medicationSchedule: MedicationSchedule.empty(),
            modifiedAt: Date(),
            legacyPremiumUnlocked: false
        )
    }

    // MARK: - Initializers

    public init(
        id: UUID = UUID(),
        name: String,
        breed: String? = nil,
        birthDate: Date,
        homeDate: Date,
        sizeCategory: SizeCategory,
        mealSchedule: MealSchedule,
        exerciseConfig: ExerciseConfig,
        predictionConfig: PredictionConfig,
        walkSchedule: WalkSchedule,
        notificationSettings: NotificationSettings,
        medicationSchedule: MedicationSchedule = MedicationSchedule.empty(),
        modifiedAt: Date? = nil,
        profilePhotoFilename: String? = nil,
        legacyPremiumUnlocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.birthDate = birthDate
        self.homeDate = homeDate
        self.sizeCategory = sizeCategory
        self.mealSchedule = mealSchedule
        self.exerciseConfig = exerciseConfig
        self.predictionConfig = predictionConfig
        self.walkSchedule = walkSchedule
        self.notificationSettings = notificationSettings
        self.medicationSchedule = medicationSchedule
        self.modifiedAt = modifiedAt ?? Date()
        self.profilePhotoFilename = profilePhotoFilename
        self.legacyPremiumUnlocked = legacyPremiumUnlocked
    }

    // MARK: - Codable

    public enum CodingKeys: String, CodingKey {
        case id
        case name, breed, birthDate, homeDate, sizeCategory
        case mealSchedule, exerciseConfig, predictionConfig
        case walkSchedule, notificationSettings, medicationSchedule
        case modifiedAt
        case profilePhotoFilename
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
        birthDate = try container.decode(Date.self, forKey: .birthDate)
        homeDate = try container.decode(Date.self, forKey: .homeDate)
        sizeCategory = try container.decode(SizeCategory.self, forKey: .sizeCategory)
        mealSchedule = try container.decode(MealSchedule.self, forKey: .mealSchedule)
        exerciseConfig = try container.decode(ExerciseConfig.self, forKey: .exerciseConfig)
        predictionConfig = try container.decode(PredictionConfig.self, forKey: .predictionConfig)
        walkSchedule = try container.decodeIfPresent(WalkSchedule.self, forKey: .walkSchedule) ?? WalkSchedule.defaultSchedule()
        notificationSettings = try container.decodeIfPresent(NotificationSettings.self, forKey: .notificationSettings) ?? NotificationSettings.defaultSettings()
        medicationSchedule = try container.decodeIfPresent(MedicationSchedule.self, forKey: .medicationSchedule) ?? MedicationSchedule.empty()
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()
        profilePhotoFilename = try container.decodeIfPresent(String.self, forKey: .profilePhotoFilename)

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
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(homeDate, forKey: .homeDate)
        try container.encode(sizeCategory, forKey: .sizeCategory)
        try container.encode(mealSchedule, forKey: .mealSchedule)
        try container.encode(exerciseConfig, forKey: .exerciseConfig)
        try container.encode(predictionConfig, forKey: .predictionConfig)
        try container.encode(walkSchedule, forKey: .walkSchedule)
        try container.encode(notificationSettings, forKey: .notificationSettings)
        try container.encode(medicationSchedule, forKey: .medicationSchedule)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encodeIfPresent(profilePhotoFilename, forKey: .profilePhotoFilename)
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
