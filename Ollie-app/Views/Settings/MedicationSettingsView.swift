//
//  MedicationSettingsView.swift
//  Otis-app
//
//  List of medications with add/edit/delete
//

import SwiftUI
import OtisShared

/// Settings view for managing medications
struct MedicationSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var medicationStore: MedicationStore
    var profileId: UUID? = nil
    @State private var showingAddSheet = false
    @State private var medicationToEdit: Medication?
    @State private var showingDeleteConfirmation = false
    @State private var medicationToDelete: Medication?

    /// The profile being edited (looked up by ID or falls back to active)
    private var targetProfile: PuppyProfile? {
        if let id = profileId {
            return profileStore.profile(for: id)
        }
        return profileStore.profile
    }

    private var medications: [Medication] {
        targetProfile?.medicationSchedule.medications ?? []
    }

    var body: some View {
        List {
            if medications.isEmpty {
                emptyState
            } else {
                medicationsList
            }
        }
        .navigationTitle(Strings.Medications.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Strings.Medications.addMedication)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditMedicationSheet(
                profileStore: profileStore,
                profileId: profileId,
                medication: nil
            )
        }
        .sheet(item: $medicationToEdit) { medication in
            AddEditMedicationSheet(
                profileStore: profileStore,
                profileId: profileId,
                medication: medication
            )
        }
        .alert(Strings.Medications.deleteConfirmTitle, isPresented: $showingDeleteConfirmation) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Common.delete, role: .destructive) {
                if let medication = medicationToDelete {
                    profileStore.deleteMedication(id: medication.id, for: profileId)
                }
            }
        } message: {
            Text(Strings.Medications.deleteConfirmMessage)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "pills")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text(Strings.Medications.noMedications)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(Strings.Medications.noMedicationsHint)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                Button {
                    showingAddSheet = true
                } label: {
                    Label(Strings.Medications.addMedication, systemImage: "plus.circle.fill")
                }
                .buttonStyle(.glassPill(tint: .accent))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Medications List

    @ViewBuilder
    private var medicationsList: some View {
        Section {
            ForEach(medications) { medication in
                NavigationLink {
                    MedicationDetailView(
                        medication: medication,
                        profileStore: profileStore,
                        medicationStore: medicationStore,
                        profileId: profileId
                    )
                } label: {
                    MedicationRow(medication: medication)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        medicationToDelete = medication
                        showingDeleteConfirmation = true
                    } label: {
                        Label(Strings.Common.delete, systemImage: "trash")
                    }

                    Button {
                        medicationToEdit = medication
                    } label: {
                        Label(Strings.Common.edit, systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        } footer: {
            Text(Strings.Medications.settingsFooter)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        // Overall adherence section
        if !medications.isEmpty {
            Section {
                weeklyAdherenceRow
            } header: {
                Text(Strings.Medications.thisWeek)
            }
        }

        Section {
            Button {
                showingAddSheet = true
            } label: {
                Label(Strings.Medications.addMedication, systemImage: "plus")
            }
        }
    }

    // MARK: - Weekly Adherence

    @ViewBuilder
    private var weeklyAdherenceRow: some View {
        let adherence = calculateWeeklyAdherence()

        HStack {
            Text(Strings.Medications.adherence)

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForAdherence(adherence))
                        .frame(width: geometry.size.width * CGFloat(adherence) / 100)
                }
            }
            .frame(width: 80, height: 8)

            Text("\(adherence)%")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func calculateWeeklyAdherence() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var expected = 0
        var taken = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            for medication in medications where medication.isActive && medication.isScheduledFor(date: date) {
                expected += medication.times.count

                for time in medication.times {
                    if medicationStore.isComplete(medicationId: medication.id, timeId: time.id, for: date) {
                        taken += 1
                    }
                }
            }
        }

        return expected > 0 ? Int(Double(taken) / Double(expected) * 100) : 100
    }

    private func colorForAdherence(_ percentage: Int) -> Color {
        switch percentage {
        case 90...100: return .otisSuccess
        case 70..<90: return .otisAccent
        case 50..<70: return .orange
        default: return .otisWarning
        }
    }
}

// MARK: - Medication Row

private struct MedicationRow: View {
    let medication: Medication

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: medication.icon)
                .font(.title2)
                .foregroundStyle(medication.isActive ? Color.otisAccent : .secondary)
                .frame(width: 32)

            // Name and schedule
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.body)
                    .foregroundStyle(medication.isActive ? .primary : .secondary)

                HStack(spacing: 8) {
                    Text(medication.recurrence.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !medication.times.isEmpty {
                        Text(formatTimes(medication.times))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Active/Paused indicator
            Text(medication.isActive ? Strings.Medications.active : Strings.Medications.paused)
                .font(.caption)
                .foregroundStyle(medication.isActive ? Color.otisSuccess : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(medication.isActive ? Color.otisSuccess.opacity(0.15) : Color.secondary.opacity(0.1))
                )
        }
    }

    private func formatTimes(_ times: [MedicationTime]) -> String {
        times.map { $0.targetTime }.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("MedicationSettingsView") {
    NavigationStack {
        MedicationSettingsView(
            profileStore: ProfileStore(),
            medicationStore: MedicationStore()
        )
    }
}
