//
//  PersistenceController.swift
//  Ollie-app
//
//  Core Data persistence with NSPersistentCloudKitContainer for automatic CloudKit sync.
//  Uses two-store architecture: private store for owner data, shared store for participant data.
//
//  IMPORTANT: Includes iCloud availability checking and fallback to local-only storage
//  to protect against data loss when iCloud becomes unavailable (iOS 18+ issue).
//

import CoreData
import CloudKit

/// Manages Core Data persistence with automatic CloudKit synchronization
final class PersistenceController: @unchecked Sendable {

    // MARK: - Singleton

    // nonisolated to allow use in default parameter values
    nonisolated(unsafe) static let shared = PersistenceController()

    // MARK: - Container

    let container: NSPersistentCloudKitContainer

    // MARK: - Store References

    private var privateStore: NSPersistentStore?
    private var sharedStore: NSPersistentStore?

    // MARK: - CloudKit Container Identifier

    private static let cloudKitContainerIdentifier = "iCloud.nl.jaapstronks.Ollie"
    private static let appGroupIdentifier = "group.jaapstronks.Ollie"

    // MARK: - iCloud Availability

    /// Whether iCloud is currently available for sync
    private(set) var isCloudKitAvailable: Bool = false

    /// Whether we're running in local-only mode (fallback when iCloud unavailable)
    private(set) var isLocalOnlyMode: Bool = false

    // MARK: - Contexts

    /// Main view context for UI operations
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Background context for data operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Ollie")

        // Check iCloud availability before configuring stores
        let iCloudAvailable = Self.checkiCloudAccountStatus()
        isCloudKitAvailable = iCloudAvailable

        // Configure stores
        if inMemory {
            configureInMemoryStore()
        } else if iCloudAvailable {
            configurePersistentStores()
        } else {
            // Fallback to local-only mode when iCloud is unavailable
            print("iCloud not available - using local-only storage")
            isLocalOnlyMode = true
            configureLocalOnlyStore()
        }

        // Load stores
        loadStores()

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Track remote changes (only useful when CloudKit is enabled)
        if iCloudAvailable {
            setupRemoteChangeTracking()
        }

        // Listen for iCloud account changes
        setupAccountChangeNotifications()
    }

    // MARK: - iCloud Account Status Check

    /// Check if iCloud account is available and signed in
    private static func checkiCloudAccountStatus() -> Bool {
        // Check if iCloud is available via FileManager
        guard FileManager.default.ubiquityIdentityToken != nil else {
            print("iCloud ubiquity token not available - user may not be signed in")
            return false
        }

        // Additional check: verify we can access the CloudKit container
        // This is a synchronous check that catches most availability issues
        let container = CKContainer(identifier: cloudKitContainerIdentifier)
        var isAvailable = false
        let semaphore = DispatchSemaphore(value: 0)

        container.accountStatus { status, error in
            defer { semaphore.signal() }

            if let error = error {
                print("CloudKit account status check failed: \(error.localizedDescription)")
                isAvailable = false
                return
            }

            switch status {
            case .available:
                print("iCloud account available")
                isAvailable = true
            case .noAccount:
                print("No iCloud account signed in")
                isAvailable = false
            case .restricted:
                print("iCloud account restricted (parental controls, MDM, etc.)")
                isAvailable = false
            case .couldNotDetermine:
                print("Could not determine iCloud account status")
                isAvailable = false
            case .temporarilyUnavailable:
                print("iCloud temporarily unavailable")
                // Still try to use CloudKit - it may become available
                isAvailable = true
            @unknown default:
                print("Unknown iCloud account status")
                isAvailable = false
            }
        }

        // Wait with timeout to avoid blocking forever
        let result = semaphore.wait(timeout: .now() + 5)
        if result == .timedOut {
            print("iCloud account status check timed out - assuming unavailable")
            return false
        }

        return isAvailable
    }

    // MARK: - Account Change Notifications

    private func setupAccountChangeNotifications() {
        // Listen for iCloud account changes to handle sign-out gracefully
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountChange),
            name: .CKAccountChanged,
            object: nil
        )
    }

    @objc private func handleAccountChange(_ notification: Notification) {
        print("iCloud account changed - checking new status")

        Task {
            let newStatus = Self.checkiCloudAccountStatus()

            if !newStatus && isCloudKitAvailable {
                // User signed out of iCloud while app was running
                // NSPersistentCloudKitContainer may clear data - this is the iOS 18+ issue
                print("WARNING: iCloud account signed out - data may be affected")

                // Post notification so UI can inform user
                await MainActor.run {
                    NotificationCenter.default.post(name: .iCloudAccountBecameUnavailable, object: nil)
                }
            }

            await MainActor.run {
                self.isCloudKitAvailable = newStatus
            }
        }
    }

    // MARK: - Store Configuration

    private func configureInMemoryStore() {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
    }

    /// Configure local-only SQLite store without CloudKit sync
    /// Used as fallback when iCloud is unavailable to prevent data loss
    private func configureLocalOnlyStore() {
        guard let storeURL = Self.storeURL(for: "Ollie-local.sqlite") else {
            fatalError("Unable to resolve app group container URL for local store")
        }

        let description = NSPersistentStoreDescription(url: storeURL)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        // IMPORTANT: No CloudKit options - this is a local-only store
        // Data will be preserved even if user signs out/in of iCloud
        description.cloudKitContainerOptions = nil

        container.persistentStoreDescriptions = [description]

        print("Local-only store configured:")
        print("  URL: \(storeURL)")
        print("  Note: CloudKit sync disabled - data stored locally only")
    }

    private func configurePersistentStores() {
        guard let storeURL = Self.storeURL(for: "Ollie.sqlite"),
              let sharedStoreURL = Self.storeURL(for: "Ollie-shared.sqlite") else {
            fatalError("Unable to resolve app group container URL")
        }

        // Private store description (owner's data)
        let privateDescription = NSPersistentStoreDescription(url: storeURL)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // CloudKit options for private database
        let privateCloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudKitContainerIdentifier)
        privateCloudKitOptions.databaseScope = .private
        privateDescription.cloudKitContainerOptions = privateCloudKitOptions

        // Shared store description (participant's view of shared data)
        let sharedDescription = NSPersistentStoreDescription(url: sharedStoreURL)
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // CloudKit options for shared database
        let sharedCloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudKitContainerIdentifier)
        sharedCloudKitOptions.databaseScope = .shared
        sharedDescription.cloudKitContainerOptions = sharedCloudKitOptions

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]

        print("Store URLs configured:")
        print("  Private: \(storeURL)")
        print("  Shared: \(sharedStoreURL)")
    }

    private func loadStores() {
        // Use a semaphore to wait for both stores to load
        let semaphore = DispatchSemaphore(value: 0)
        var loadedStoreCount = 0
        let expectedStoreCount = container.persistentStoreDescriptions.count

        print("Loading \(expectedStoreCount) persistent stores...")

        container.loadPersistentStores { [weak self] storeDescription, error in
            defer {
                loadedStoreCount += 1
                print("Store load callback \(loadedStoreCount)/\(expectedStoreCount)")
                if loadedStoreCount >= expectedStoreCount {
                    semaphore.signal()
                }
            }

            if let error = error as NSError? {
                print("❌ Core Data store failed to load: \(error.localizedDescription)")
                print("   Error details: \(error.userInfo)")
                return
            }

            guard let url = storeDescription.url else {
                print("⚠️ Store loaded but no URL available")
                return
            }

            print("✅ Store loaded: \(url.lastPathComponent)")

            if url.lastPathComponent == "Ollie.sqlite" {
                self?.privateStore = self?.container.persistentStoreCoordinator.persistentStore(for: url)
            } else if url.lastPathComponent == "Ollie-shared.sqlite" {
                self?.sharedStore = self?.container.persistentStoreCoordinator.persistentStore(for: url)
            }
        }

        // Wait for all stores to load (with timeout)
        print("Waiting for stores to load...")
        let result = semaphore.wait(timeout: .now() + 10)
        if result == .timedOut {
            print("⚠️ Warning: Core Data stores took too long to load")
        } else {
            let storeCount = container.persistentStoreCoordinator.persistentStores.count
            print("✅ All stores loaded. Total: \(storeCount)")
        }
    }

    // MARK: - Store URL Helper

    private static func storeURL(for filename: String) -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return nil
        }
        return containerURL.appendingPathComponent(filename)
    }

    // MARK: - Remote Change Tracking

    private func setupRemoteChangeTracking() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(processRemoteStoreChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }

    @objc private func processRemoteStoreChange(_ notification: Notification) {
        // Process persistent history to update local cache
        // This is called automatically by NSPersistentCloudKitContainer
        Task {
            await processRemoteNotification()
        }
    }

    /// Process remote notification for background fetch
    @MainActor
    func processRemoteNotification() async {
        // Force context refresh to pick up remote changes
        viewContext.refreshAllObjects()
    }

    // MARK: - Store Access Helpers

    /// Check if stores are ready for use
    var isReady: Bool {
        container.persistentStoreCoordinator.persistentStores.count > 0
    }

    /// Check if the private store is available
    var hasPrivateStore: Bool {
        privateStore != nil
    }

    /// Check if the shared store is available
    var hasSharedStore: Bool {
        sharedStore != nil
    }

    /// Get the private store for fetch requests
    func getPrivateStore() -> NSPersistentStore? {
        privateStore
    }

    /// Get the shared store for fetch requests
    func getSharedStore() -> NSPersistentStore? {
        sharedStore
    }

    /// Check if user is a participant (has data in shared store)
    func isParticipant() -> Bool {
        guard let sharedStore = sharedStore else { return false }

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")
        fetchRequest.affectedStores = [sharedStore]
        fetchRequest.fetchLimit = 1

        do {
            let count = try viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking participant status: \(error)")
            return false
        }
    }

    // MARK: - Sharing Support

    /// Share objects using NSPersistentCloudKitContainer
    func share(_ objects: [NSManagedObject], to share: CKShare?) async throws -> CKShare {
        let (_, ckShare, _) = try await container.share(objects, to: share)
        return ckShare
    }

    /// Accept a share invitation
    func acceptShareInvitation(from metadata: CKShare.Metadata) async throws {
        guard let sharedStore = sharedStore else {
            throw PersistenceError.sharedStoreUnavailable
        }
        try await container.acceptShareInvitations(from: [metadata], into: sharedStore)
    }

    /// Get shares for objects
    func fetchShares(matching objectIDs: [NSManagedObjectID]) throws -> [NSManagedObjectID: CKShare] {
        try container.fetchShares(matching: objectIDs)
    }

    // MARK: - Save

    /// Save the view context if there are changes
    func save() throws {
        let context = viewContext
        guard context.hasChanges else { return }

        // Ensure stores are loaded before saving
        guard container.persistentStoreCoordinator.persistentStores.count > 0 else {
            print("Warning: Cannot save - no persistent stores loaded")
            throw PersistenceError.privateStoreUnavailable
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Save a background context
    func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    // MARK: - Reset (Debug Only)

    #if DEBUG
    /// Delete all data from Core Data stores
    /// WARNING: This is destructive and cannot be undone
    func resetAllData() async throws {
        // Delete all entities in order (to avoid constraint violations)
        let entityNames = [
            "CDPuppyEvent",
            "CDExposure",
            "CDMasteredSkill",
            "CDMedicationCompletion",
            "CDWalkSpot",
            "CDPuppyProfile"
        ]

        let context = newBackgroundContext()

        try await context.perform {
            for entityName in entityNames {
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
                fetchRequest.includesPropertyValues = false

                do {
                    let objects = try context.fetch(fetchRequest)
                    for object in objects {
                        context.delete(object)
                    }
                } catch {
                    print("Error deleting \(entityName): \(error)")
                }
            }

            if context.hasChanges {
                try context.save()
            }
        }

        // Refresh the view context
        await MainActor.run {
            viewContext.reset()
        }
    }
    #endif

    // MARK: - Preview Support

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Add sample data for previews if needed
        return controller
    }()
}

// MARK: - Errors

enum PersistenceError: LocalizedError {
    case sharedStoreUnavailable
    case privateStoreUnavailable
    case saveFailure(Error)
    case iCloudUnavailable

    var errorDescription: String? {
        switch self {
        case .sharedStoreUnavailable:
            return "Shared store is not available"
        case .privateStoreUnavailable:
            return "Private store is not available"
        case .saveFailure(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .iCloudUnavailable:
            return "iCloud is not available. Data is being stored locally only."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when iCloud account becomes unavailable while app is running
    /// UI should inform user that sync is paused
    static let iCloudAccountBecameUnavailable = Notification.Name("iCloudAccountBecameUnavailable")
}
