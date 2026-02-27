//
//  CloudKitSyncable.swift
//  Ollie-app
//
//  Protocol for Core Data stores with CloudKit sync support.
//  Provides common patterns for remote change observation and error handling.
//

import Foundation
import CoreData
import Combine
import os

// MARK: - CloudKit Syncable Protocol

/// Protocol for stores that sync with CloudKit via Core Data
/// Provides common patterns for remote change observation
protocol CloudKitSyncable: AnyObject {
    /// The persistence controller for Core Data operations
    var persistenceController: PersistenceController { get }

    /// Set of cancellables for Combine subscriptions
    var cancellables: Set<AnyCancellable> { get set }

    /// Logger for the store
    var logger: Logger { get }

    /// Called when a remote change is detected from CloudKit
    func handleRemoteChange()

    /// The view context for Core Data operations
    var viewContext: NSManagedObjectContext { get }
}

// MARK: - Default Implementations

extension CloudKitSyncable {
    /// Default view context accessor
    var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    /// Set up the remote change observer for CloudKit sync
    /// Call this in your store's init()
    func setupRemoteChangeObserver() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)
    }

    /// Save changes to Core Data with error handling
    /// - Parameter operation: Description of the operation for logging
    /// - Returns: True if save succeeded, false otherwise
    @discardableResult
    func saveContext(operation: String) -> Bool {
        do {
            try persistenceController.save()
            return true
        } catch {
            viewContext.rollback()
            logger.error("Failed to \(operation): \(error.localizedDescription)")
            return false
        }
    }

    /// Save changes with error callback for UI display
    /// - Parameters:
    ///   - operation: Description of the operation for logging
    ///   - onError: Callback when save fails, receives error message
    /// - Returns: True if save succeeded, false otherwise
    @discardableResult
    func saveContext(operation: String, onError: (String) -> Void) -> Bool {
        do {
            try persistenceController.save()
            return true
        } catch {
            viewContext.rollback()
            logger.error("Failed to \(operation): \(error.localizedDescription)")
            onError(Strings.Common.saveFailed)
            return false
        }
    }
}

// MARK: - Error State Protocol

/// Protocol for stores that track and display error state
protocol ErrorTrackable: AnyObject {
    /// Last error that occurred (message and timestamp)
    var lastError: (message: String, date: Date)? { get set }
}

extension ErrorTrackable {
    /// Clear the last error (call when user dismisses error banner)
    func clearError() {
        lastError = nil
    }

    /// Set an error with the current timestamp
    func setError(_ message: String) {
        lastError = (message, Date())
    }
}
