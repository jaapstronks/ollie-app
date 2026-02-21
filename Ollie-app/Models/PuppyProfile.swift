//
//  PuppyProfile.swift
//  Ollie-app
//

import Foundation

/// Profile for a puppy, configurable by the user
struct PuppyProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var breed: String?
    var birthDate: Date
    var homeDate: Date
    var sizeCategory: SizeCategory
    var mealSchedule: MealSchedule
    var exerciseConfig: ExerciseConfig
    var predictionConfig: PredictionConfig
    var walkSchedule: WalkSchedule
    var notificationSettings: NotificationSettings
    var medicationSchedule: MedicationSchedule

    // MARK: - Monetization
    var freeStartDate: Date          // Set on profile creation
    var isPremiumUnlocked: Bool      // Set to true after purchase

    enum SizeCategory: String, Codable, CaseIterable, Identifiable {
        case small
        case medium
        case large
        case extraLarge

        var id: String { rawValue }

        var label: String {
            switch self {
            case .small: return Strings.SizeCategory.small
            case .medium: return Strings.SizeCategory.medium
            case .large: return Strings.SizeCategory.large
            case .extraLarge: return Strings.SizeCategory.extraLarge
            }
        }

        var examples: String {
            switch self {
            case .small: return Strings.SizeCategory.smallExamples
            case .medium: return Strings.SizeCategory.mediumExamples
            case .large: return Strings.SizeCategory.largeExamples
            case .extraLarge: return Strings.SizeCategory.extraLargeExamples
            }
        }
    }

    /// Age in weeks from birth date
    var ageInWeeks: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: birthDate, to: Date())
        return components.weekOfYear ?? 0
    }

    /// Age in months (approximate)
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        return components.month ?? 0
    }

    /// Days since coming home
    var daysHome: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: homeDate, to: Date())
        return components.day ?? 0
    }

    /// Maximum exercise minutes based on age
    var maxExerciseMinutes: Int {
        ageInMonths * exerciseConfig.minutesPerMonthOfAge
    }

    // MARK: - Monetization Computed Properties

    /// Days remaining in the free trial period (-1 if premium unlocked)
    var freeDaysRemaining: Int {
        guard !isPremiumUnlocked else { return -1 }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: freeStartDate, to: Date()).day ?? 0
        return max(0, 21 - daysSinceStart)
    }

    /// Whether the free trial period has expired
    var isFreePeriodExpired: Bool {
        !isPremiumUnlocked && freeDaysRemaining <= 0
    }

    /// Whether the user can log events (premium or still in free period)
    var canLogEvents: Bool {
        isPremiumUnlocked || !isFreePeriodExpired
    }

    /// Creates a default profile for onboarding
    static func defaultProfile(name: String, birthDate: Date, homeDate: Date, size: SizeCategory) -> PuppyProfile {
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
            freeStartDate: Date(),
            isPremiumUnlocked: false
        )
    }

    // MARK: - Initializers

    init(
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
        freeStartDate: Date = Date(),
        isPremiumUnlocked: Bool = false
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
        self.freeStartDate = freeStartDate
        self.isPremiumUnlocked = isPremiumUnlocked
    }

    // MARK: - Codable (with migration support)

    enum CodingKeys: String, CodingKey {
        case id
        case name, breed, birthDate, homeDate, sizeCategory
        case mealSchedule, exerciseConfig, predictionConfig
        case walkSchedule, notificationSettings, medicationSchedule
        case freeStartDate, isPremiumUnlocked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Migration: generate new UUID for existing profiles without id
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        breed = try container.decodeIfPresent(String.self, forKey: .breed)
        birthDate = try container.decode(Date.self, forKey: .birthDate)
        homeDate = try container.decode(Date.self, forKey: .homeDate)
        sizeCategory = try container.decode(SizeCategory.self, forKey: .sizeCategory)
        mealSchedule = try container.decode(MealSchedule.self, forKey: .mealSchedule)
        exerciseConfig = try container.decode(ExerciseConfig.self, forKey: .exerciseConfig)
        predictionConfig = try container.decode(PredictionConfig.self, forKey: .predictionConfig)
        // Migration: use defaults if not present in saved profile
        walkSchedule = try container.decodeIfPresent(WalkSchedule.self, forKey: .walkSchedule) ?? WalkSchedule.defaultSchedule()
        notificationSettings = try container.decodeIfPresent(NotificationSettings.self, forKey: .notificationSettings) ?? NotificationSettings.defaultSettings()
        // Migration: medicationSchedule defaults to empty for existing profiles
        medicationSchedule = try container.decodeIfPresent(MedicationSchedule.self, forKey: .medicationSchedule) ?? MedicationSchedule.empty()
        // Migration: monetization fields default to fresh free period for existing users
        freeStartDate = try container.decodeIfPresent(Date.self, forKey: .freeStartDate) ?? Date()
        isPremiumUnlocked = try container.decodeIfPresent(Bool.self, forKey: .isPremiumUnlocked) ?? false
    }

    func encode(to encoder: Encoder) throws {
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
        try container.encode(freeStartDate, forKey: .freeStartDate)
        try container.encode(isPremiumUnlocked, forKey: .isPremiumUnlocked)
    }
}
