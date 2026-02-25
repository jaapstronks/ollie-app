//
//  MedicationSettingsView.swift
//  Ollie-app
//
//  List of medications with add/edit/delete
//

import SwiftUI
import OllieShared

/// Settings view for managing medications
struct MedicationSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @State private var showingAddSheet = false
    @State private var medicationToEdit: Medication?
    @State private var showingDeleteConfirmation = false
    @State private var medicationToDelete: Medication?

    private var medications: [Medication] {
        profileStore.profile?.medicationSchedule.medications ?? []
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
                medication: nil
            )
        }
        .sheet(item: $medicationToEdit) { medication in
            AddEditMedicationSheet(
                profileStore: profileStore,
                medication: medication
            )
        }
        .alert(Strings.Medications.deleteConfirmTitle, isPresented: $showingDeleteConfirmation) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Common.delete, role: .destructive) {
                if let medication = medicationToDelete {
                    profileStore.deleteMedication(id: medication.id)
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
                MedicationRow(
                    medication: medication,
                    onToggleActive: {
                        profileStore.toggleMedicationActive(id: medication.id)
                    },
                    onEdit: {
                        medicationToEdit = medication
                    }
                )
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
            Text(Strings.Medications.addMedication)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section {
            Button {
                showingAddSheet = true
            } label: {
                Label(Strings.Medications.addMedication, systemImage: "plus")
            }
        }
    }
}

// MARK: - Medication Row

private struct MedicationRow: View {
    let medication: Medication
    let onToggleActive: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: medication.icon)
                    .font(.title2)
                    .foregroundStyle(medication.isActive ? Color.ollieAccent : .secondary)
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
                    .foregroundStyle(medication.isActive ? Color.ollieSuccess : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(medication.isActive ? Color.ollieSuccess.opacity(0.15) : Color.secondary.opacity(0.1))
                    )

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatTimes(_ times: [MedicationTime]) -> String {
        times.map { $0.targetTime }.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("MedicationSettingsView") {
    NavigationStack {
        MedicationSettingsView(profileStore: ProfileStore())
    }
}
