//
//  CDBodyConditionScore+Extensions.swift
//  Otis-app
//
//  Extensions for converting between BodyConditionScore and CDBodyConditionScore
//

@preconcurrency import CoreData
import OtisShared

// MARK: - StorableModel Conformance

extension BodyConditionScore: StorableModel {}

// MARK: - CDEntityConvertible Conformance

extension CDBodyConditionScore: CDEntityConvertible {
    typealias Model = BodyConditionScore

    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject] {
        fetchAllScores(in: context)
    }

    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<CDBodyConditionScore>(entityName: "CDBodyConditionScore")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    @discardableResult
    static func create(from score: BodyConditionScore, in context: NSManagedObjectContext) -> NSManagedObject {
        let cdScore = CDBodyConditionScore(context: context)
        cdScore.update(from: score)
        return cdScore
    }

    @discardableResult
    static func create(from score: BodyConditionScore, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDBodyConditionScore {
        let cdScore = CDBodyConditionScore(context: context)
        cdScore.update(from: score)
        cdScore.profile = profile
        return cdScore
    }

    func toModel() -> BodyConditionScore? {
        toBodyConditionScore()
    }
}

// MARK: - Core Data Operations

extension CDBodyConditionScore {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from BodyConditionScore struct
    func update(from bcs: BodyConditionScore) {
        self.id = bcs.id
        self.score = Int16(bcs.score)
        self.note = bcs.note
        self.createdAt = bcs.createdAt
        self.modifiedAt = Date()
    }

    // MARK: - Convert to Swift Struct

    /// Convert to BodyConditionScore struct
    func toBodyConditionScore() -> BodyConditionScore? {
        guard let id = self.id,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return BodyConditionScore(
            id: id,
            score: Int(self.score),
            note: self.note,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDBodyConditionScore {

    /// Fetch all scores sorted by created date (newest first)
    static func fetchAllScores(in context: NSManagedObjectContext) -> [CDBodyConditionScore] {
        let request = NSFetchRequest<CDBodyConditionScore>(entityName: "CDBodyConditionScore")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBodyConditionScore.createdAt, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch scores for a specific profile, sorted by created date (newest first)
    static func fetchScores(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDBodyConditionScore] {
        let request = NSFetchRequest<CDBodyConditionScore>(entityName: "CDBodyConditionScore")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBodyConditionScore.createdAt, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch the latest score for a profile
    static func fetchLatest(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDBodyConditionScore? {
        let request = NSFetchRequest<CDBodyConditionScore>(entityName: "CDBodyConditionScore")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBodyConditionScore.createdAt, ascending: false)]
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Fetch by ID (convenience method with correct return type)
    static func fetchScore(byId id: UUID, in context: NSManagedObjectContext) -> CDBodyConditionScore? {
        let request = NSFetchRequest<CDBodyConditionScore>(entityName: "CDBodyConditionScore")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Count all scores for a profile
    static func countScores(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDBodyConditionScore>(entityName: "CDBodyConditionScore")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return context.performAndWait {
            (try? context.count(for: request)) ?? 0
        }
    }

    /// Fetch all scores without a profile (for migration)
    static func fetchOrphanedScores(in context: NSManagedObjectContext) -> [CDBodyConditionScore] {
        let request = NSFetchRequest<CDBodyConditionScore>(entityName: "CDBodyConditionScore")
        request.predicate = NSPredicate(format: "profile == nil")
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }
}
