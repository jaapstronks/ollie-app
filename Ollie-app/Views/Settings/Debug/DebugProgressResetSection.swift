//
//  DebugProgressResetSection.swift
//  Otis-app
//
//  Debug section for resetting various progress data for testing

#if DEBUG

import SwiftUI
import CoreData
import OtisShared

/// Debug section for resetting training, socialization, and milestone progress
struct DebugProgressResetSection: View {
    @Environment(SkillProgressStore.self) var skillProgressStore
    @Environment(SocializationStore.self) var socializationStore
    @Environment(MilestoneStore.self) var milestoneStore

    @State private var showResetTrainingConfirm = false
    @State private var showResetSocializationConfirm = false
    @State private var showResetMilestonesConfirm = false

    @State private var isResettingTraining = false
    @State private var isResettingSocialization = false
    @State private var isResettingMilestones = false

    @State private var trainingResult: String?
    @State private var socializationResult: String?
    @State private var milestonesResult: String?

    var body: some View {
        Section {
            // Reset Training Progress
            Button(role: .destructive) {
                showResetTrainingConfirm = true
            } label: {
                HStack {
                    Label("Reset Training Progress", systemImage: "graduationcap.fill")
                    Spacer()
                    if isResettingTraining {
                        ProgressView()
                    } else {
                        Text("\(skillProgressStore.startedSkillCount) skills")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isResettingTraining)

            if let result = trainingResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
            }

            // Reset Socialization Progress
            Button(role: .destructive) {
                showResetSocializationConfirm = true
            } label: {
                HStack {
                    Label("Reset Socialization Progress", systemImage: "person.2.fill")
                    Spacer()
                    if isResettingSocialization {
                        ProgressView()
                    } else {
                        let count = socializationStore.allExposures.count + socializationStore.comfortableItems.count
                        Text("\(count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isResettingSocialization)

            if let result = socializationResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
            }

            // Reset Medical Milestones
            Button(role: .destructive) {
                showResetMilestonesConfirm = true
            } label: {
                HStack {
                    Label("Reset Medical Milestones", systemImage: "heart.text.square.fill")
                    Spacer()
                    if isResettingMilestones {
                        ProgressView()
                    } else {
                        Text("\(milestoneStore.completedCount)/\(milestoneStore.totalCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isResettingMilestones)

            if let result = milestonesResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
            }
        } header: {
            Label("Reset Progress", systemImage: "arrow.counterclockwise")
        } footer: {
            Text("Reset specific progress data for testing. This deletes local and synced data.")
        }
        .alert("Reset Training Progress?", isPresented: $showResetTrainingConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Training", role: .destructive) {
                Task { await resetTrainingProgress() }
            }
        } message: {
            Text("This will delete all skill progress, including mastered skills and training sessions. This cannot be undone.")
        }
        .alert("Reset Socialization Progress?", isPresented: $showResetSocializationConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Socialization", role: .destructive) {
                Task { await resetSocializationProgress() }
            }
        } message: {
            Text("This will delete all exposures, comfortable items, and early milestones. This cannot be undone.")
        }
        .alert("Reset Medical Milestones?", isPresented: $showResetMilestonesConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Milestones", role: .destructive) {
                Task { await resetMedicalMilestones() }
            }
        } message: {
            Text("This will delete all medical milestones and their completion status. Default milestones will be re-created. This cannot be undone.")
        }
    }

    // MARK: - Reset Actions

    private func resetTrainingProgress() async {
        isResettingTraining = true
        trainingResult = nil

        let context = PersistenceController.shared.viewContext

        do {
            // Fetch all skill progress records
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDSkillProgress")
            let records = try context.fetch(fetchRequest)
            let count = records.count

            // Queue CloudKit deletions and delete locally
            for record in records {
                if let id = record.value(forKey: "id") as? UUID {
                    let recordID = SyncCoordinator.shared.recordID(for: "CD_CDSkillProgress", id: id)
                    SyncCoordinator.shared.markPendingDelete(recordID: recordID)
                }
                context.delete(record)
            }

            try context.save()

            // Reload store
            skillProgressStore.performInitialLoad()

            trainingResult = "✓ Deleted \(count) skill progress records"
        } catch {
            trainingResult = "Error: \(error.localizedDescription)"
        }

        isResettingTraining = false
    }

    private func resetSocializationProgress() async {
        isResettingSocialization = true
        socializationResult = nil

        let context = PersistenceController.shared.viewContext

        do {
            var totalDeleted = 0

            // Delete exposures
            let exposureRequest = NSFetchRequest<NSManagedObject>(entityName: "CDExposure")
            let exposures = try context.fetch(exposureRequest)
            for record in exposures {
                if let id = record.value(forKey: "id") as? UUID {
                    let recordID = SyncCoordinator.shared.recordID(for: "CD_CDExposure", id: id)
                    SyncCoordinator.shared.markPendingDelete(recordID: recordID)
                }
                context.delete(record)
            }
            totalDeleted += exposures.count

            // Delete comfortable items
            let comfortableRequest = NSFetchRequest<NSManagedObject>(entityName: "CDComfortableItem")
            let comfortableItems = try context.fetch(comfortableRequest)
            for record in comfortableItems {
                if let id = record.value(forKey: "id") as? UUID {
                    let recordID = SyncCoordinator.shared.recordID(for: "CD_CDComfortableItem", id: id)
                    SyncCoordinator.shared.markPendingDelete(recordID: recordID)
                }
                context.delete(record)
            }
            totalDeleted += comfortableItems.count

            // Delete early milestones
            let earlyMilestoneRequest = NSFetchRequest<NSManagedObject>(entityName: "CDEarlyMilestone")
            let earlyMilestones = try context.fetch(earlyMilestoneRequest)
            for record in earlyMilestones {
                if let id = record.value(forKey: "id") as? UUID {
                    let recordID = SyncCoordinator.shared.recordID(for: "CD_CDEarlyMilestone", id: id)
                    SyncCoordinator.shared.markPendingDelete(recordID: recordID)
                }
                context.delete(record)
            }
            totalDeleted += earlyMilestones.count

            try context.save()

            // Reload store
            socializationStore.performInitialLoad()

            socializationResult = "✓ Deleted \(totalDeleted) socialization records"
        } catch {
            socializationResult = "Error: \(error.localizedDescription)"
        }

        isResettingSocialization = false
    }

    private func resetMedicalMilestones() async {
        isResettingMilestones = true
        milestonesResult = nil

        let context = PersistenceController.shared.viewContext

        do {
            // Fetch all milestone records
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDMilestone")
            let records = try context.fetch(fetchRequest)
            let count = records.count

            // Queue CloudKit deletions and delete locally
            for record in records {
                if let id = record.value(forKey: "id") as? UUID {
                    let recordID = SyncCoordinator.shared.recordID(for: "CD_CDMilestone", id: id)
                    SyncCoordinator.shared.markPendingDelete(recordID: recordID)
                }
                context.delete(record)
            }

            try context.save()

            // Reload store and seed defaults
            milestoneStore.performInitialLoad()
            milestoneStore.seedDefaultMilestonesIfNeeded()

            milestonesResult = "✓ Deleted \(count) milestones, re-seeded defaults"
        } catch {
            milestonesResult = "Error: \(error.localizedDescription)"
        }

        isResettingMilestones = false
    }
}

#Preview {
    Form {
        DebugProgressResetSection()
    }
    .environment(SkillProgressStore())
    .environment(SocializationStore())
    .environment(MilestoneStore())
}

#endif
