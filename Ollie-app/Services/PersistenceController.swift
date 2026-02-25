//
//  PersistenceController.swift
//  Ollie-app
//
//  Core Data persistence with NSPersistentCloudKitContainer for automatic CloudKit sync.
//  Uses two-store architecture: private store for owner data, shared store for participant data.
//

import CoreData
import CloudKit

/// Manages Core Data persistence with automatic CloudKit synchronization
final class PersistenceController: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Container

    let container: NSPersistentCloudKitContainer

    // MARK: - Store References

    private var privateStore: NSPersistentStore?
    private var sharedStore: NSPersistentStore?

    // MARK: - CloudKit Container Identifier

    private static let cloudKitContainerIdentifier = "iCloud.nl.jaapstronks.Ollie"
    private static let appGroupIdentifier = "group.jaapstronks.Ollie"

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

        // Configure stores
        if inMemory {
            configureInMemoryStore()
        } else {
            configurePersistentStores()
        }

        // Load stores
        loadStores()

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Track remote changes
        setupRemoteChangeTracking()
    }

    // MARK: - Store Configuration

    private func configureInMemoryStore() {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
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

    var errorDescription: String? {
        switch self {
        case .sharedStoreUnavailable:
            return "Shared store is not available"
        case .privateStoreUnavailable:
            return "Private store is not available"
        case .saveFailure(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}
