//
//  ProfileStore.swift
//  Ollie-app
//

import Foundation
import Combine

/// Manages reading and writing the puppy profile
@MainActor
class ProfileStore: ObservableObject {
    @Published private(set) var profile: PuppyProfile?
    @Published private(set) var isLoading: Bool = true

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        loadProfile()
    }

    // MARK: - Public Methods

    /// Check if a profile exists
    var hasProfile: Bool {
        profile != nil
    }

    /// Save a new or updated profile
    func saveProfile(_ newProfile: PuppyProfile) {
        profile = newProfile
        writeProfile()
    }

    /// Update the meal schedule
    func updateMealSchedule(_ schedule: MealSchedule) {
        guard var currentProfile = profile else { return }
        currentProfile.mealSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Update the exercise config
    func updateExerciseConfig(_ config: ExerciseConfig) {
        guard var currentProfile = profile else { return }
        currentProfile.exerciseConfig = config
        saveProfile(currentProfile)
    }

    /// Update the prediction config
    func updatePredictionConfig(_ config: PredictionConfig) {
        guard var currentProfile = profile else { return }
        currentProfile.predictionConfig = config
        saveProfile(currentProfile)
    }

    /// Reset profile (for testing or re-onboarding)
    func resetProfile() {
        profile = nil
        let url = profileURL
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Private Methods

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var profileURL: URL {
        documentsURL.appendingPathComponent(Constants.profileFileName)
    }

    private func loadProfile() {
        isLoading = true
        defer { isLoading = false }

        guard fileManager.fileExists(atPath: profileURL.path),
              let data = try? Data(contentsOf: profileURL),
              let loadedProfile = try? decoder.decode(PuppyProfile.self, from: data) else {
            profile = nil
            return
        }

        profile = loadedProfile
    }

    private func writeProfile() {
        guard let profile = profile,
              let data = try? encoder.encode(profile) else {
            return
        }

        try? data.write(to: profileURL, options: .atomic)
    }
}
