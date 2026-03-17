//
//  CDMilestone+Extensions.swift
//  Otis-app
//
//  Extensions for converting between Milestone and CDMilestone

@preconcurrency import CoreData
import OtisShared

// MARK: - CDEntityConvertible Conformance

extension CDMilestone: CDEntityConvertible {
    typealias Model = Milestone

    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject] {
        fetchAllMilestones(in: context)
    }

    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        nonisolated(unsafe) var result: CDMilestone?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    @discardableResult
    static func create(from milestone: Milestone, in context: NSManagedObjectContext) -> NSManagedObject {
        let cdMilestone = CDMilestone(context: context)
        cdMilestone.update(from: milestone)
        return cdMilestone
    }

    /// Create a new CDMilestone linked to a profile (required for CloudKit sync)
    @discardableResult
    static func create(from milestone: Milestone, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDMilestone {
        let cdMilestone = CDMilestone(context: context)
        cdMilestone.update(from: milestone)
        cdMilestone.profile = profile
        return cdMilestone
    }

    func toModel() -> Milestone? {
        toMilestone()
    }
}

// MARK: - Core Data Operations

extension CDMilestone {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from Milestone struct
    func update(from milestone: Milestone) {
        self.id = milestone.id
        self.category = milestone.category.rawValue
        self.labelKey = milestone.labelKey
        self.detailKey = milestone.detailKey
        self.targetAgeWeeks = milestone.targetAgeWeeks.map { Int32($0) } ?? 0
        self.targetAgeDays = milestone.targetAgeDays.map { Int32($0) } ?? 0
        self.targetAgeMonths = milestone.targetAgeMonths.map { Int32($0) } ?? 0
        self.fixedDate = milestone.fixedDate
        self.isRecurring = milestone.isRecurring
        self.recurrenceMonths = milestone.recurrenceMonths.map { Int32($0) } ?? 0
        self.isCompleted = milestone.isCompleted
        self.completedDate = milestone.completedDate
        self.completionNotes = milestone.completionNotes
        self.completionPhotoID = milestone.completionPhotoID
        self.vetClinicName = milestone.vetClinicName
        self.linkedContactID = milestone.linkedContactID
        self.calendarEventID = milestone.calendarEventID
        self.reminderDaysBefore = Int32(milestone.reminderDaysBefore)
        self.icon = milestone.icon
        self.isActionable = milestone.isActionable
        self.isUserDismissable = milestone.isUserDismissable
        self.sortOrder = Int32(milestone.sortOrder)
        self.isCustom = milestone.isCustom
        self.createdAt = milestone.createdAt
        self.modifiedAt = Date()
    }


    // MARK: - Convert to Swift Struct

    /// Convert to Milestone struct
    func toMilestone() -> Milestone? {
        guard let id = self.id,
              let categoryString = self.category,
              let category = MilestoneCategory(rawValue: categoryString),
              let labelKey = self.labelKey,
              let icon = self.icon,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return Milestone(
            id: id,
            category: category,
            labelKey: labelKey,
            detailKey: self.detailKey,
            targetAgeWeeks: self.targetAgeWeeks > 0 ? Int(self.targetAgeWeeks) : nil,
            targetAgeDays: self.targetAgeDays > 0 ? Int(self.targetAgeDays) : nil,
            targetAgeMonths: self.targetAgeMonths > 0 ? Int(self.targetAgeMonths) : nil,
            fixedDate: self.fixedDate,
            isRecurring: self.isRecurring,
            recurrenceMonths: self.recurrenceMonths > 0 ? Int(self.recurrenceMonths) : nil,
            isCompleted: self.isCompleted,
            completedDate: self.completedDate,
            completionNotes: self.completionNotes,
            completionPhotoID: self.completionPhotoID,
            vetClinicName: self.vetClinicName,
            linkedContactID: self.linkedContactID,
            calendarEventID: self.calendarEventID,
            reminderDaysBefore: Int(self.reminderDaysBefore),
            icon: icon,
            isActionable: self.isActionable,
            isUserDismissable: self.isUserDismissable,
            sortOrder: Int(self.sortOrder),
            isCustom: self.isCustom,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDMilestone {

    /// Fetch all milestones sorted by sortOrder
    static func fetchAllMilestones(in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        nonisolated(unsafe) var results: [CDMilestone] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch milestones by category
    static func fetchMilestones(category: MilestoneCategory, in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        nonisolated(unsafe) var results: [CDMilestone] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch completed milestones
    static func fetchCompletedMilestones(in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.completedDate, ascending: false)]
        nonisolated(unsafe) var results: [CDMilestone] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch incomplete milestones
    static func fetchIncompleteMilestones(in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        nonisolated(unsafe) var results: [CDMilestone] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch custom milestones only
    static func fetchCustomMilestones(in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "isCustom == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        nonisolated(unsafe) var results: [CDMilestone] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Count all milestones
    static func countMilestones(in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        nonisolated(unsafe) var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count
    }

    /// Count completed milestones
    static func countCompletedMilestones(in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "isCompleted == YES")
        nonisolated(unsafe) var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count
    }

    /// Fetch all milestones for a specific profile
    static func fetchAllMilestones(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        nonisolated(unsafe) var results: [CDMilestone] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch all orphaned milestones (not linked to a profile)
    /// Used for migration to link existing records to the profile
    static func fetchOrphanedMilestones(in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "profile == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        nonisolated(unsafe) var results: [CDMilestone] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Count milestones for a specific profile
    static func countMilestones(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        nonisolated(unsafe) var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count
    }
}
