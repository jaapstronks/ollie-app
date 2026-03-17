//
//  SyncTestFixtures.swift
//  OtisShared
//
//  Test data fixtures with predictable IDs for sync testing.
//  All test IDs start with TEST0000 for easy filtering in logs.
//
//  Usage in Debug builds:
//  1. Create test profile via debug menu
//  2. Run sync operations
//  3. Filter logs: message CONTAINS "[TEST0000]"
//

import CoreData
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Test UUIDs
// Note: UUIDs must only contain hex characters (0-9, A-F)
// We use "AA000000" prefix for easy filtering - search for "[AA000000]" in logs

/// Test profile ID - always the same for consistent testing
public let testProfileID = UUID(uuidString: "AA000000-0000-0000-0000-000000000001")!

/// Test event IDs by type - predictable for log filtering
public enum TestEventID: String, CaseIterable {
    case pee = "AA000000-0000-0000-0000-000000000010"
    case poop = "AA000000-0000-0000-0000-000000000011"
    case meal = "AA000000-0000-0000-0000-000000000012"
    case nap = "AA000000-0000-0000-0000-000000000013"
    case walk = "AA000000-0000-0000-0000-000000000014"
    case training = "AA000000-0000-0000-0000-000000000015"
    case moment = "AA000000-0000-0000-0000-000000000016"
    case weight = "AA000000-0000-0000-0000-000000000017"

    public var uuid: UUID {
        UUID(uuidString: rawValue)!
    }

    public var eventType: String {
        switch self {
        case .pee: return "plassen"
        case .poop: return "poepen"
        case .meal: return "eten"
        case .nap: return "slapen"
        case .walk: return "uitlaten"
        case .training: return "training"
        case .moment: return "moment"
        case .weight: return "gewicht"
        }
    }
}

/// Test weight measurement ID
public let testWeightID = UUID(uuidString: "AA000000-0000-0000-0000-000000000020")!

/// Test milestone ID
public let testMilestoneID = UUID(uuidString: "AA000000-0000-0000-0000-000000000021")!

/// Test photo event ID (for photo sync testing)
public let testPhotoEventID = UUID(uuidString: "AA000000-0000-0000-0000-000000000022")!

// MARK: - Additional Entity Test IDs

/// Test IDs for all entity types (Phase 1.2 testing)
public enum TestEntityID: String, CaseIterable {
    case walkSpot = "AA000000-0000-0000-0000-000000000030"
    case dogContact = "AA000000-0000-0000-0000-000000000031"
    case dogAppointment = "AA000000-0000-0000-0000-000000000032"
    case document = "AA000000-0000-0000-0000-000000000033"
    case exposure = "AA000000-0000-0000-0000-000000000034"
    case comfortableItem = "AA000000-0000-0000-0000-000000000035"
    case earlyMilestone = "AA000000-0000-0000-0000-000000000036"
    case medicationCompletion = "AA000000-0000-0000-0000-000000000037"
    case routineItem = "AA000000-0000-0000-0000-000000000038"
    case weightGoal = "AA000000-0000-0000-0000-000000000039"
    case bodyConditionScore = "AA000000-0000-0000-0000-00000000003A"
    case groomingActivity = "AA000000-0000-0000-0000-00000000003B"
    case enrichmentActivity = "AA000000-0000-0000-0000-00000000003C"
    case skillProgress = "AA000000-0000-0000-0000-00000000003D"
    case masteredSkill = "AA000000-0000-0000-0000-00000000003E"
    case regressionLog = "AA000000-0000-0000-0000-00000000003F"
    case exploredTile = "AA000000-0000-0000-0000-000000000040"
    case userIdentity = "AA000000-0000-0000-0000-000000000041"
    case userSentimentCheckIn = "AA000000-0000-0000-0000-000000000042"

    public var uuid: UUID {
        UUID(uuidString: rawValue)!
    }

    public var entityName: String {
        switch self {
        case .walkSpot: return "CDWalkSpot"
        case .dogContact: return "CDDogContact"
        case .dogAppointment: return "CDDogAppointment"
        case .document: return "CDDocument"
        case .exposure: return "CDExposure"
        case .comfortableItem: return "CDComfortableItem"
        case .earlyMilestone: return "CDEarlyMilestone"
        case .medicationCompletion: return "CDMedicationCompletion"
        case .routineItem: return "CDRoutineItem"
        case .weightGoal: return "CDWeightGoal"
        case .bodyConditionScore: return "CDBodyConditionScore"
        case .groomingActivity: return "CDGroomingActivity"
        case .enrichmentActivity: return "CDEnrichmentActivity"
        case .skillProgress: return "CDSkillProgress"
        case .masteredSkill: return "CDMasteredSkill"
        case .regressionLog: return "CDRegressionLog"
        case .exploredTile: return "CDExploredTile"
        case .userIdentity: return "CDUserIdentity"
        case .userSentimentCheckIn: return "CDUserSentimentCheckIn"
        }
    }

    public var displayName: String {
        switch self {
        case .walkSpot: return "Walk Spot"
        case .dogContact: return "Contact"
        case .dogAppointment: return "Appointment"
        case .document: return "Document"
        case .exposure: return "Exposure"
        case .comfortableItem: return "Comfortable Item"
        case .earlyMilestone: return "Early Milestone"
        case .medicationCompletion: return "Medication"
        case .routineItem: return "Routine"
        case .weightGoal: return "Weight Goal"
        case .bodyConditionScore: return "Body Score"
        case .groomingActivity: return "Grooming"
        case .enrichmentActivity: return "Enrichment"
        case .skillProgress: return "Skill Progress"
        case .masteredSkill: return "Mastered Skill"
        case .regressionLog: return "Regression Log"
        case .exploredTile: return "Explored Tile"
        case .userIdentity: return "User Identity"
        case .userSentimentCheckIn: return "Sentiment"
        }
    }
}

// MARK: - Test Profile Name

/// Name used for test profiles - easy to identify in UI
public let testProfileName = "TestDog-Sync"

// MARK: - Sync Test Fixtures

#if DEBUG
import CloudKit

/// Fixtures for sync testing with predictable, traceable data
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@MainActor
public struct SyncTestFixtures {

    // MARK: - Profile Creation

    /// Create a test profile with predictable ID
    /// - Parameter context: Core Data context
    /// - Returns: The created profile
    @discardableResult
    public static func createTestProfile(in context: NSManagedObjectContext) -> NSManagedObject {
        let entityName = "CDPuppyProfile"
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        let profile = NSManagedObject(entity: entity, insertInto: context)

        let now = Date()
        let fourMonthsAgo = Calendar.current.date(byAdding: .month, value: -4, to: now)!
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: now)!

        profile.setValue(testProfileID, forKey: "id")
        profile.setValue(testProfileName, forKey: "name")
        profile.setValue(fourMonthsAgo, forKey: "birthDate")
        profile.setValue(twoMonthsAgo, forKey: "homeDate")
        profile.setValue("medium", forKey: "sizeCategory")
        profile.setValue("male", forKey: "gender")
        profile.setValue(now, forKey: "modifiedAt")

        return profile
    }

    // MARK: - Event Creation

    /// Create a set of test events with predictable IDs
    /// - Parameters:
    ///   - context: Core Data context
    ///   - profile: The profile to attach events to
    /// - Returns: Array of created events
    @discardableResult
    public static func createTestEvents(
        in context: NSManagedObjectContext,
        for profile: NSManagedObject
    ) -> [NSManagedObject] {
        var events: [NSManagedObject] = []
        let entityName = "CDPuppyEvent"
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        let now = Date()

        for testEvent in TestEventID.allCases {
            let event = NSManagedObject(entity: entity, insertInto: context)
            let eventTime = Calendar.current.date(byAdding: .hour, value: -events.count, to: now)!

            event.setValue(testEvent.uuid, forKey: "id")
            event.setValue(testEvent.eventType, forKey: "type")
            event.setValue(eventTime, forKey: "time")
            event.setValue(now, forKey: "createdAt")
            event.setValue(now, forKey: "modifiedAt")
            event.setValue(profile, forKey: "profile")

            // Set location for potty events
            if testEvent == .pee || testEvent == .poop {
                event.setValue("buiten", forKey: "location")
            }

            // Set duration for walk/nap
            if testEvent == .walk {
                event.setValue(30, forKey: "durationMin")
            } else if testEvent == .nap {
                event.setValue(45, forKey: "durationMin")
            }

            // Set weight for weight event
            if testEvent == .weight {
                event.setValue(8.5, forKey: "weightKg")
            }

            events.append(event)
        }

        return events
    }

    // MARK: - Weight Measurement

    /// Create a test weight measurement
    @discardableResult
    public static func createTestWeight(
        in context: NSManagedObjectContext,
        for profile: NSManagedObject
    ) -> NSManagedObject {
        let entityName = "CDWeightMeasurement"
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        let measurement = NSManagedObject(entity: entity, insertInto: context)
        let now = Date()

        measurement.setValue(testWeightID, forKey: "id")
        measurement.setValue(8.5, forKey: "weightKg")
        measurement.setValue(now, forKey: "date")
        measurement.setValue(now, forKey: "createdAt")
        measurement.setValue(now, forKey: "modifiedAt")
        measurement.setValue(profile, forKey: "profile")

        return measurement
    }

    // MARK: - Milestone

    /// Create a test milestone
    @discardableResult
    public static func createTestMilestone(
        in context: NSManagedObjectContext,
        for profile: NSManagedObject
    ) -> NSManagedObject {
        let entityName = "CDMilestone"
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        let milestone = NSManagedObject(entity: entity, insertInto: context)
        let now = Date()

        milestone.setValue(testMilestoneID, forKey: "id")
        milestone.setValue("test.milestone.label", forKey: "labelKey")
        milestone.setValue("test.milestone.detail", forKey: "detailKey")
        milestone.setValue("health", forKey: "category")
        milestone.setValue("star.fill", forKey: "icon")
        milestone.setValue(false, forKey: "isCompleted")
        milestone.setValue(true, forKey: "isCustom")
        milestone.setValue(false, forKey: "isRecurring")
        milestone.setValue(0, forKey: "sortOrder")
        milestone.setValue(now, forKey: "createdAt")
        milestone.setValue(now, forKey: "modifiedAt")
        milestone.setValue(profile, forKey: "profile")

        return milestone
    }

    // MARK: - All Additional Entities

    /// Create a test entity of the specified type
    @discardableResult
    public static func createTestEntity(
        _ entityType: TestEntityID,
        in context: NSManagedObjectContext,
        for profile: NSManagedObject,
        userIdentity: NSManagedObject? = nil
    ) -> NSManagedObject {
        let entity = NSEntityDescription.entity(forEntityName: entityType.entityName, in: context)!
        let obj = NSManagedObject(entity: entity, insertInto: context)
        let now = Date()

        // Common fields
        obj.setValue(entityType.uuid, forKey: "id")
        obj.setValue(now, forKey: "modifiedAt")

        // Entity-specific fields
        switch entityType {
        case .walkSpot:
            obj.setValue("Test Walk Spot", forKey: "name")
            obj.setValue("park", forKey: "category")
            obj.setValue(52.3676, forKey: "latitude")
            obj.setValue(4.9041, forKey: "longitude")
            obj.setValue(false, forKey: "isFavorite")
            obj.setValue(1, forKey: "visitCount")
            obj.setValue(now, forKey: "createdAt")
            // WalkSpot doesn't have profile relationship

        case .dogContact:
            obj.setValue("Test Vet Contact", forKey: "name")
            obj.setValue("vet", forKey: "contactType")
            obj.setValue("test@example.com", forKey: "email")
            obj.setValue("+31612345678", forKey: "phone")
            obj.setValue(now, forKey: "createdAt")
            // DogContact doesn't have profile relationship

        case .dogAppointment:
            obj.setValue("Test Vet Appointment", forKey: "title")
            obj.setValue("vet", forKey: "appointmentType")
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
            obj.setValue(tomorrow, forKey: "startDate")
            obj.setValue(false, forKey: "isAllDay")
            obj.setValue(false, forKey: "isCompleted")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .document:
            obj.setValue("Test Document", forKey: "title")
            obj.setValue("vaccination", forKey: "type")
            obj.setValue(now, forKey: "documentDate")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .exposure:
            obj.setValue("test-exposure-item", forKey: "itemId")
            obj.setValue(now, forKey: "date")
            obj.setValue("close", forKey: "distance")
            obj.setValue("positive", forKey: "reaction")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .comfortableItem:
            obj.setValue("test-comfort-item", forKey: "itemId")
            obj.setValue(now, forKey: "comfortableAt")
            obj.setValue("gradual", forKey: "method")
            obj.setValue(profile, forKey: "profile")

        case .earlyMilestone:
            obj.setValue("test-early-milestone", forKey: "milestoneId")
            obj.setValue(now, forKey: "achievedAt")
            obj.setValue(profile, forKey: "profile")

        case .medicationCompletion:
            obj.setValue(UUID(), forKey: "medicationId")
            obj.setValue(UUID(), forKey: "timeId")
            obj.setValue(now, forKey: "date")
            obj.setValue(now, forKey: "completedAt")
            obj.setValue(profile, forKey: "profile")

        case .routineItem:
            obj.setValue("Test Routine", forKey: "label")
            obj.setValue(now, forKey: "time")
            obj.setValue("care", forKey: "category")
            obj.setValue(true, forKey: "isEnabled")
            obj.setValue(0, forKey: "sortOrder")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .weightGoal:
            obj.setValue(12.0, forKey: "targetWeightKg")
            obj.setValue(8.5, forKey: "startWeightKg")
            obj.setValue(now, forKey: "startDate")
            let targetDate = Calendar.current.date(byAdding: .month, value: 3, to: now)!
            obj.setValue(targetDate, forKey: "targetDate")
            obj.setValue(true, forKey: "isActive")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .bodyConditionScore:
            obj.setValue(5, forKey: "score")
            obj.setValue("Test BCS assessment", forKey: "note")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .groomingActivity:
            obj.setValue("brushing", forKey: "type")
            obj.setValue(7, forKey: "intervalDays")
            obj.setValue(now, forKey: "lastCompleted")
            obj.setValue(true, forKey: "isEnabled")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .enrichmentActivity:
            obj.setValue("puzzle", forKey: "type")
            obj.setValue(now, forKey: "completedAt")
            obj.setValue(15, forKey: "durationMinutes")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .skillProgress:
            obj.setValue("sit", forKey: "skillId")
            obj.setValue("learning", forKey: "phase")
            obj.setValue(1, forKey: "durationLevel")
            obj.setValue(1, forKey: "distanceLevel")
            obj.setValue(1, forKey: "distractionLevel")
            obj.setValue(0.5, forKey: "confidenceScore")
            obj.setValue(10, forKey: "totalSuccessReps")
            obj.setValue(2, forKey: "totalFailedReps")
            obj.setValue(now, forKey: "lastPracticedAt")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .masteredSkill:
            obj.setValue("down", forKey: "skillId")
            obj.setValue(now, forKey: "masteredAt")
            obj.setValue(profile, forKey: "profile")

        case .regressionLog:
            obj.setValue("stay", forKey: "skillId")
            obj.setValue(now, forKey: "occurredAt")
            obj.setValue(2, forKey: "previousTier")
            obj.setValue(0.6, forKey: "successRateAtFailure")
            obj.setValue(now, forKey: "createdAt")
            // RegressionLog doesn't have profile relationship

        case .exploredTile:
            obj.setValue("52.3676_4.9041_16", forKey: "tileKey")
            obj.setValue(1, forKey: "walkCount")
            obj.setValue(now, forKey: "firstExploredAt")
            obj.setValue(now, forKey: "lastExploredAt")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .userIdentity:
            obj.setValue("Test User", forKey: "name")
            obj.setValue("#FF5733", forKey: "colorHex")
            obj.setValue("primary", forKey: "responsibilityLevel")
            obj.setValue(now, forKey: "createdAt")
            obj.setValue(profile, forKey: "profile")

        case .userSentimentCheckIn:
            obj.setValue("general", forKey: "category")
            obj.setValue(4, forKey: "score")
            obj.setValue(now, forKey: "date")
            obj.setValue(now, forKey: "createdAt")
            if let identity = userIdentity {
                obj.setValue(identity, forKey: "userIdentity")
            }
        }

        return obj
    }

    /// Create all additional test entities (beyond profile/events/weight)
    @discardableResult
    public static func createAllTestEntities(
        in context: NSManagedObjectContext,
        for profile: NSManagedObject
    ) -> [TestEntityID: NSManagedObject] {
        var entities: [TestEntityID: NSManagedObject] = [:]

        // Create UserIdentity first since UserSentimentCheckIn depends on it
        var userIdentity: NSManagedObject?

        for entityType in TestEntityID.allCases {
            if entityType == .userIdentity {
                let identity = createTestEntity(entityType, in: context, for: profile)
                userIdentity = identity
                entities[entityType] = identity
            } else if entityType == .userSentimentCheckIn {
                let checkIn = createTestEntity(entityType, in: context, for: profile, userIdentity: userIdentity)
                entities[entityType] = checkIn
            } else {
                entities[entityType] = createTestEntity(entityType, in: context, for: profile)
            }
        }

        return entities
    }

    // MARK: - Photo Event (for photo sync testing)

    /// Create a test event with a photo for photo sync testing
    @discardableResult
    public static func createTestPhotoEvent(
        in context: NSManagedObjectContext,
        for profile: NSManagedObject,
        photoFilename: String? = nil
    ) -> NSManagedObject {
        let entityName = "CDPuppyEvent"
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        let event = NSManagedObject(entity: entity, insertInto: context)
        let now = Date()

        event.setValue(testPhotoEventID, forKey: "id")
        event.setValue("moment", forKey: "type")
        event.setValue(now, forKey: "time")
        event.setValue(now, forKey: "createdAt")
        event.setValue(now, forKey: "modifiedAt")
        event.setValue(profile, forKey: "profile")
        event.setValue("Test photo for sync testing", forKey: "note")

        if let filename = photoFilename {
            event.setValue(filename, forKey: "photo")
        }

        return event
    }

    #if os(iOS)
    /// Create a test photo event with an actual test image file saved to disk
    /// - Returns: Tuple of (event, localPhotoURL) for photo upload testing
    public static func createTestPhotoEventWithImage(
        in context: NSManagedObjectContext,
        for profile: NSManagedObject
    ) -> (event: NSManagedObject, photoURL: URL)? {
        // Create the test image data
        guard let imageData = createTestImageData() else {
            print("[SyncTestFixtures] Failed to create test image data")
            return nil
        }

        // Save to media directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[SyncTestFixtures] Failed to get documents directory")
            return nil
        }

        let mediaDir = documentsURL.appendingPathComponent("Media", isDirectory: true)

        // Ensure directory exists
        do {
            try FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        } catch {
            print("[SyncTestFixtures] Failed to create media directory: \(error)")
            return nil
        }

        // Use predictable filename based on test event ID
        let filename = "test-photo-\(testPhotoEventID.uuidString).png"
        let photoURL = mediaDir.appendingPathComponent(filename)

        // Save image data
        do {
            try imageData.write(to: photoURL)
        } catch {
            print("[SyncTestFixtures] Failed to save test image: \(error)")
            return nil
        }

        // Create the event with the photo path
        let relativePath = "Media/\(filename)"
        let event = createTestPhotoEvent(in: context, for: profile, photoFilename: relativePath)

        return (event, photoURL)
    }

    /// Check if test photo event exists
    public static func testPhotoEventExists(in context: NSManagedObjectContext) -> Bool {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyEvent")
        fetch.predicate = NSPredicate(format: "id == %@", testPhotoEventID as CVarArg)
        fetch.fetchLimit = 1

        do {
            return try context.count(for: fetch) > 0
        } catch {
            return false
        }
    }

    /// Get the local URL for the test photo file
    public static func testPhotoLocalURL() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let filename = "test-photo-\(testPhotoEventID.uuidString).png"
        return documentsURL.appendingPathComponent("Media/\(filename)")
    }

    /// Delete test photo file from local storage
    public static func deleteTestPhotoFile() {
        guard let photoURL = testPhotoLocalURL() else { return }
        try? FileManager.default.removeItem(at: photoURL)
    }
    #endif

    // MARK: - Full Test Data Set

    /// Create a complete test data set (profile + events + weight)
    /// - Parameter context: Core Data context
    /// - Returns: Tuple with profile and all created events
    public static func createFullTestDataSet(
        in context: NSManagedObjectContext
    ) -> (profile: NSManagedObject, events: [NSManagedObject], weight: NSManagedObject) {
        let profile = createTestProfile(in: context)
        let events = createTestEvents(in: context, for: profile)
        let weight = createTestWeight(in: context, for: profile)
        return (profile, events, weight)
    }

    // MARK: - Cleanup

    /// Delete all test data (identified by TEST0000 prefix in IDs)
    public static func deleteAllTestData(in context: NSManagedObjectContext) {
        // Delete test profile (cascade will delete related entities)
        let profileFetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")
        profileFetch.predicate = NSPredicate(format: "id == %@", testProfileID as CVarArg)

        do {
            let profiles = try context.fetch(profileFetch)
            for profile in profiles {
                context.delete(profile)
            }
        } catch {
            print("[SyncTestFixtures] Failed to delete test profiles: \(error)")
        }

        // Also delete any orphaned test events
        let eventFetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyEvent")
        let testEventIDs = TestEventID.allCases.map { $0.uuid }
        eventFetch.predicate = NSPredicate(format: "id IN %@", testEventIDs as NSArray)

        do {
            let events = try context.fetch(eventFetch)
            for event in events {
                context.delete(event)
            }
        } catch {
            print("[SyncTestFixtures] Failed to delete test events: \(error)")
        }

        // Delete all additional test entities
        for entityType in TestEntityID.allCases {
            deleteTestEntity(entityType, in: context)
        }

        // Delete test milestone
        let milestoneFetch = NSFetchRequest<NSManagedObject>(entityName: "CDMilestone")
        milestoneFetch.predicate = NSPredicate(format: "id == %@", testMilestoneID as CVarArg)
        do {
            let milestones = try context.fetch(milestoneFetch)
            for milestone in milestones {
                context.delete(milestone)
            }
        } catch {
            print("[SyncTestFixtures] Failed to delete test milestone: \(error)")
        }
    }

    /// Delete a specific test entity type
    public static func deleteTestEntity(_ entityType: TestEntityID, in context: NSManagedObjectContext) {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: entityType.entityName)
        fetch.predicate = NSPredicate(format: "id == %@", entityType.uuid as CVarArg)

        do {
            let entities = try context.fetch(fetch)
            for entity in entities {
                context.delete(entity)
            }
        } catch {
            print("[SyncTestFixtures] Failed to delete test \(entityType.entityName): \(error)")
        }
    }

    // MARK: - Verification

    /// Check if test profile exists in Core Data
    public static func testProfileExists(in context: NSManagedObjectContext) -> Bool {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")
        fetch.predicate = NSPredicate(format: "id == %@", testProfileID as CVarArg)
        fetch.fetchLimit = 1

        do {
            let count = try context.count(for: fetch)
            return count > 0
        } catch {
            return false
        }
    }

    /// Get count of test events in Core Data
    public static func testEventCount(in context: NSManagedObjectContext) -> Int {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyEvent")
        let testEventIDs = TestEventID.allCases.map { $0.uuid }
        fetch.predicate = NSPredicate(format: "id IN %@", testEventIDs as NSArray)

        do {
            return try context.count(for: fetch)
        } catch {
            return 0
        }
    }

    /// Check if a specific test entity exists
    public static func testEntityExists(_ entityType: TestEntityID, in context: NSManagedObjectContext) -> Bool {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: entityType.entityName)
        fetch.predicate = NSPredicate(format: "id == %@", entityType.uuid as CVarArg)
        fetch.fetchLimit = 1

        do {
            return try context.count(for: fetch) > 0
        } catch {
            return false
        }
    }

    /// Get a map of which test entities exist
    public static func existingTestEntities(in context: NSManagedObjectContext) -> [TestEntityID: Bool] {
        var result: [TestEntityID: Bool] = [:]
        for entityType in TestEntityID.allCases {
            result[entityType] = testEntityExists(entityType, in: context)
        }
        return result
    }

    /// Get count of additional test entities that exist
    public static func additionalTestEntityCount(in context: NSManagedObjectContext) -> Int {
        TestEntityID.allCases.filter { testEntityExists($0, in: context) }.count
    }

    // MARK: - Log Filter Helpers

    /// Get log predicate for filtering test record logs only
    public static var testRecordLogPredicate: String {
        "subsystem==\"nl.jaapstronks.Otis\" AND message CONTAINS \"[AA000000]\""
    }

    /// Get shell command to stream test record logs
    public static var testLogStreamCommand: String {
        """
        xcrun simctl spawn booted log stream \\
          --predicate '\(testRecordLogPredicate)' \\
          --level debug
        """
    }

    // MARK: - Test Image Generation

    #if os(iOS)
    /// Create a small test image for photo sync testing
    /// Returns PNG data of a 100x100 colored square with "TEST" text
    public static func createTestImageData() -> Data? {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { ctx in
            // Red background
            UIColor.systemRed.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // White "TEST" text
            let text = "TEST" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.white,
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }

        return image.pngData()
    }
    #endif
}
#endif
