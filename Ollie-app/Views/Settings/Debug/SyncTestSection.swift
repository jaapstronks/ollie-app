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

    @State private var testProfileExists = false
    @State private var testEventCount = 0
    @State private var isCreating = false
    @State private var isDeleting = false
    @State private var isSyncing = false
    @State private var lastAction: String?
    @State private var showDeleteConfirm = false
    @State private var showPurgeConfirm = false
    @State private var isPurgingCloudKit = false
    @State private var pendingChanges = 0

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

            HStack {
                Label("Pending Changes", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                Text("\(pendingChanges)")
                    .foregroundStyle(pendingChanges > 0 ? .orange : .secondary)
            }

            // Create test data
            Button {
                Task { await createTestData() }
            } label: {
                HStack {
                    Label("Create Test Data", systemImage: "plus.circle")
                    Spacer()
                    if isCreating {
                        ProgressView()
                    }
                }
            }
            .disabled(isCreating || testProfileExists)

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

        lastAction = "Re-queued 10 test records for sync"
        refreshStatus()
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

        // Now delete locally
        SyncTestFixtures.deleteAllTestData(in: viewContext)

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
