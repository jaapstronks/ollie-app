//
//  CloudKitSyncable.swift
//  Otis-app
//
//  Protocol for Core Data stores with CloudKit sync support.
//  Provides common patterns for remote change observation and error handling.
//

import Foundation
import CoreData
import Combine
import os
import OtisShared

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
        // PERF: Use RunLoop.main to ensure handling happens on NEXT runloop tick,
        // preventing "Publishing changes from within view updates" warnings
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: RunLoop.main)
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
    /// Last error that occurred
    var lastError: AppError? { get set }
}

extension ErrorTrackable {
    /// Clear the last error (call when user dismisses error banner)
    func clearError() {
        lastError = nil
    }

    /// Set an error using a message string (convenience method)
    func setError(_ message: String) {
        lastError = AppError(category: .save, message: message)
    }

    /// Set an error using an AppError
    func setError(_ error: AppError) {
        lastError = error
    }

    /// Set a not found error
    func setNotFoundError() {
        lastError = .notFound()
    }

    /// Set a save failed error
    func setSaveError() {
        lastError = .saveFailed()
    }

    /// Set a delete failed error
    func setDeleteError() {
        lastError = .deleteFailed()
    }
}

// MARK: - Profile Accessible Protocol

/// Protocol for stores that need profile access
/// Provides common patterns for profile-scoped operations
@MainActor
protocol ProfileAccessible: AnyObject {
    /// The profile store reference
    var profileStore: ProfileStore? { get set }

    /// Logger for logging profile access issues
    var logger: Logger { get }

    /// View context for Core Data operations
    var viewContext: NSManagedObjectContext { get }

    /// Called after profile store is set
    func performInitialLoad()
}

extension ProfileAccessible {
    /// Get the current profile ID
    var currentProfileId: UUID? {
        profileStore?.profile?.id
    }

    /// Get the current CDPuppyProfile from Core Data
    func getCurrentProfile() -> CDPuppyProfile? {
        guard let profileId = currentProfileId else {
            // Use debug level since this is expected during app startup before profile loads
            logger.debug("No profile available for operations")
            return nil
        }
        return CDPuppyProfile.fetch(byId: profileId, in: viewContext)
    }

    /// Set the profile store (for when it's not available at init time)
    func configureProfileStore(_ profileStore: ProfileStore) {
        self.profileStore = profileStore
        performInitialLoad()
    }
}

// MARK: - Base Store

/// Abstract base class for Core Data stores with CloudKit sync support.
/// Subclasses should override `performInitialLoad()` to load their data.
@Observable
@MainActor
class BaseStore: CloudKitSyncable, ErrorTrackable, CloudKitRefreshable {

    // MARK: - CloudKitSyncable

    @ObservationIgnored let persistenceController: PersistenceController
    @ObservationIgnored var cancellables = Set<AnyCancellable>()
    @ObservationIgnored let logger: Logger

    // MARK: - ErrorTrackable

    var lastError: AppError?

    // MARK: - Common State

    private(set) var isSyncing = false

    // MARK: - Init

    /// Initialize the base store
    /// - Parameters:
    ///   - persistenceController: The Core Data persistence controller
    ///   - logCategory: Category name for the logger (e.g., "ContactStore")
    init(persistenceController: PersistenceController = .shared, logCategory: String) {
        self.persistenceController = persistenceController
        self.logger = Logger.otis(category: logCategory)
        performInitialLoad()
        // PERF: Register with centralized coordinator instead of individual observer
        // This reduces 12+ simultaneous reactions to 1 coordinated response
        registerWithCoordinator(identifier: logCategory)
    }

    /// Register this store with the centralized CloudKit sync coordinator
    private func registerWithCoordinator(identifier: String) {
        CloudKitSyncCoordinator.shared.register(store: self, identifier: identifier)
    }

    // MARK: - Abstract Methods

    /// Override in subclass to load data from Core Data.
    /// Called during init and when remote changes are detected.
    func performInitialLoad() {
        fatalError("Subclass must override performInitialLoad()")
    }

    // MARK: - CloudKitSyncable

    func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change")
        performInitialLoad()
    }

    /// Sync data from CloudKit (refreshes context and reloads)
    func syncFromCloud() async {
        viewContext.refreshAllObjects()
        performInitialLoad()
    }

    // MARK: - CloudKitRefreshable

    /// Called by CloudKitSyncCoordinator when remote changes are detected
    func refreshFromCloud() async {
        await syncFromCloud()
    }

    /// Force sync with CloudKit
    func forceSync() async {
        await syncFromCloud()
    }

    /// Perform initial sync on app launch
    func initialSync() async {
        await syncFromCloud()
    }

    // MARK: - Save Operations

    /// Perform a save operation with error handling
    /// - Parameters:
    ///   - operation: Description of the operation for logging
    ///   - onSuccess: Closure to execute after successful save (update in-memory state)
    /// - Returns: `true` if save succeeded, `false` otherwise
    @discardableResult
    func performSave(operation: String, onSuccess: () -> Void) -> Bool {
        do {
            try persistenceController.save()
            onSuccess()
            lastError = nil
            logger.info("\(operation)")
            return true
        } catch {
            viewContext.rollback()
            setError(Strings.Common.saveFailed)
            logger.error("Failed to \(operation): \(error.localizedDescription)")
            return false
        }
    }

    /// Perform a delete operation with error handling
    /// - Parameters:
    ///   - operation: Description of the operation for logging
    ///   - onSuccess: Closure to execute after successful delete (update in-memory state)
    /// - Returns: `true` if delete succeeded, `false` otherwise
    @discardableResult
    func performDelete(operation: String, onSuccess: () -> Void) -> Bool {
        do {
            try persistenceController.save()
            onSuccess()
            lastError = nil
            logger.info("\(operation)")
            return true
        } catch {
            viewContext.rollback()
            setError(Strings.Common.deleteFailed)
            logger.error("Failed to \(operation): \(error.localizedDescription)")
            return false
        }
    }
}
