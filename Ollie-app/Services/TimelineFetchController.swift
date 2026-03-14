//
//  TimelineFetchController.swift
//  Ollie-app
//
//  Manages NSFetchedResultsController for efficient single-day event queries.
//  Uses FRC's incremental updates instead of full reloads when events change.
//

@preconcurrency import CoreData
import Foundation
import os
import OtisShared

/// Manages NSFetchedResultsController for efficient single-day event queries
final class TimelineFetchController: NSObject, @unchecked Sendable {

    private var fetchedResultsController: NSFetchedResultsController<CDPuppyEvent>?
    private let context: NSManagedObjectContext
    private let logger = Logger.otis(category: "TimelineFetchController")

    private(set) var currentDate: Date = Date()
    private(set) var activeProfile: CDPuppyProfile?

    /// Callback when fetched results change (insert/delete/update/move)
    var onContentChange: (() -> Void)?

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
    }

    /// Configure FRC for a specific date and profile
    func configure(for date: Date, profile: CDPuppyProfile?) {
        currentDate = date
        activeProfile = profile

        let request = createFetchRequest(for: date, profile: profile)

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil  // No cache - date changes frequently
        )
        fetchedResultsController?.delegate = self
    }

    /// Execute the fetch
    func performFetch() throws {
        try fetchedResultsController?.performFetch()
    }

    /// Get fetched events as Swift structs
    var fetchedEvents: [PuppyEvent] {
        guard let objects = fetchedResultsController?.fetchedObjects else {
            return []
        }
        return objects.compactMap { $0.toPuppyEvent() }
    }

    private func createFetchRequest(for date: Date, profile: CDPuppyProfile?) -> NSFetchRequest<CDPuppyEvent> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<CDPuppyEvent> = CDPuppyEvent.fetchRequest()
        request.fetchBatchSize = 50
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]

        if let profile = profile {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "profile == %@", profile),
                NSPredicate(format: "time >= %@ AND time < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            ])
        } else {
            request.predicate = NSPredicate(format: "time >= %@ AND time < %@", startOfDay as CVarArg, endOfDay as CVarArg)
        }

        return request
    }
}

extension TimelineFetchController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        logger.debug("FRC detected changes - notifying EventStore")
        onContentChange?()
    }
}
