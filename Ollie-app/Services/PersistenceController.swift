//
//  PersistenceController.swift
//  Otis-app
//
//  Core Data persistence with LOCAL-ONLY storage.
//  CloudKit sync is handled separately by CKSyncEngine via SyncCoordinator.
//
//  Architecture:
//  - NSPersistentContainer for local SQLite storage (NOT NSPersistentCloudKitContainer)
//  - Two stores: private (user's data) and shared (data from partner)
//  - SyncCoordinator handles CKSyncEngine-based CloudKit sync
//  - This separation provides faster sync (sub-second vs 1-5 min) and better control
//
//  Migration Note:
//  Previously used NSPersistentCloudKitContainer which has sync delays and
//  limited control. CKSyncEngine (iOS 17+) gives us manual sync triggers,
//  explicit conflict resolution, and better error visibility.
//

@preconcurrency import CoreData
import CloudKit

/// Manages Core Data persistence (local-only, CloudKit sync handled by SyncCoordinator)
final class PersistenceController: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared singleton - explicitly nonisolated for access from default parameter expressions
    nonisolated static let shared = PersistenceController()

    // MARK: - Container

    /// Local-only Core Data container (NOT CloudKit-enabled)
    /// CloudKit sync is handled by CKSyncEngine via SyncCoordinator
    let container: NSPersistentContainer

    // MARK: - Store References

    private var privateStore: NSPersistentStore?
    private var sharedStore: NSPersistentStore?

    // MARK: - Identifiers

    nonisolated static let cloudKitContainerIdentifier = "iCloud.nl.jaapstronks.Otis"
    nonisolated private static let appGroupIdentifier = "group.jaapstronks.Otis"

    // MARK: - iCloud Availability

    /// Whether iCloud is currently available for sync
    private(set) var isCloudKitAvailable: Bool = false

    /// Whether we're running with in-memory storage only (fallback when app group unavailable)
    /// Data will NOT persist between app launches in this mode
    private(set) var isInMemoryFallbackMode: Bool = false

    // MARK: - Contexts

    /// Main view context for UI operations
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Background context for data operations
    nonisolated func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    // MARK: - Initialization

    nonisolated init(inMemory: Bool = false) {
        // Use regular NSPersistentContainer (not CloudKit-enabled)
        // CloudKit sync is handled by CKSyncEngine via SyncCoordinator
        container = NSPersistentContainer(name: "Ollie")

        // Check iCloud availability (for SyncCoordinator to use)
        let iCloudAvailable = Self.checkiCloudAccountStatusSync()
        isCloudKitAvailable = iCloudAvailable

        // Configure stores (all local-only)
        if inMemory {
            configureInMemoryStore()
        } else {
            configurePersistentStores()
        }

        // Load stores (callback is synchronous for local SQLite stores)
        loadStores()

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Listen for iCloud account changes
        setupAccountChangeNotifications()

        // Verify CloudKit availability asynchronously (may update isCloudKitAvailable)
        if iCloudAvailable {
            Task { await self.verifyCloudKitAvailabilityAsync() }
        }
    }

    // MARK: - iCloud Account Status Check

    /// Fast synchronous check using ubiquityIdentityToken only.
    /// Does NOT call CKContainer.accountStatus() — that is deferred to background.
    nonisolated private static func checkiCloudAccountStatusSync() -> Bool {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            print("iCloud ubiquity token not available - user may not be signed in")
            return false
        }
        print("iCloud ubiquity token present - assuming available")
        return true
    }

    /// Async verification of CloudKit account status, called after init completes.
    /// Updates isCloudKitAvailable if the account turns out to be unavailable.
    private func verifyCloudKitAvailabilityAsync() async {
        do {
            let status = try await CKContainer(identifier: Self.cloudKitContainerIdentifier).accountStatus()
            switch status {
            case .available:
                print("CloudKit account verified: available")
            case .temporarilyUnavailable:
                print("CloudKit account temporarily unavailable - keeping sync enabled")
            case .noAccount, .restricted, .couldNotDetermine:
                print("CloudKit account not usable (status: \(status)) - sync may not work")
                await MainActor.run {
                    self.isCloudKitAvailable = false
                }
            @unknown default:
                print("Unknown CloudKit account status")
            }
        } catch {
            print("CloudKit account status check failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Account Change Notifications

    nonisolated private func setupAccountChangeNotifications() {
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
            // Use async account status check — never block a thread with semaphores
            let newStatus: Bool
            do {
                let status = try await CKContainer(identifier: Self.cloudKitContainerIdentifier).accountStatus()
                newStatus = (status == .available || status == .temporarilyUnavailable)
            } catch {
                print("CloudKit account status check failed: \(error.localizedDescription)")
                newStatus = false
            }

            if !newStatus && isCloudKitAvailable {
                // User signed out of iCloud while app was running
                print("WARNING: iCloud account signed out - sync will be paused")

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

    nonisolated private func configureInMemoryStore() {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
    }

    /// Configure local-only SQLite stores for private and shared data.
    /// CloudKit sync is handled by SyncCoordinator/CKSyncEngine, not Core Data.
    nonisolated private func configurePersistentStores() {
        guard let storeURL = Self.storeURL(for: "Ollie.sqlite"),
              let sharedStoreURL = Self.storeURL(for: "Ollie-shared.sqlite") else {
            // Fallback to in-memory store if app group container is unavailable
            // This prevents crashes while still allowing the app to function
            print("ERROR: Unable to resolve app group container URL - falling back to in-memory storage")
            isInMemoryFallbackMode = true
            configureInMemoryStore()
            return
        }

        // Migration: Check if we need to migrate from old Application Support location
        Self.migrateFromLegacyStoreIfNeeded(to: storeURL)

        // Private store description (owner's data)
        // NO CloudKit options - sync handled by CKSyncEngine
        let privateDescription = NSPersistentStoreDescription(url: storeURL)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        // Shared store description (partner's data synced from CloudKit shared database)
        // NO CloudKit options - sync handled by CKSyncEngine
        let sharedDescription = NSPersistentStoreDescription(url: sharedStoreURL)
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]

        print("Local Core Data stores configured:")
        print("  Private: \(storeURL)")
        print("  Shared: \(sharedStoreURL)")
        print("  Note: CloudKit sync handled by CKSyncEngine via SyncCoordinator")
    }

    // MARK: - Legacy Store Migration

    /// Migrate data from old Application Support location to app group container
    /// This handles the transition from NSPersistentCloudKitContainer to CKSyncEngine
    nonisolated private static func migrateFromLegacyStoreIfNeeded(to newStoreURL: URL) {
        let fileManager = FileManager.default

        print("Migration: Checking for legacy store migration...")
        print("Migration: Target URL: \(newStoreURL.path)")

        // Check if new store already has data (migration already done or fresh install)
        if fileManager.fileExists(atPath: newStoreURL.path) {
            let fileSize = (try? fileManager.attributesOfItem(atPath: newStoreURL.path)[.size] as? Int) ?? 0
            print("Migration: App group store exists, size: \(fileSize) bytes")
            if fileSize > 32768 { // SQLite header + some data (more than just empty DB)
                print("Migration: Store appears to have data, skipping migration")
                return
            }
        } else {
            print("Migration: App group store does not exist yet")
        }

        // Look for legacy store in Application Support
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("Migration: Could not find Application Support directory")
            return
        }

        print("Migration: Searching in Application Support: \(appSupportURL.path)")

        // List all files in Application Support for debugging
        if let contents = try? fileManager.contentsOfDirectory(atPath: appSupportURL.path) {
            print("Migration: Application Support contents: \(contents)")
        }

        // Try multiple possible legacy store names
        let possibleLegacyNames = ["Ollie.sqlite", "Otis.sqlite", "Ollie-app.sqlite"]
        var legacyStoreURL: URL?

        for name in possibleLegacyNames {
            let candidateURL = appSupportURL.appendingPathComponent(name)
            if fileManager.fileExists(atPath: candidateURL.path) {
                let size = (try? fileManager.attributesOfItem(atPath: candidateURL.path)[.size] as? Int) ?? 0
                legacyStoreURL = candidateURL
                print("Migration: Found legacy store at \(candidateURL.path) (\(size) bytes)")
                break
            }
        }

        // Also check app group container for any other sqlite files
        if let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            print("Migration: App group container: \(appGroupURL.path)")
            if let contents = try? fileManager.contentsOfDirectory(atPath: appGroupURL.path) {
                print("Migration: App group contents: \(contents)")
                for file in contents where file.contains("sqlite") {
                    let fileURL = appGroupURL.appendingPathComponent(file)
                    let size = (try? fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int) ?? 0
                    print("Migration: Found SQLite file: \(file) (\(size) bytes)")
                }
            }
        }

        guard let sourceURL = legacyStoreURL else {
            print("Migration: No legacy store found in Application Support")
            return
        }

        // Delete empty target store if it exists (so we can copy)
        if fileManager.fileExists(atPath: newStoreURL.path) {
            do {
                try fileManager.removeItem(at: newStoreURL)
                print("Migration: Removed empty target store")
            } catch {
                print("Migration: Could not remove empty target store: \(error)")
            }
        }

        // Copy the legacy store and its associated files (-wal, -shm)
        print("Migration: Copying legacy store to app group container...")

        do {
            // Copy main SQLite file
            try fileManager.copyItem(at: sourceURL, to: newStoreURL)
            print("Migration: Copied main store file")

            // Copy WAL file if exists
            let walSource = sourceURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
            let walDest = newStoreURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
            if fileManager.fileExists(atPath: walSource.path) {
                try? fileManager.removeItem(at: walDest)
                try fileManager.copyItem(at: walSource, to: walDest)
                print("Migration: Copied WAL file")
            }

            // Copy SHM file if exists
            let shmSource = sourceURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
            let shmDest = newStoreURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
            if fileManager.fileExists(atPath: shmSource.path) {
                try? fileManager.removeItem(at: shmDest)
                try fileManager.copyItem(at: shmSource, to: shmDest)
                print("Migration: Copied SHM file")
            }

            print("Migration: Successfully migrated legacy store to app group container")

        } catch {
            print("Migration ERROR: Failed to copy legacy store: \(error.localizedDescription)")
        }
    }

    nonisolated private func loadStores() {
        let expectedStoreCount = container.persistentStoreDescriptions.count
        var loadedStoreCount = 0

        print("Loading \(expectedStoreCount) persistent stores...")

        // loadPersistentStores calls the completion handler synchronously for each
        // store description when using local SQLite stores. No semaphore needed.
        container.loadPersistentStores { [weak self] storeDescription, error in
            loadedStoreCount += 1
            print("Store load callback \(loadedStoreCount)/\(expectedStoreCount)")

            if let error = error as NSError? {
                print("Core Data store failed to load: \(error.localizedDescription)")
                print("   Error details: \(error.userInfo)")
                return
            }

            guard let url = storeDescription.url else {
                print("Store loaded but no URL available")
                return
            }

            print("Store loaded: \(url.lastPathComponent)")

            if url.lastPathComponent == "Ollie.sqlite" {
                self?.privateStore = self?.container.persistentStoreCoordinator.persistentStore(for: url)
            } else if url.lastPathComponent == "Ollie-shared.sqlite" {
                self?.sharedStore = self?.container.persistentStoreCoordinator.persistentStore(for: url)
            }
        }

        let storeCount = container.persistentStoreCoordinator.persistentStores.count
        print("All stores loaded. Total: \(storeCount)")
    }

    // MARK: - Store URL Helper

    nonisolated private static func storeURL(for filename: String) -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return nil
        }
        return containerURL.appendingPathComponent(filename)
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

    // MARK: - Context Refresh

    /// Refresh the view context to pick up changes from CKSyncEngine
    /// Called by SyncCoordinator when remote changes are fetched
    @MainActor
    func refreshAfterRemoteChanges() {
        viewContext.refreshAllObjects()
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

    nonisolated(unsafe) static var preview: PersistenceController = {
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
    case appGroupUnavailable

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
        case .appGroupUnavailable:
            return "App group container is not available. Data will not persist between app launches."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when iCloud account becomes unavailable while app is running
    /// UI should inform user that sync is paused
    static let iCloudAccountBecameUnavailable = Notification.Name("iCloudAccountBecameUnavailable")
}
