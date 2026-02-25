//
//  CDMasteredSkill+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between MasteredSkill and CDMasteredSkill
//

import CoreData
import OllieShared

extension CDMasteredSkill {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from MasteredSkill struct
    func update(from skill: MasteredSkill) {
        self.id = skill.id
        self.skillId = skill.skillId
        self.masteredAt = skill.masteredAt
        self.modifiedAt = skill.modifiedAt
    }

    /// Create a new CDMasteredSkill from a MasteredSkill struct
    static func create(from skill: MasteredSkill, in context: NSManagedObjectContext) -> CDMasteredSkill {
        let cdSkill = CDMasteredSkill(context: context)
        cdSkill.update(from: skill)
        return cdSkill
    }

    // MARK: - Convert to Swift Struct

    /// Convert to MasteredSkill struct
    func toMasteredSkill() -> MasteredSkill? {
        guard let id = self.id,
              let skillId = self.skillId,
              let masteredAt = self.masteredAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return MasteredSkill(
            id: id,
            skillId: skillId,
            masteredAt: masteredAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDMasteredSkill {

    /// Fetch all mastered skills
    static func fetchAllSkills(in context: NSManagedObjectContext) -> [CDMasteredSkill] {
        let request = NSFetchRequest<CDMasteredSkill>(entityName: "CDMasteredSkill")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMasteredSkill.masteredAt, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch skill by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDMasteredSkill? {
        let request = NSFetchRequest<CDMasteredSkill>(entityName: "CDMasteredSkill")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Fetch skill by skillId
    static func fetch(bySkillId skillId: String, in context: NSManagedObjectContext) -> CDMasteredSkill? {
        let request = NSFetchRequest<CDMasteredSkill>(entityName: "CDMasteredSkill")
        request.predicate = NSPredicate(format: "skillId == %@", skillId)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Check if a skill is mastered
    static func isSkillMastered(_ skillId: String, in context: NSManagedObjectContext) -> Bool {
        let request = NSFetchRequest<CDMasteredSkill>(entityName: "CDMasteredSkill")
        request.predicate = NSPredicate(format: "skillId == %@", skillId)
        request.fetchLimit = 1

        return ((try? context.count(for: request)) ?? 0) > 0
    }
}
