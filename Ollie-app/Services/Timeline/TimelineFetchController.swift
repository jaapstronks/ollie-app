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

    /// Track whether any actual object changes occurred during this FRC update cycle.
    /// This prevents spurious notifications when context saves don't affect our fetched objects.
    private var hasPendingChanges = false

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

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        hasPendingChanges = false
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        // Only care about structural changes (insert/delete/move), not updates.
        // Updates are often just CloudKit sync touching modifiedAt timestamps
        // without changing actual event data.
        switch type {
        case .insert, .delete, .move:
            hasPendingChanges = true
        case .update:
            // Skip - updates don't change the set of events, just their contents
            // and handleFetchedResultsChange() would reject them anyway
            break
        @unknown default:
            hasPendingChanges = true
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Only notify if actual objects changed (not just context noise)
        guard hasPendingChanges else {
            return
        }
        logger.debug("FRC detected changes - notifying EventStore")
        onContentChange?()
    }
}
