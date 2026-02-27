//
//  CDPuppyProfile+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between PuppyProfile and CDPuppyProfile
//

import CoreData
import OllieShared

extension CDPuppyProfile {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from PuppyProfile struct
    func update(from profile: PuppyProfile) {
        self.id = profile.id
        self.name = profile.name
        self.breed = profile.breed
        self.birthDate = profile.birthDate
        self.homeDate = profile.homeDate
        self.sizeCategory = profile.sizeCategory.rawValue
        self.modifiedAt = profile.modifiedAt
        self.profilePhotoFilename = profile.profilePhotoFilename
        self.legacyPremiumUnlocked = profile.legacyPremiumUnlocked

        // Encode nested configs as JSON Data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        self.mealScheduleData = try? encoder.encode(profile.mealSchedule)
        self.exerciseConfigData = try? encoder.encode(profile.exerciseConfig)
        self.predictionConfigData = try? encoder.encode(profile.predictionConfig)
        self.walkScheduleData = try? encoder.encode(profile.walkSchedule)
        self.notificationSettingsData = try? encoder.encode(profile.notificationSettings)
        self.medicationScheduleData = try? encoder.encode(profile.medicationSchedule)
    }

    /// Create a new CDPuppyProfile from a PuppyProfile struct
    static func create(from profile: PuppyProfile, in context: NSManagedObjectContext) -> CDPuppyProfile {
        let cdProfile = CDPuppyProfile(context: context)
        cdProfile.update(from: profile)
        return cdProfile
    }

    // MARK: - Convert to Swift Struct

    /// Convert to PuppyProfile struct
    func toPuppyProfile() -> PuppyProfile? {
        guard let id = self.id,
              let name = self.name,
              let birthDate = self.birthDate,
              let homeDate = self.homeDate,
              let sizeCategoryString = self.sizeCategory,
              let sizeCategory = PuppyProfile.SizeCategory(rawValue: sizeCategoryString),
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Decode nested configs from JSON Data with fallbacks to defaults
        let mealSchedule: MealSchedule
        if let data = self.mealScheduleData,
           let decoded = try? decoder.decode(MealSchedule.self, from: data) {
            mealSchedule = decoded
        } else {
            let ageWeeks = Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 8
            mealSchedule = MealSchedule.defaultSchedule(ageWeeks: ageWeeks, size: sizeCategory)
        }

        let exerciseConfig: ExerciseConfig
        if let data = self.exerciseConfigData,
           let decoded = try? decoder.decode(ExerciseConfig.self, from: data) {
            exerciseConfig = decoded
        } else {
            exerciseConfig = ExerciseConfig.defaultConfig()
        }

        let predictionConfig: PredictionConfig
        if let data = self.predictionConfigData,
           let decoded = try? decoder.decode(PredictionConfig.self, from: data) {
            predictionConfig = decoded
        } else {
            predictionConfig = PredictionConfig.defaultConfig()
        }

        let walkSchedule: WalkSchedule
        if let data = self.walkScheduleData,
           let decoded = try? decoder.decode(WalkSchedule.self, from: data) {
            walkSchedule = decoded
        } else {
            walkSchedule = WalkSchedule.defaultSchedule()
        }

        let notificationSettings: NotificationSettings
        if let data = self.notificationSettingsData,
           let decoded = try? decoder.decode(NotificationSettings.self, from: data) {
            notificationSettings = decoded
        } else {
            notificationSettings = NotificationSettings.defaultSettings()
        }

        let medicationSchedule: MedicationSchedule
        if let data = self.medicationScheduleData,
           let decoded = try? decoder.decode(MedicationSchedule.self, from: data) {
            medicationSchedule = decoded
        } else {
            medicationSchedule = MedicationSchedule.empty()
        }

        return PuppyProfile(
            id: id,
            name: name,
            breed: self.breed,
            birthDate: birthDate,
            homeDate: homeDate,
            sizeCategory: sizeCategory,
            mealSchedule: mealSchedule,
            exerciseConfig: exerciseConfig,
            predictionConfig: predictionConfig,
            walkSchedule: walkSchedule,
            notificationSettings: notificationSettings,
            medicationSchedule: medicationSchedule,
            modifiedAt: modifiedAt,
            profilePhotoFilename: self.profilePhotoFilename,
            legacyPremiumUnlocked: self.legacyPremiumUnlocked
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDPuppyProfile {

    /// Fetch the profile from Core Data
    static func fetchProfile(in context: NSManagedObjectContext) -> CDPuppyProfile? {
        let request = NSFetchRequest<CDPuppyProfile>(entityName: "CDPuppyProfile")
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Fetch profile by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDPuppyProfile? {
        let request = NSFetchRequest<CDPuppyProfile>(entityName: "CDPuppyProfile")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
