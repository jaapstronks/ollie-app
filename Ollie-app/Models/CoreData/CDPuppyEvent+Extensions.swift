//
//  CDPuppyEvent+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between PuppyEvent and CDPuppyEvent
//

import CoreData
import OllieShared

extension CDPuppyEvent {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from PuppyEvent struct
    func update(from event: PuppyEvent) {
        self.id = event.id
        self.time = event.time
        self.type = event.type.rawValue
        self.createdAt = event.createdAt
        self.modifiedAt = event.modifiedAt
        self.location = event.location?.rawValue
        self.note = event.note
        self.durationMin = Int32(event.durationMin ?? 0)
        self.who = event.who
        self.exercise = event.exercise
        self.result = event.result
        self.weightKg = event.weightKg ?? 0
        self.photo = event.photo
        self.video = event.video
        self.thumbnailPath = event.thumbnailPath
        self.cloudPhotoSynced = event.cloudPhotoSynced ?? false
        self.latitude = event.latitude ?? 0
        self.longitude = event.longitude ?? 0
        self.spotId = event.spotId
        self.spotName = event.spotName
        self.parentWalkId = event.parentWalkId
        self.sleepSessionId = event.sleepSessionId
    }

    /// Create a new CDPuppyEvent from a PuppyEvent struct
    static func create(from event: PuppyEvent, in context: NSManagedObjectContext) -> CDPuppyEvent {
        let cdEvent = CDPuppyEvent(context: context)
        cdEvent.update(from: event)
        return cdEvent
    }

    // MARK: - Convert to Swift Struct

    /// Convert to PuppyEvent struct
    func toPuppyEvent() -> PuppyEvent? {
        guard let id = self.id,
              let time = self.time,
              let typeString = self.type,
              let type = EventType(rawValue: typeString),
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        let location: EventLocation?
        if let locationString = self.location {
            location = EventLocation(rawValue: locationString)
        } else {
            location = nil
        }

        return PuppyEvent(
            id: id,
            time: time,
            type: type,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            location: location,
            note: self.note,
            who: self.who,
            exercise: self.exercise,
            result: self.result,
            durationMin: self.durationMin > 0 ? Int(self.durationMin) : nil,
            photo: self.photo,
            video: self.video,
            latitude: self.latitude != 0 ? self.latitude : nil,
            longitude: self.longitude != 0 ? self.longitude : nil,
            thumbnailPath: self.thumbnailPath,
            cloudPhotoSynced: self.cloudPhotoSynced,
            weightKg: self.weightKg != 0 ? self.weightKg : nil,
            spotId: self.spotId,
            spotName: self.spotName,
            parentWalkId: self.parentWalkId,
            sleepSessionId: self.sleepSessionId
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDPuppyEvent {

    /// Fetch all events for a specific date
    static func fetchEvents(for date: Date, in context: NSManagedObjectContext) -> [CDPuppyEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let request = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
        request.predicate = NSPredicate(format: "time >= %@ AND time < %@", startOfDay as CVarArg, endOfDay as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDPuppyEvent.time, ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch events in a date range
    static func fetchEvents(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> [CDPuppyEvent] {
        let request = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
        request.predicate = NSPredicate(format: "time >= %@ AND time <= %@", startDate as CVarArg, endDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDPuppyEvent.time, ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch event by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDPuppyEvent? {
        let request = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Fetch events by type
    static func fetchEvents(ofType type: EventType, in context: NSManagedObjectContext) -> [CDPuppyEvent] {
        let request = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
        request.predicate = NSPredicate(format: "type == %@", type.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDPuppyEvent.time, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch recent events (last N events)
    static func fetchRecentEvents(limit: Int, in context: NSManagedObjectContext) -> [CDPuppyEvent] {
        let request = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDPuppyEvent.time, ascending: false)]
        request.fetchLimit = limit

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch all events
    static func fetchAllEvents(in context: NSManagedObjectContext) -> [CDPuppyEvent] {
        let request = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDPuppyEvent.time, ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch events modified after a given date
    static func fetchEventsModified(after date: Date, in context: NSManagedObjectContext) -> [CDPuppyEvent] {
        let request = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
        request.predicate = NSPredicate(format: "modifiedAt > %@", date as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDPuppyEvent.modifiedAt, ascending: true)]

        return (try? context.fetch(request)) ?? []
    }
}
