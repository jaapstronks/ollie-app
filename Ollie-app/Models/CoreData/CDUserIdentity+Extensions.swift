//
//  CDUserIdentity+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between UserIdentity and CDUserIdentity.
//  CDUserIdentity syncs to CloudKit shared zone so all family members
//  can see each other's names and avatars.
//

@preconcurrency import CoreData
import OtisShared

// MARK: - Core Data Operations

extension CDUserIdentity {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from UserIdentity struct
    func update(from identity: UserIdentity) {
        self.id = identity.id
        self.name = identity.name
        self.avatarData = identity.avatarData
        self.colorHex = identity.colorHex
        self.cloudKitUserRecordID = identity.cloudKitUserRecordID
        self.responsibilityLevel = identity.responsibilityLevel.rawValue
        self.enabledNudgesData = Self.encodeNudges(identity.enabledNudges)
        self.createdAt = identity.createdAt
        self.modifiedAt = identity.modifiedAt
    }

    // MARK: - Convert to Swift Struct

    /// Convert to UserIdentity struct
    func toUserIdentity() -> UserIdentity? {
        guard let id = self.id,
              let name = self.name,
              let colorHex = self.colorHex,
              let cloudKitUserRecordID = self.cloudKitUserRecordID,
              !cloudKitUserRecordID.isEmpty,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        // Decode responsibility level with fallback
        let level = ResponsibilityLevel(rawValue: self.responsibilityLevel ?? "caregiver") ?? .caregiver

        // Decode enabled nudges with fallback to level defaults
        let nudges = Self.decodeNudges(self.enabledNudgesData) ?? level.defaultEnabledNudges

        return UserIdentity(
            id: id,
            name: name,
            avatarData: self.avatarData,
            colorHex: colorHex,
            cloudKitUserRecordID: cloudKitUserRecordID,
            responsibilityLevel: level,
            enabledNudges: nudges,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }

    // MARK: - Nudge Encoding/Decoding

    private static func encodeNudges(_ nudges: Set<NudgeCategory>) -> Data? {
        try? JSONEncoder().encode(nudges)
    }

    private static func decodeNudges(_ data: Data?) -> Set<NudgeCategory>? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(Set<NudgeCategory>.self, from: data)
    }
}

// MARK: - Fetch Request Helpers

extension CDUserIdentity {

    /// Fetch all user identities
    static func fetchAll(in context: NSManagedObjectContext) -> [CDUserIdentity] {
        let request = NSFetchRequest<CDUserIdentity>(entityName: "CDUserIdentity")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDUserIdentity.modifiedAt, ascending: false)
        ]

        nonisolated(unsafe) var results: [CDUserIdentity] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch user identity by CloudKit record ID
    static func fetch(byCloudKitRecordID recordID: String, in context: NSManagedObjectContext) -> CDUserIdentity? {
        let request = NSFetchRequest<CDUserIdentity>(entityName: "CDUserIdentity")
        request.predicate = NSPredicate(format: "cloudKitUserRecordID == %@", recordID)
        request.fetchLimit = 1

        nonisolated(unsafe) var result: CDUserIdentity?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Fetch user identity by UUID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDUserIdentity? {
        let request = NSFetchRequest<CDUserIdentity>(entityName: "CDUserIdentity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        nonisolated(unsafe) var result: CDUserIdentity?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Create or update a user identity in Core Data
    @discardableResult
    static func upsert(_ identity: UserIdentity, in context: NSManagedObjectContext) -> CDUserIdentity {
        // First try to find by CloudKit record ID (the stable identifier)
        if let existing = fetch(byCloudKitRecordID: identity.cloudKitUserRecordID, in: context) {
            // Only update if incoming data is newer
            if identity.modifiedAt > (existing.modifiedAt ?? .distantPast) {
                existing.update(from: identity)
            }
            return existing
        }

        // Create new
        let cdIdentity = CDUserIdentity(context: context)
        cdIdentity.update(from: identity)
        return cdIdentity
    }

    /// Create or update a user identity linked to a profile (required for CloudKit sharing)
    @discardableResult
    static func upsert(_ identity: UserIdentity, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDUserIdentity {
        // First try to find by CloudKit record ID (the stable identifier)
        if let existing = fetch(byCloudKitRecordID: identity.cloudKitUserRecordID, in: context) {
            // Only update if incoming data is newer
            if identity.modifiedAt > (existing.modifiedAt ?? .distantPast) {
                existing.update(from: identity)
            }
            // Ensure profile link exists
            if existing.profile == nil {
                existing.profile = profile
            }
            return existing
        }

        // Create new, linked to profile
        let cdIdentity = CDUserIdentity(context: context)
        cdIdentity.update(from: identity)
        cdIdentity.profile = profile
        return cdIdentity
    }

    /// Fetch all user identities for a specific profile
    static func fetchAll(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDUserIdentity] {
        let request = NSFetchRequest<CDUserIdentity>(entityName: "CDUserIdentity")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDUserIdentity.modifiedAt, ascending: false)
        ]

        nonisolated(unsafe) var results: [CDUserIdentity] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch all orphaned user identities (not linked to a profile)
    /// Used for migration to link existing records to the profile
    static func fetchOrphaned(in context: NSManagedObjectContext) -> [CDUserIdentity] {
        let request = NSFetchRequest<CDUserIdentity>(entityName: "CDUserIdentity")
        request.predicate = NSPredicate(format: "profile == nil")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDUserIdentity.modifiedAt, ascending: false)
        ]

        nonisolated(unsafe) var results: [CDUserIdentity] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch all identities as UserIdentity structs
    static func fetchAllAsModels(in context: NSManagedObjectContext) -> [UserIdentity] {
        fetchAll(in: context).compactMap { $0.toUserIdentity() }
    }
}
