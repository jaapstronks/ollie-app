//
//  CDDogAppointment+Extensions.swift
//  Otis-app
//
//  Extensions for converting between DogAppointment and CDDogAppointment

@preconcurrency import CoreData
import OtisShared
import Foundation

extension CDDogAppointment {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from DogAppointment struct
    func update(from appointment: DogAppointment) {
        self.id = appointment.id
        self.title = appointment.title
        self.appointmentType = appointment.appointmentType.rawValue
        self.startDate = appointment.startDate
        self.endDate = appointment.endDate
        self.isAllDay = appointment.isAllDay
        self.location = appointment.location
        self.notes = appointment.notes
        self.reminderMinutesBefore = Int16(appointment.reminderMinutesBefore)

        // Recurrence
        if let recurrence = appointment.recurrence {
            self.recurrenceFrequency = recurrence.frequency.rawValue
            self.recurrenceInterval = Int16(recurrence.interval)
            self.recurrenceEndDate = recurrence.endDate
            self.recurrenceCount = Int16(recurrence.occurrenceCount ?? 0)
            if let days = recurrence.daysOfWeek {
                self.recurrenceDaysOfWeek = days.map { String($0) }.joined(separator: ",")
            } else {
                self.recurrenceDaysOfWeek = nil
            }
        } else {
            self.recurrenceFrequency = nil
            self.recurrenceInterval = 1
            self.recurrenceEndDate = nil
            self.recurrenceCount = 0
            self.recurrenceDaysOfWeek = nil
        }

        // Linking
        self.linkedMilestoneID = appointment.linkedMilestoneID
        self.linkedContactID = appointment.linkedContactID
        self.linkedGroomingType = appointment.linkedGroomingType?.rawValue
        self.calendarEventID = appointment.calendarEventID

        // Completion
        self.isCompleted = appointment.isCompleted
        self.completionNotes = appointment.completionNotes

        // Timestamps
        self.createdAt = appointment.createdAt
        self.modifiedAt = Date()
    }

    /// Create a new CDDogAppointment from a DogAppointment struct
    static func create(
        from appointment: DogAppointment,
        profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> CDDogAppointment {
        let entity = CDDogAppointment(context: context)
        entity.update(from: appointment)
        entity.profile = profile
        return entity
    }

    // MARK: - Convert to Swift Struct

    /// Convert to DogAppointment struct
    func toAppointment() -> DogAppointment? {
        guard let id = self.id,
              let title = self.title,
              let typeString = self.appointmentType,
              let appointmentType = AppointmentType(rawValue: typeString),
              let startDate = self.startDate,
              let endDate = self.endDate,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        // Parse recurrence
        var recurrence: RecurrenceRule? = nil
        if let freqString = self.recurrenceFrequency,
           let frequency = RecurrenceRule.Frequency(rawValue: freqString) {

            var daysOfWeek: [Int]? = nil
            if let daysString = self.recurrenceDaysOfWeek, !daysString.isEmpty {
                daysOfWeek = daysString.split(separator: ",").compactMap { Int($0) }
            }

            recurrence = RecurrenceRule(
                frequency: frequency,
                interval: Int(self.recurrenceInterval),
                daysOfWeek: daysOfWeek,
                endDate: self.recurrenceEndDate,
                occurrenceCount: self.recurrenceCount > 0 ? Int(self.recurrenceCount) : nil
            )
        }

        // Parse linkedGroomingType
        var linkedGroomingType: GroomingType? = nil
        if let groomingTypeString = self.linkedGroomingType {
            linkedGroomingType = GroomingType(rawValue: groomingTypeString)
        }

        return DogAppointment(
            id: id,
            title: title,
            appointmentType: appointmentType,
            startDate: startDate,
            endDate: endDate,
            isAllDay: self.isAllDay,
            location: self.location,
            notes: self.notes,
            reminderMinutesBefore: Int(self.reminderMinutesBefore),
            recurrence: recurrence,
            linkedMilestoneID: self.linkedMilestoneID,
            linkedContactID: self.linkedContactID,
            linkedGroomingType: linkedGroomingType,
            calendarEventID: self.calendarEventID,
            isCompleted: self.isCompleted,
            completionNotes: self.completionNotes,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDDogAppointment {

    /// Fetch all appointments for a profile sorted by start date (upcoming first)
    static func fetchAppointments(
        for profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> [CDDogAppointment] {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDDogAppointment.startDate, ascending: true)
        ]
        nonisolated(unsafe) var results: [CDDogAppointment] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch upcoming appointments for a profile
    static func fetchUpcomingAppointments(
        for profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> [CDDogAppointment] {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(
            format: "profile == %@ AND startDate >= %@",
            profile,
            Date() as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDDogAppointment.startDate, ascending: true)
        ]
        nonisolated(unsafe) var results: [CDDogAppointment] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch past appointments for a profile
    static func fetchPastAppointments(
        for profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> [CDDogAppointment] {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(
            format: "profile == %@ AND endDate < %@",
            profile,
            Date() as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDDogAppointment.startDate, ascending: false)
        ]
        nonisolated(unsafe) var results: [CDDogAppointment] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch appointments for a specific date
    static func fetchAppointments(
        for profile: CDPuppyProfile,
        on date: Date,
        in context: NSManagedObjectContext
    ) -> [CDDogAppointment] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(
            format: "profile == %@ AND startDate >= %@ AND startDate < %@",
            profile,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDDogAppointment.startDate, ascending: true)
        ]
        nonisolated(unsafe) var results: [CDDogAppointment] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch appointment by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDDogAppointment? {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        nonisolated(unsafe) var result: CDDogAppointment?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Fetch appointments linked to a specific milestone
    static func fetchAppointments(
        linkedToMilestoneId milestoneId: UUID,
        in context: NSManagedObjectContext
    ) -> [CDDogAppointment] {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(format: "linkedMilestoneID == %@", milestoneId as CVarArg)
        nonisolated(unsafe) var results: [CDDogAppointment] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch appointments linked to a specific contact
    static func fetchAppointments(
        linkedToContactId contactId: UUID,
        in context: NSManagedObjectContext
    ) -> [CDDogAppointment] {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(format: "linkedContactID == %@", contactId as CVarArg)
        nonisolated(unsafe) var results: [CDDogAppointment] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Count all appointments for a profile
    static func countAppointments(
        for profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> Int {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        nonisolated(unsafe) var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count
    }

    /// Count upcoming appointments for a profile
    static func countUpcomingAppointments(
        for profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> Int {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(
            format: "profile == %@ AND startDate >= %@",
            profile,
            Date() as NSDate
        )
        nonisolated(unsafe) var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count
    }

    /// Fetch all appointments for migration (no profile filter)
    static func fetchAllAppointmentsForMigration(
        in context: NSManagedObjectContext
    ) -> [CDDogAppointment] {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDDogAppointment.startDate, ascending: true)
        ]
        nonisolated(unsafe) var results: [CDDogAppointment] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }
}
