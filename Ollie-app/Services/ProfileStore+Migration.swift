//
//  ProfileStore+Migration.swift
//  Otis-app
//
//  Migration methods for ProfileStore.
//

import Foundation
import OtisShared
import os

// MARK: - Migration Methods

extension ProfileStore {

    /// Link orphaned events (without profile relationship) to the first profile
    func migrateOrphanedEventsIfNeeded() {
        guard let firstProfile = profiles.first,
              let cdProfile = CDPuppyProfile.fetch(byId: firstProfile.id, in: viewContext) else {
            return
        }

        let linkedCount = CDPuppyEvent.linkOrphanedEvents(to: cdProfile, in: viewContext)
        if linkedCount > 0 {
            do {
                try persistenceController.save()
                logger.info("Linked \(linkedCount) orphaned events to profile '\(firstProfile.name)'")
            } catch {
                logger.error("Failed to save after linking orphaned events: \(error.localizedDescription)")
            }
        }
    }

    /// Migrate breed name to breedId if profile has breed but no breedId
    func migrateBreedNameToId() async {
        guard let profile = activeProfile,
              let breedName = profile.breed,
              !breedName.isEmpty,
              profile.breedId == nil else {
            return
        }

        logger.info("Migrating breed name '\(breedName)' to breedId")

        // Fetch breeds and find matching breed
        await BreedService.shared.fetchBreeds()

        if let matchedBreed = BreedService.shared.findBreed(named: breedName) {
            updateBreedId(matchedBreed.id)
            logger.info("Migrated breed '\(breedName)' to breedId \(matchedBreed.id)")
        } else {
            logger.warning("Could not find breed match for '\(breedName)'")
        }
    }

    /// Create a test profile for UI testing if none exists
    func createTestProfileIfNeeded() {
        // Check if profile already exists
        if CDPuppyProfile.fetchProfile(in: viewContext) != nil {
            return
        }

        logger.info("Creating test profile for UI testing")

        // Create test profile: "Oliver", 16 weeks old, Golden Retriever
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .weekOfYear, value: -16, to: Date()) ?? Date()
        let homeDate = calendar.date(byAdding: .weekOfYear, value: -8, to: Date()) ?? Date()

        var testProfile = PuppyProfile.defaultProfile(
            name: "Oliver",
            birthDate: birthDate,
            homeDate: homeDate,
            size: .medium
        )
        testProfile.breed = "Golden Retriever"

        _ = CDPuppyProfile.create(from: testProfile, in: viewContext)
        try? persistenceController.save()
    }
}
