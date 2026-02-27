//
//  CDMilestone+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between Milestone and CDMilestone

import CoreData
import OllieShared

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

    /// Create a new CDMilestone from a Milestone struct
    static func create(from milestone: Milestone, in context: NSManagedObjectContext) -> CDMilestone {
        let cdMilestone = CDMilestone(context: context)
        cdMilestone.update(from: milestone)
        return cdMilestone
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
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch milestones by category
    static func fetchMilestones(category: MilestoneCategory, in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch completed milestones
    static func fetchCompletedMilestones(in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.completedDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch incomplete milestones
    static func fetchIncompleteMilestones(in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch milestone by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDMilestone? {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Fetch custom milestones only
    static func fetchCustomMilestones(in context: NSManagedObjectContext) -> [CDMilestone] {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "isCustom == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.sortOrder, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    /// Count all milestones
    static func countMilestones(in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        return (try? context.count(for: request)) ?? 0
    }

    /// Count completed milestones
    static func countCompletedMilestones(in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "isCompleted == YES")
        return (try? context.count(for: request)) ?? 0
    }
}
