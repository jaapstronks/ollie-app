//
//  CDUserSentimentCheckIn+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between SentimentCheckIn and CDUserSentimentCheckIn.
//  User-specific sentiment check-ins sync to CloudKit via the CDUserIdentity relationship.
//

@preconcurrency import CoreData

// MARK: - Core Data Operations

extension CDUserSentimentCheckIn {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from SentimentCheckIn struct
    func update(from checkIn: SentimentCheckIn) {
        self.id = checkIn.id
        self.category = checkIn.category.rawValue
        self.score = Int16(checkIn.score)
        self.contextSummary = checkIn.contextSummary
        self.date = checkIn.date
        self.createdAt = checkIn.date
        self.modifiedAt = Date()
    }

    // MARK: - Convert to Swift Struct

    /// Convert to SentimentCheckIn struct
    func toSentimentCheckIn() -> SentimentCheckIn? {
        guard let id = self.id,
              let categoryRaw = self.category,
              let category = SentimentCategory(rawValue: categoryRaw),
              let date = self.date else {
            return nil
        }

        return SentimentCheckIn(
            id: id,
            category: category,
            score: Int(self.score),
            date: date,
            contextSummary: self.contextSummary
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDUserSentimentCheckIn {

    /// Fetch all sentiment check-ins for a user identity
    static func fetchAll(for userIdentity: CDUserIdentity, in context: NSManagedObjectContext) -> [CDUserSentimentCheckIn] {
        let request = NSFetchRequest<CDUserSentimentCheckIn>(entityName: "CDUserSentimentCheckIn")
        request.predicate = NSPredicate(format: "userIdentity == %@", userIdentity)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDUserSentimentCheckIn.date, ascending: false)
        ]

        nonisolated(unsafe) var results: [CDUserSentimentCheckIn] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch the latest check-in for a category for a user
    static func fetchLatest(
        for category: SentimentCategory,
        userIdentity: CDUserIdentity,
        in context: NSManagedObjectContext
    ) -> CDUserSentimentCheckIn? {
        let request = NSFetchRequest<CDUserSentimentCheckIn>(entityName: "CDUserSentimentCheckIn")
        request.predicate = NSPredicate(
            format: "userIdentity == %@ AND category == %@",
            userIdentity,
            category.rawValue
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDUserSentimentCheckIn.date, ascending: false)
        ]
        request.fetchLimit = 1

        nonisolated(unsafe) var result: CDUserSentimentCheckIn?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Fetch all check-ins for a user by CloudKit record ID
    static func fetchAll(
        forCloudKitRecordID recordID: String,
        in context: NSManagedObjectContext
    ) -> [CDUserSentimentCheckIn] {
        guard let cdIdentity = CDUserIdentity.fetch(byCloudKitRecordID: recordID, in: context) else {
            return []
        }
        return fetchAll(for: cdIdentity, in: context)
    }

    /// Create or update a sentiment check-in for a user
    @discardableResult
    static func upsert(
        _ checkIn: SentimentCheckIn,
        for userIdentity: CDUserIdentity,
        in context: NSManagedObjectContext
    ) -> CDUserSentimentCheckIn {
        // Check for existing check-in for this category
        if let existing = fetchLatest(for: checkIn.category, userIdentity: userIdentity, in: context) {
            // Always update with newer data (latest check-in replaces previous)
            existing.update(from: checkIn)
            return existing
        }

        // Create new
        let cdCheckIn = CDUserSentimentCheckIn(context: context)
        cdCheckIn.update(from: checkIn)
        cdCheckIn.userIdentity = userIdentity
        return cdCheckIn
    }

    /// Fetch all check-ins as SentimentCheckIn structs mapped by category
    static func fetchAllAsMap(
        for userIdentity: CDUserIdentity,
        in context: NSManagedObjectContext
    ) -> [SentimentCategory: SentimentCheckIn] {
        let cdCheckIns = fetchAll(for: userIdentity, in: context)
        var result: [SentimentCategory: SentimentCheckIn] = [:]

        for cd in cdCheckIns {
            if let checkIn = cd.toSentimentCheckIn() {
                // Only keep the latest per category (they're sorted desc by date)
                if result[checkIn.category] == nil {
                    result[checkIn.category] = checkIn
                }
            }
        }

        return result
    }
}
