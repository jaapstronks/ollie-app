//
//  DebugDataSection.swift
//  Otis-app
//
//  Debug section for data management (import/reset)

#if DEBUG

import SwiftUI
import CoreData
import CloudKit
import OtisShared

/// Debug section for data import and reset operations
struct DebugDataSection: View {
    @Environment(EventStore.self) var eventStore

    @State private var showResetConfirm = false
    @State private var showImportConfirm = false
    @State private var showFixZonesConfirm = false
    @State private var showResetSharingConfirm = false
    @State private var isResetting = false
    @State private var isImporting = false
    @State private var isFixingZones = false
    @State private var isResettingSharing = false
    @State private var importResult: String?
    @State private var zoneFixResult: String?
    @State private var sharingResult: String?
    @State private var cacheCleared = false
    @State private var sharedDBResult: String?
    @State private var isCheckingSharedDB = false
    @State private var isResettingSharedSync = false
    @State private var sharedSyncResetResult: String?

    var body: some View {
        Section {
            // Import from local web app data
            Button {
                showImportConfirm = true
            } label: {
                HStack {
                    Label("Import from Web App", systemImage: "square.and.arrow.down")
                    if isImporting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isImporting || isResetting)

            if let result = importResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
            }

            // Fix CloudKit zone conflicts
            Button {
                showFixZonesConfirm = true
            } label: {
                HStack {
                    Label("Fix CloudKit Zone Conflicts", systemImage: "arrow.triangle.2.circlepath.icloud")
                    if isFixingZones {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isFixingZones || isResetting)

            if let result = zoneFixResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
            }

            // Reset sharing to fix zone conflicts
            Button(role: .destructive) {
                showResetSharingConfirm = true
            } label: {
                HStack {
                    Label("Reset Sharing (Fix Sync)", systemImage: "person.2.slash")
                    if isResettingSharing {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isResettingSharing || isResetting)

            if let result = sharingResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
            }

            // Debug shared database
            Button {
                Task { await checkSharedDatabase() }
            } label: {
                HStack {
                    Label("Check Shared Database", systemImage: "icloud.and.arrow.down")
                    if isCheckingSharedDB {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isCheckingSharedDB)

            if let result = sharedDBResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") || result.contains("0 zones") ? .red : .green)
            }

            // Reset shared sync state (fixes stale sync state issues)
            Button {
                Task { await resetSharedSyncState() }
            } label: {
                HStack {
                    Label("Reset Shared Sync State", systemImage: "arrow.counterclockwise.icloud")
                    if isResettingSharedSync {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isResettingSharedSync)

            if let result = sharedSyncResetResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
            }

            // Clear discovery cache
            Button {
                clearDiscoveryCache()
            } label: {
                HStack {
                    Label("Clear Discovery Cache", systemImage: "location.slash")
                    if cacheCleared {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

            // Nuclear reset option
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                HStack {
                    Label("Reset All Data", systemImage: "trash.fill")
                    if isResetting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isResetting || isImporting)
        } header: {
            Label("Data Management", systemImage: "externaldrive.fill")
        } footer: {
            Text("Import loads JSONL files from ~/Github NW/Otis/data. Reset deletes all Core Data and starts fresh.")
        }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) {
                Task { await performReset() }
            }
        } message: {
            Text("This will delete all events, profile, and sync data. The app will restart fresh. This cannot be undone.")
        }
        .alert("Import Web App Data?", isPresented: $showImportConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Import") {
                Task { await performImport() }
            }
        } message: {
            Text("This will import all JSONL files from the local Otis web app directory into Core Data.")
        }
        .alert("Fix CloudKit Zone Conflicts?", isPresented: $showFixZonesConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Fix Zones", role: .destructive) {
                Task { await fixZoneConflicts() }
            }
        } message: {
            Text("This will reassign all events to the same zone as their profile. Events will be deleted and recreated. Force-quit the app after this completes.")
        }
        .alert("Reset Sharing?", isPresented: $showResetSharingConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Sharing", role: .destructive) {
                Task { await resetSharing() }
            }
        } message: {
            Text("This will STOP sharing with all participants. Your data stays intact. After this, you can re-share from Settings and participants will need to re-accept. This fixes zone sync conflicts.")
        }
    }

    // MARK: - Reset Sharing

    private func resetSharing() async {
        isResettingSharing = true
        sharingResult = nil

        let context = PersistenceController.shared.viewContext
        let profiles = CDPuppyProfile.fetchAllProfiles(in: context)

        guard !profiles.isEmpty else {
            sharingResult = "Error: No profile found"
            isResettingSharing = false
            return
        }

        do {
            // Check if there's a share using CloudKitService
            guard let share = CloudKitService.shared.currentShare else {
                sharingResult = "No active share found"
                isResettingSharing = false
                return
            }

            // Delete the share from CloudKit
            let container = CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier)
            let privateDatabase = container.privateCloudDatabase

            try await privateDatabase.deleteRecord(withID: share.recordID)

            print("Successfully deleted CKShare")
            sharingResult = "✓ Sharing stopped. Force-quit app, then re-share from Settings."

        } catch {
            print("Error resetting sharing: \(error)")
            sharingResult = "Error: \(error.localizedDescription)"
        }

        isResettingSharing = false
    }

    // MARK: - Reset Action

    private func performReset() async {
        isResetting = true
        importResult = nil

        do {
            try await PersistenceController.shared.resetAllData()

            // Clear migration flag so it doesn't try to migrate archived data
            UserDefaults.standard.removeObject(forKey: "CoreDataMigrationCompleted_v1")

            // Clear widget data
            if let sharedDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier) {
                sharedDefaults.removeObject(forKey: "widgetData")
            }

            importResult = "✓ Reset complete. Restart the app."
        } catch {
            importResult = "Error: \(error.localizedDescription)"
        }

        isResetting = false
    }

    // MARK: - Import Action

    private func performImport() async {
        isImporting = true
        importResult = nil

        let webAppDataPath = NSString("~/Github NW/Otis/data").expandingTildeInPath
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: webAppDataPath) else {
            importResult = "Error: Web app data not found at \(webAppDataPath)"
            isImporting = false
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: webAppDataPath)
            let jsonlFiles = files.filter { $0.hasSuffix(".jsonl") }.sorted()

            var totalEvents = 0
            var totalFiles = 0
            let context = PersistenceController.shared.viewContext
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let string = try container.decode(String.self)
                if let date = Date.fromISO8601(string) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date")
            }

            for fileName in jsonlFiles {
                let filePath = (webAppDataPath as NSString).appendingPathComponent(fileName)
                let content = try String(contentsOfFile: filePath, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

                for line in lines {
                    guard let data = line.data(using: .utf8),
                          let event = try? decoder.decode(PuppyEvent.self, from: data) else {
                        continue
                    }

                    // Check if event already exists
                    let existing = CDPuppyEvent.fetch(byId: event.id, in: context)
                    if existing == nil {
                        _ = CDPuppyEvent.create(from: event, in: context)
                        totalEvents += 1
                    }
                }

                totalFiles += 1

                // Save in batches
                if totalEvents % 100 == 0 && context.hasChanges {
                    try context.save()
                }
            }

            // Final save
            if context.hasChanges {
                try context.save()
            }

            importResult = "✓ Imported \(totalEvents) events from \(totalFiles) files"
        } catch {
            importResult = "Error: \(error.localizedDescription)"
        }

        isImporting = false
    }

    // MARK: - Fix Zone Conflicts

    private func fixZoneConflicts() async {
        isFixingZones = true
        zoneFixResult = nil

        let context = PersistenceController.shared.viewContext
        let coordinator = context.persistentStoreCoordinator

        // First, print diagnostic info
        print("=== ZONE DIAGNOSTIC ===")
        print("Available stores:")
        for store in coordinator?.persistentStores ?? [] {
            print("  - \(store.url?.lastPathComponent ?? "unknown"): \(store.identifier ?? "no id")")
        }

        // Get all profiles to find their stores
        let profiles = CDPuppyProfile.fetchAllProfiles(in: context)

        print("Found \(profiles.count) profiles")

        guard !profiles.isEmpty else {
            zoneFixResult = "Error: No profiles found"
            isFixingZones = false
            return
        }

        var fixedCount = 0
        var errorCount = 0
        var diagnosticInfo: [String] = []

        for profile in profiles {
            let profileStoreName = profile.persistentStore?.url?.lastPathComponent ?? "UNKNOWN"
            print("Profile '\(profile.name ?? "?")' store: \(profileStoreName)")
            diagnosticInfo.append("Profile: \(profileStoreName)")

            guard let profileStore = profile.persistentStore else {
                print("Could not determine store for profile \(profile.name ?? "unknown")")
                diagnosticInfo.append("  ⚠️ No store for profile!")
                continue
            }

            // Fetch all events for this profile
            let fetchRequest = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
            fetchRequest.predicate = NSPredicate(format: "profile == %@", profile)

            do {
                let events = try context.fetch(fetchRequest)
                print("Found \(events.count) events for profile")
                diagnosticInfo.append("  Events: \(events.count)")

                var storeBreakdown: [String: Int] = [:]

                for cdEvent in events {
                    let eventStoreName: String
                    // Use objectID.persistentStore directly (more reliable)
                    if !cdEvent.objectID.isTemporaryID, let eventStore = cdEvent.objectID.persistentStore {
                        eventStoreName = eventStore.url?.lastPathComponent ?? "unknown"
                        storeBreakdown[eventStoreName, default: 0] += 1

                        if eventStore != profileStore {
                            // Event is in wrong store - save its data, delete it, recreate in correct store
                            print("  ⚠️ Event \(cdEvent.id?.uuidString ?? "?") in wrong store: \(eventStoreName) vs profile in \(profileStore.url?.lastPathComponent ?? "?")")
                            if let eventData = cdEvent.toPuppyEvent() {
                                context.delete(cdEvent)

                                // Create new event in correct store
                                let newEvent = CDPuppyEvent.create(from: eventData, in: context)
                                newEvent.profile = profile
                                context.assign(newEvent, to: profileStore)

                                fixedCount += 1
                            }
                        }
                    } else {
                        storeBreakdown["nil-store", default: 0] += 1
                    }
                }

                for (storeName, count) in storeBreakdown {
                    print("  - \(storeName): \(count) events")
                    diagnosticInfo.append("    \(storeName): \(count)")
                }

            } catch {
                print("Error fetching events for profile: \(error)")
                errorCount += 1
            }
        }

        // Also check for orphaned events (no profile)
        let orphanRequest = NSFetchRequest<CDPuppyEvent>(entityName: "CDPuppyEvent")
        orphanRequest.predicate = NSPredicate(format: "profile == nil")
        if let orphans = try? context.fetch(orphanRequest) {
            print("Orphaned events (no profile): \(orphans.count)")
            diagnosticInfo.append("Orphans: \(orphans.count)")
        }

        // Check CloudKit sharing state via CloudKitService
        print("\n=== CLOUDKIT SHARING STATE ===")
        if let share = CloudKitService.shared.currentShare {
            print("Active CKShare found:")
            print("  Share URL: \(share.url?.absoluteString ?? "none")")
            print("  Participants: \(share.participants.count)")
            for participant in share.participants {
                let role = participant.role == .owner ? "owner" : "participant"
                let status = participant.acceptanceStatus == .accepted ? "accepted" : "pending"
                print("    - \(participant.userIdentity.nameComponents?.formatted() ?? "unknown") (\(role), \(status))")
            }
            diagnosticInfo.append("Share: active with \(share.participants.count) participants")
        } else {
            print("No active CKShare")
            diagnosticInfo.append("Share: none")
        }
        print("Is participant: \(CloudKitService.shared.isParticipant)")
        print("=== END SHARING STATE ===")

        // Save changes
        do {
            if context.hasChanges {
                try context.save()
            }
            let summary = diagnosticInfo.joined(separator: "\n")
            print("=== END DIAGNOSTIC ===")
            print(summary)
            zoneFixResult = "Fixed \(fixedCount). Check Xcode console for details."
        } catch {
            zoneFixResult = "Error saving: \(error.localizedDescription)"
        }

        isFixingZones = false
    }

    // MARK: - Check Shared Database

    private func checkSharedDatabase() async {
        isCheckingSharedDB = true
        sharedDBResult = nil

        let container = CKContainer(identifier: "iCloud.nl.jaapstronks.Otis")
        let sharedDB = container.sharedCloudDatabase
        let privateDB = container.privateCloudDatabase

        var results: [String] = []

        // Check shared database zones
        do {
            let zones = try await sharedDB.allRecordZones()
            results.append("Shared DB: \(zones.count) zone(s)")
            print("=== SHARED DATABASE ZONES ===")
            for zone in zones {
                print("  Zone: \(zone.zoneID.zoneName) (owner: \(zone.zoneID.ownerName))")
                results.append("  - \(zone.zoneID.zoneName)")

                // Try to fetch records from this zone
                let query = CKQuery(recordType: "CD_CDPuppyProfile", predicate: NSPredicate(value: true))
                let (records, _) = try await sharedDB.records(
                    matching: query,
                    inZoneWith: zone.zoneID,
                    desiredKeys: ["CD_name"],
                    resultsLimit: 10
                )
                print("  Found \(records.count) profile record(s)")
                for (recordID, result) in records {
                    switch result {
                    case .success(let record):
                        let name = record["CD_name"] as? String ?? "unnamed"
                        print("    - \(name) (\(recordID.recordName))")
                        results.append("    Profile: \(name)")
                    case .failure(let error):
                        print("    - Error: \(error.localizedDescription)")
                    }
                }
            }
            print("=== END SHARED ZONES ===")
        } catch {
            results.append("Shared DB error: \(error.localizedDescription)")
            print("Error fetching shared zones: \(error)")
        }

        // Check private database for shares
        do {
            print("\n=== PRIVATE DATABASE SHARES ===")
            // Query for CKShare records in the Core Data zone
            let zoneName = "com.apple.coredata.cloudkit.zone"
            let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)

            // Check if there's a share in the private database
            let query = CKQuery(recordType: "cloudkit.share", predicate: NSPredicate(value: true))
            let (shareRecords, _) = try await privateDB.records(
                matching: query,
                inZoneWith: zoneID,
                desiredKeys: nil,
                resultsLimit: 10
            )

            results.append("Private DB shares: \(shareRecords.count)")
            print("Found \(shareRecords.count) CKShare record(s)")

            for (_, result) in shareRecords {
                switch result {
                case .success(let record):
                    if let share = record as? CKShare {
                        print("  Share URL: \(share.url?.absoluteString ?? "none")")
                        print("  Participants: \(share.participants.count)")
                        for p in share.participants {
                            let status = p.acceptanceStatus == .accepted ? "accepted" : "pending"
                            print("    - \(p.userIdentity.nameComponents?.formatted() ?? "?") (\(status))")
                        }
                    }
                case .failure(let error):
                    print("  Error: \(error.localizedDescription)")
                }
            }
            print("=== END PRIVATE SHARES ===")
        } catch {
            results.append("Private shares check: \(error.localizedDescription)")
            print("Error checking private shares: \(error)")
        }

        // Check Core Data shared store
        if let sharedStore = PersistenceController.shared.getSharedStore() {
            let context = PersistenceController.shared.viewContext
            let request = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")
            request.affectedStores = [sharedStore]

            if let count = try? context.count(for: request) {
                results.append("Core Data shared store: \(count) profile(s)")
            }
        } else {
            results.append("Core Data shared store: unavailable")
        }

        sharedDBResult = results.joined(separator: "\n")
        isCheckingSharedDB = false
    }

    // MARK: - Reset Shared Sync State

    private func resetSharedSyncState() async {
        isResettingSharedSync = true
        sharedSyncResetResult = nil

        // Clear tombstones first
        SyncCoordinator.shared.clearAllTombstones()

        // Reset shared sync engine state and re-fetch
        await SyncCoordinator.shared.resetSharedSyncState()

        // Check how many profiles we got
        let context = PersistenceController.shared.viewContext
        if let sharedStore = PersistenceController.shared.getSharedStore() {
            let request = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")
            request.affectedStores = [sharedStore]
            let count = (try? context.count(for: request)) ?? 0
            sharedSyncResetResult = "Reset complete. Shared profiles: \(count)"
        } else {
            sharedSyncResetResult = "Reset complete. (No shared store)"
        }

        isResettingSharedSync = false
    }

    // MARK: - Clear Discovery Cache

    private func clearDiscoveryCache() {
        // Delete the discovered spots cache file
        let cacheFileName = "discovered-spots-cache.json"
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let cacheFileURL = documentsURL.appendingPathComponent(cacheFileName)
            try? FileManager.default.removeItem(at: cacheFileURL)
        }

        withAnimation {
            cacheCleared = true
        }

        // Reset after 2 seconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                cacheCleared = false
            }
        }
    }
}

#Preview {
    Form {
        DebugDataSection()
    }
    .environment(EventStore())
}

#endif
