//
//  SyncTestSection.swift
//  Ollie-app
//
//  Debug section for sync testing with predictable test data.
//  Use with scripts/sync-test.sh for log capture and analysis.
//

#if DEBUG

import CloudKit
import CoreData
import OtisShared
import SwiftUI

/// Debug section for sync testing operations
@available(iOS 17.0, *)
struct SyncTestSection: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(CloudKitService.self) var cloudKitService

    @State private var testProfileExists = false
    @State private var testEventCount = 0
    @State private var additionalEntityCount = 0
    @State private var existingEntities: [TestEntityID: Bool] = [:]
    @State private var isCreating = false
    @State private var isCreatingAll = false
    @State private var isDeleting = false
    @State private var isSyncing = false
    @State private var lastAction: String?
    @State private var showDeleteConfirm = false
    @State private var showPurgeConfirm = false
    @State private var isPurgingCloudKit = false
    @State private var pendingChanges = 0
    @State private var showEntityList = false

    // Photo testing state
    @State private var testPhotoEventExists = false
    @State private var isCreatingPhoto = false
    @State private var isUploadingPhoto = false
    @State private var showPhotoSection = false

    var body: some View {
        Section {
            // Test data status
            HStack {
                Label("Test Profile", systemImage: testProfileExists ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(testProfileExists ? .green : .secondary)
                Spacer()
                Text(testProfileExists ? testProfileName : "Not created")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Test Events", systemImage: "list.bullet")
                Spacer()
                Text("\(testEventCount) / \(TestEventID.allCases.count)")
                    .foregroundStyle(.secondary)
            }

            // Additional entities status (expandable)
            DisclosureGroup(isExpanded: $showEntityList) {
                ForEach(TestEntityID.allCases, id: \.self) { entityType in
                    HStack {
                        Image(systemName: existingEntities[entityType] == true ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(existingEntities[entityType] == true ? .green : .secondary)
                            .font(.caption)
                        Text(entityType.displayName)
                            .font(.caption)
                        Spacer()
                        if existingEntities[entityType] != true && testProfileExists {
                            Button("Create") {
                                Task { await createSingleEntity(entityType) }
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                        }
                    }
                }
            } label: {
                HStack {
                    Label("Additional Entities", systemImage: "square.stack.3d.up")
                    Spacer()
                    Text("\(additionalEntityCount) / \(TestEntityID.allCases.count)")
                        .foregroundStyle(.secondary)
                }
            }

            // Photo sync testing (Phase 2)
            DisclosureGroup(isExpanded: $showPhotoSection) {
                HStack {
                    Image(systemName: testPhotoEventExists ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(testPhotoEventExists ? .green : .secondary)
                        .font(.caption)
                    Text("Test Photo Event")
                        .font(.caption)
                    Spacer()
                    Text(testPhotoEventExists ? "AA000000-...-000022" : "Not created")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Create test photo event with image
                Button {
                    Task { await createTestPhotoEvent() }
                } label: {
                    HStack {
                        Label("Create Photo Event", systemImage: "photo.badge.plus")
                            .font(.caption)
                        Spacer()
                        if isCreatingPhoto {
                            ProgressView()
                        }
                    }
                }
                .disabled(isCreatingPhoto || !testProfileExists || testPhotoEventExists)

                // Upload test photo to CloudKit
                Button {
                    Task { await uploadTestPhoto() }
                } label: {
                    HStack {
                        Label("Upload Photo to CloudKit", systemImage: "icloud.and.arrow.up")
                            .font(.caption)
                        Spacer()
                        if isUploadingPhoto {
                            ProgressView()
                        }
                    }
                }
                .disabled(isUploadingPhoto || !testPhotoEventExists)

            } label: {
                HStack {
                    Label("Photo Sync (Phase 2)", systemImage: "photo.on.rectangle.angled")
                    Spacer()
                    Image(systemName: testPhotoEventExists ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(testPhotoEventExists ? .green : .secondary)
                }
            }

            HStack {
                Label("Pending Changes", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                Text("\(pendingChanges)")
                    .foregroundStyle(pendingChanges > 0 ? .orange : .secondary)
            }

            // Create basic test data
            Button {
                Task { await createTestData() }
            } label: {
                HStack {
                    Label("Create Basic Test Data", systemImage: "plus.circle")
                    Spacer()
                    if isCreating {
                        ProgressView()
                    }
                }
            }
            .disabled(isCreating || testProfileExists)

            // Create ALL test entities
            Button {
                Task { await createAllEntities() }
            } label: {
                HStack {
                    Label("Create All Entity Types", systemImage: "plus.circle.fill")
                    Spacer()
                    if isCreatingAll {
                        ProgressView()
                    }
                }
            }
            .disabled(isCreatingAll || !testProfileExists || additionalEntityCount == TestEntityID.allCases.count)

            // Re-queue existing test data for sync
            Button {
                Task { await requeueTestData() }
            } label: {
                Label("Re-queue Test Data", systemImage: "arrow.clockwise.icloud")
            }
            .disabled(!testProfileExists)

            // Delete test data
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack {
                    Label("Delete Test Data", systemImage: "trash")
                    Spacer()
                    if isDeleting {
                        ProgressView()
                    }
                }
            }
            .disabled(isDeleting || !testProfileExists)

            // Force sync
            Button {
                Task { await forceSync() }
            } label: {
                HStack {
                    Label("Force Full Sync", systemImage: "arrow.triangle.2.circlepath.icloud")
                    Spacer()
                    if isSyncing {
                        ProgressView()
                    }
                }
            }
            .disabled(isSyncing)

            // Purge test data from CloudKit
            Button(role: .destructive) {
                showPurgeConfirm = true
            } label: {
                HStack {
                    Label("Purge Test Data (CloudKit)", systemImage: "icloud.slash")
                    Spacer()
                    if isPurgingCloudKit {
                        ProgressView()
                    }
                }
            }
            .disabled(isPurgingCloudKit)

            // Clear tombstones
            Button {
                SyncCoordinator.shared.clearAllTombstones()
                lastAction = "Cleared all tombstones"
            } label: {
                Label("Clear Tombstones", systemImage: "trash.slash")
            }

            // Log filter command
            Button {
                copyLogCommand()
            } label: {
                Label("Copy Log Filter Command", systemImage: "doc.on.doc")
            }

            if let action = lastAction {
                Text(action)
                    .font(.caption)
                    .foregroundStyle(action.contains("Error") ? .red : .green)
            }
        } header: {
            Label("Sync Testing", systemImage: "testtube.2")
        } footer: {
            Text("Create test data with predictable IDs (AA000000...) for sync debugging. Use scripts/sync-test.sh -t to capture only test record logs.")
        }
        .onAppear {
            refreshStatus()
        }
        .alert("Delete Test Data?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteTestData() }
            }
        } message: {
            Text("This will delete the test profile and all test events from Core Data. CloudKit data will be deleted on next sync.")
        }
        .alert("Purge from CloudKit?", isPresented: $showPurgeConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Purge", role: .destructive) {
                Task { await purgeFromCloudKit() }
            }
        } message: {
            Text("This will directly delete test records from CloudKit. Use this if test data is stuck in the cloud.")
        }
    }

    // MARK: - Actions

    private func refreshStatus() {
        testProfileExists = SyncTestFixtures.testProfileExists(in: viewContext)
        testEventCount = SyncTestFixtures.testEventCount(in: viewContext)
        existingEntities = SyncTestFixtures.existingTestEntities(in: viewContext)
        additionalEntityCount = SyncTestFixtures.additionalTestEntityCount(in: viewContext)
        testPhotoEventExists = SyncTestFixtures.testPhotoEventExists(in: viewContext)
        pendingChanges = SyncCoordinator.shared.pendingChangesCount
    }

    private func createTestData() async {
        isCreating = true
        lastAction = nil

        let (_, events, _) = SyncTestFixtures.createFullTestDataSet(in: viewContext)

        do {
            try viewContext.save()

            // Queue for sync using record IDs
            let profileRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyProfile", id: testProfileID)
            SyncCoordinator.shared.markPendingSave(recordID: profileRecordID)

            for testEvent in TestEventID.allCases {
                let eventRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyEvent", id: testEvent.uuid)
                SyncCoordinator.shared.markPendingSave(recordID: eventRecordID)
            }

            let weightRecordID = SyncCoordinator.shared.recordID(for: "CDWeightMeasurement", id: testWeightID)
            SyncCoordinator.shared.markPendingSave(recordID: weightRecordID)

            lastAction = "Created \(testProfileName) + \(events.count) events"
            refreshStatus()
        } catch {
            lastAction = "Error: \(error.localizedDescription)"
        }

        isCreating = false
    }

    private func createAllEntities() async {
        isCreatingAll = true
        lastAction = nil

        // Get the test profile
        let profileFetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")
        profileFetch.predicate = NSPredicate(format: "id == %@", testProfileID as CVarArg)
        profileFetch.fetchLimit = 1

        do {
            guard let profile = try viewContext.fetch(profileFetch).first else {
                lastAction = "Error: Test profile not found"
                isCreatingAll = false
                return
            }

            let entities = SyncTestFixtures.createAllTestEntities(in: viewContext, for: profile)
            try viewContext.save()

            // Queue all for sync
            for (entityType, _) in entities {
                let recordID = SyncCoordinator.shared.recordID(for: entityType.entityName, id: entityType.uuid)
                SyncCoordinator.shared.markPendingSave(recordID: recordID)
            }

            lastAction = "Created \(entities.count) additional entities"
            refreshStatus()
        } catch {
            lastAction = "Error: \(error.localizedDescription)"
        }

        isCreatingAll = false
    }

    private func createSingleEntity(_ entityType: TestEntityID) async {
        lastAction = nil

        // Get the test profile
        let profileFetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")
        profileFetch.predicate = NSPredicate(format: "id == %@", testProfileID as CVarArg)
        profileFetch.fetchLimit = 1

        do {
            guard let profile = try viewContext.fetch(profileFetch).first else {
                lastAction = "Error: Test profile not found"
                return
            }

            // For UserSentimentCheckIn, we need a UserIdentity first
            var userIdentity: NSManagedObject?
            if entityType == .userSentimentCheckIn {
                let identityFetch = NSFetchRequest<NSManagedObject>(entityName: "CDUserIdentity")
                identityFetch.predicate = NSPredicate(format: "id == %@", TestEntityID.userIdentity.uuid as CVarArg)
                identityFetch.fetchLimit = 1
                userIdentity = try viewContext.fetch(identityFetch).first

                if userIdentity == nil {
                    // Create UserIdentity first
                    userIdentity = SyncTestFixtures.createTestEntity(.userIdentity, in: viewContext, for: profile)
                    try viewContext.save()
                    let identityRecordID = SyncCoordinator.shared.recordID(for: TestEntityID.userIdentity.entityName, id: TestEntityID.userIdentity.uuid)
                    SyncCoordinator.shared.markPendingSave(recordID: identityRecordID)
                }
            }

            _ = SyncTestFixtures.createTestEntity(entityType, in: viewContext, for: profile, userIdentity: userIdentity)
            try viewContext.save()

            // Queue for sync
            let recordID = SyncCoordinator.shared.recordID(for: entityType.entityName, id: entityType.uuid)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)

            lastAction = "Created \(entityType.displayName)"
            refreshStatus()
        } catch {
            lastAction = "Error: \(error.localizedDescription)"
        }
    }

    private func requeueTestData() async {
        lastAction = nil

        // Re-queue existing test data for sync
        let profileRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyProfile", id: testProfileID)
        SyncCoordinator.shared.markPendingSave(recordID: profileRecordID)

        for testEvent in TestEventID.allCases {
            let eventRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyEvent", id: testEvent.uuid)
            SyncCoordinator.shared.markPendingSave(recordID: eventRecordID)
        }

        let weightRecordID = SyncCoordinator.shared.recordID(for: "CDWeightMeasurement", id: testWeightID)
        SyncCoordinator.shared.markPendingSave(recordID: weightRecordID)

        // Also re-queue additional entities
        for entityType in TestEntityID.allCases {
            if existingEntities[entityType] == true {
                let recordID = SyncCoordinator.shared.recordID(for: entityType.entityName, id: entityType.uuid)
                SyncCoordinator.shared.markPendingSave(recordID: recordID)
            }
        }

        let totalCount = 10 + additionalEntityCount
        lastAction = "Re-queued \(totalCount) test records for sync"
        refreshStatus()
    }

    // MARK: - Photo Testing (Phase 2)

    private func createTestPhotoEvent() async {
        isCreatingPhoto = true
        lastAction = nil

        // Get the test profile
        let profileFetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")
        profileFetch.predicate = NSPredicate(format: "id == %@", testProfileID as CVarArg)
        profileFetch.fetchLimit = 1

        do {
            guard let profile = try viewContext.fetch(profileFetch).first else {
                lastAction = "Error: Test profile not found"
                isCreatingPhoto = false
                return
            }

            // Create photo event with actual test image
            guard SyncTestFixtures.createTestPhotoEventWithImage(in: viewContext, for: profile) != nil else {
                lastAction = "Error: Failed to create test image"
                isCreatingPhoto = false
                return
            }

            try viewContext.save()

            // Queue event for sync
            let eventRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyEvent", id: testPhotoEventID)
            SyncCoordinator.shared.markPendingSave(recordID: eventRecordID)

            lastAction = "Created photo event + test image"
            refreshStatus()
        } catch {
            lastAction = "Error: \(error.localizedDescription)"
        }

        isCreatingPhoto = false
    }

    private func uploadTestPhoto() async {
        isUploadingPhoto = true
        lastAction = nil

        guard let photoURL = SyncTestFixtures.testPhotoLocalURL(),
              FileManager.default.fileExists(atPath: photoURL.path) else {
            lastAction = "Error: Test photo file not found"
            isUploadingPhoto = false
            return
        }

        do {
            let result = try await cloudKitService.uploadPhoto(localURL: photoURL, eventId: testPhotoEventID)
            lastAction = "Photo uploaded to CloudKit"

            // Update event with cloud sync status
            let eventFetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyEvent")
            eventFetch.predicate = NSPredicate(format: "id == %@", testPhotoEventID as CVarArg)
            eventFetch.fetchLimit = 1

            if let event = try viewContext.fetch(eventFetch).first {
                event.setValue(true, forKey: "cloudPhotoSynced")
                event.setValue(result.ownerName, forKey: "cloudPhotoOwner")
                try viewContext.save()

                // Re-queue event to sync the updated cloudPhotoSynced flag
                let eventRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyEvent", id: testPhotoEventID)
                SyncCoordinator.shared.markPendingSave(recordID: eventRecordID)
            }

            refreshStatus()
        } catch {
            lastAction = "Error: \(error.localizedDescription)"
        }

        isUploadingPhoto = false
    }

    private func deleteTestData() async {
        isDeleting = true
        lastAction = nil

        // Queue deletions for CloudKit using record IDs
        let profileRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyProfile", id: testProfileID)
        SyncCoordinator.shared.markPendingDelete(recordID: profileRecordID)

        for testEvent in TestEventID.allCases {
            let eventRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyEvent", id: testEvent.uuid)
            SyncCoordinator.shared.markPendingDelete(recordID: eventRecordID)
        }

        let weightRecordID = SyncCoordinator.shared.recordID(for: "CDWeightMeasurement", id: testWeightID)
        SyncCoordinator.shared.markPendingDelete(recordID: weightRecordID)

        // Also queue deletions for additional entities
        for entityType in TestEntityID.allCases {
            if existingEntities[entityType] == true {
                let recordID = SyncCoordinator.shared.recordID(for: entityType.entityName, id: entityType.uuid)
                SyncCoordinator.shared.markPendingDelete(recordID: recordID)
            }
        }

        // Milestone
        let milestoneRecordID = SyncCoordinator.shared.recordID(for: "CDMilestone", id: testMilestoneID)
        SyncCoordinator.shared.markPendingDelete(recordID: milestoneRecordID)

        // Photo event
        let photoEventRecordID = SyncCoordinator.shared.recordID(for: "CDPuppyEvent", id: testPhotoEventID)
        SyncCoordinator.shared.markPendingDelete(recordID: photoEventRecordID)

        // Delete test photo file from local storage
        SyncTestFixtures.deleteTestPhotoFile()

        // Now delete locally
        SyncTestFixtures.deleteAllTestData(in: viewContext)

        // Also delete photo event specifically
        let photoEventFetch = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyEvent")
        photoEventFetch.predicate = NSPredicate(format: "id == %@", testPhotoEventID as CVarArg)
        if let photoEvents = try? viewContext.fetch(photoEventFetch) {
            for event in photoEvents {
                viewContext.delete(event)
            }
        }

        do {
            try viewContext.save()
            lastAction = "Deleted test data"
            refreshStatus()
        } catch {
            lastAction = "Error: \(error.localizedDescription)"
        }

        isDeleting = false
    }

    private func forceSync() async {
        isSyncing = true
        lastAction = nil

        await SyncCoordinator.shared.sync()

        lastAction = "Sync complete"
        refreshStatus()
        isSyncing = false
    }

    private func purgeFromCloudKit() async {
        isPurgingCloudKit = true
        lastAction = nil

        let container = CKContainer(identifier: "iCloud.nl.jaapstronks.Otis")
        let privateDB = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)

        var deletedCount = 0
        var errors: [String] = []

        // Build record IDs for test data
        var recordIDsToDelete: [CKRecord.ID] = []

        // Profile
        let profileRecordID = CKRecord.ID(
            recordName: "CD_CDPuppyProfile:\(testProfileID.uuidString)",
            zoneID: zoneID
        )
        recordIDsToDelete.append(profileRecordID)

        // Events
        for testEvent in TestEventID.allCases {
            let eventRecordID = CKRecord.ID(
                recordName: "CD_CDPuppyEvent:\(testEvent.uuid.uuidString)",
                zoneID: zoneID
            )
            recordIDsToDelete.append(eventRecordID)
        }

        // Weight
        let weightRecordID = CKRecord.ID(
            recordName: "CD_CDWeightMeasurement:\(testWeightID.uuidString)",
            zoneID: zoneID
        )
        recordIDsToDelete.append(weightRecordID)

        // Photo event
        let photoRecordID = CKRecord.ID(
            recordName: "CD_CDPuppyEvent:\(testPhotoEventID.uuidString)",
            zoneID: zoneID
        )
        recordIDsToDelete.append(photoRecordID)

        // Milestone
        let milestoneRecordID = CKRecord.ID(
            recordName: "CD_CDMilestone:\(testMilestoneID.uuidString)",
            zoneID: zoneID
        )
        recordIDsToDelete.append(milestoneRecordID)

        // All additional entity types
        for entityType in TestEntityID.allCases {
            let recordID = CKRecord.ID(
                recordName: "CD_\(entityType.entityName):\(entityType.uuid.uuidString)",
                zoneID: zoneID
            )
            recordIDsToDelete.append(recordID)
        }

        // EventMedia record for test photo (stored separately from event)
        let eventMediaRecordID = CKRecord.ID(
            recordName: "media-\(testPhotoEventID.uuidString)",
            zoneID: zoneID
        )
        recordIDsToDelete.append(eventMediaRecordID)

        // Delete each record
        for recordID in recordIDsToDelete {
            do {
                try await privateDB.deleteRecord(withID: recordID)
                deletedCount += 1
            } catch let error as CKError where error.code == .unknownItem {
                // Record doesn't exist - that's fine
                continue
            } catch {
                errors.append(error.localizedDescription)
            }
        }

        if errors.isEmpty {
            lastAction = "Purged \(deletedCount) records from CloudKit"
        } else {
            lastAction = "Purged \(deletedCount), errors: \(errors.count)"
        }

        isPurgingCloudKit = false
    }

    private func copyLogCommand() {
        let command = SyncTestFixtures.testLogStreamCommand
        UIPasteboard.general.string = command
        lastAction = "Copied to clipboard"
    }
}

#Preview {
    Form {
        if #available(iOS 17.0, *) {
            SyncTestSection()
        }
    }
    .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
}

#endif
