//
//  CDEarlyMilestone+Extensions.swift
//  Otis-app
//
//  Extensions for converting between EarlyMilestoneRecord and CDEarlyMilestone
//

import CoreData
import OtisShared

extension CDEarlyMilestone {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from EarlyMilestoneRecord struct
    func update(from milestone: EarlyMilestoneRecord) {
        self.id = milestone.id
        self.milestoneId = milestone.milestoneId
        self.achievedAt = milestone.achievedAt
        self.modifiedAt = milestone.modifiedAt
    }

    /// Create a new CDEarlyMilestone from an EarlyMilestoneRecord struct
    static func create(from milestone: EarlyMilestoneRecord, in context: NSManagedObjectContext) -> CDEarlyMilestone {
        let cdMilestone = CDEarlyMilestone(context: context)
        cdMilestone.update(from: milestone)
        return cdMilestone
    }

    // MARK: - Convert to Swift Struct

    /// Convert to EarlyMilestoneRecord struct
    func toEarlyMilestoneRecord() -> EarlyMilestoneRecord? {
        guard let id = self.id,
              let milestoneId = self.milestoneId,
              let achievedAt = self.achievedAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return EarlyMilestoneRecord(
            id: id,
            milestoneId: milestoneId,
            achievedAt: achievedAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDEarlyMilestone {

    /// Fetch all early milestones
    static func fetchAll(in context: NSManagedObjectContext) -> [CDEarlyMilestone] {
        let request = NSFetchRequest<CDEarlyMilestone>(entityName: "CDEarlyMilestone")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDEarlyMilestone.achievedAt, ascending: true)]

        var results: [CDEarlyMilestone] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch by milestone ID
    static func fetch(byMilestoneId milestoneId: String, in context: NSManagedObjectContext) -> CDEarlyMilestone? {
        let request = NSFetchRequest<CDEarlyMilestone>(entityName: "CDEarlyMilestone")
        request.predicate = NSPredicate(format: "milestoneId == %@", milestoneId)
        request.fetchLimit = 1
        var result: CDEarlyMilestone?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Check if a milestone is achieved
    static func isAchieved(_ milestoneId: String, in context: NSManagedObjectContext) -> Bool {
        let request = NSFetchRequest<CDEarlyMilestone>(entityName: "CDEarlyMilestone")
        request.predicate = NSPredicate(format: "milestoneId == %@", milestoneId)
        request.fetchLimit = 1

        var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count > 0
    }

    /// Delete milestone by milestoneId
    static func delete(byMilestoneId milestoneId: String, in context: NSManagedObjectContext) {
        context.performAndWait {
            if let existing = fetch(byMilestoneId: milestoneId, in: context) {
                context.delete(existing)
            }
        }
    }
}
