//
//  CDMedicationCompletion+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between MedicationCompletion and CDMedicationCompletion
//

import CoreData
import OllieShared

extension CDMedicationCompletion {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from MedicationCompletion struct
    func update(from completion: MedicationCompletion) {
        self.id = completion.id
        self.medicationId = completion.medicationId
        self.timeId = completion.timeId
        self.date = completion.date
        self.completedAt = completion.completedAt
        self.modifiedAt = completion.modifiedAt
    }

    /// Create a new CDMedicationCompletion from a MedicationCompletion struct
    static func create(from completion: MedicationCompletion, in context: NSManagedObjectContext) -> CDMedicationCompletion {
        let cdCompletion = CDMedicationCompletion(context: context)
        cdCompletion.update(from: completion)
        return cdCompletion
    }

    // MARK: - Convert to Swift Struct

    /// Convert to MedicationCompletion struct
    func toMedicationCompletion() -> MedicationCompletion? {
        guard let id = self.id,
              let medicationId = self.medicationId,
              let timeId = self.timeId,
              let date = self.date,
              let completedAt = self.completedAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return MedicationCompletion(
            id: id,
            medicationId: medicationId,
            timeId: timeId,
            date: date,
            completedAt: completedAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDMedicationCompletion {

    /// Fetch all completions
    static func fetchAllCompletions(in context: NSManagedObjectContext) -> [CDMedicationCompletion] {
        let request = NSFetchRequest<CDMedicationCompletion>(entityName: "CDMedicationCompletion")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMedicationCompletion.completedAt, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch completions for a specific date
    static func fetchCompletions(for date: Date, in context: NSManagedObjectContext) -> [CDMedicationCompletion] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let request = NSFetchRequest<CDMedicationCompletion>(entityName: "CDMedicationCompletion")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMedicationCompletion.completedAt, ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch completion by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDMedicationCompletion? {
        let request = NSFetchRequest<CDMedicationCompletion>(entityName: "CDMedicationCompletion")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Fetch completions for a specific medication
    static func fetchCompletions(forMedication medicationId: UUID, in context: NSManagedObjectContext) -> [CDMedicationCompletion] {
        let request = NSFetchRequest<CDMedicationCompletion>(entityName: "CDMedicationCompletion")
        request.predicate = NSPredicate(format: "medicationId == %@", medicationId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMedicationCompletion.completedAt, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Check if a specific dose was completed
    static func isCompleted(medicationId: UUID, timeId: UUID, date: Date, in context: NSManagedObjectContext) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }

        let request = NSFetchRequest<CDMedicationCompletion>(entityName: "CDMedicationCompletion")
        request.predicate = NSPredicate(
            format: "medicationId == %@ AND timeId == %@ AND date >= %@ AND date < %@",
            medicationId as CVarArg,
            timeId as CVarArg,
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        request.fetchLimit = 1

        return ((try? context.count(for: request)) ?? 0) > 0
    }
}
