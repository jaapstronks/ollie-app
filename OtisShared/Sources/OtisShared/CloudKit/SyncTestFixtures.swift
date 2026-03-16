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
