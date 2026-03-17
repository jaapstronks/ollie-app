//
//  MedicationLogSheet.swift
//  Otis-app
//
//  Sheet for quick-logging medications from the quick log bar
//

import SwiftUI
import OtisShared

/// Sheet for selecting and logging a medication
struct MedicationLogSheet: View {
    var profileStore: ProfileStore
    var medicationStore: MedicationStore
    let onComplete: (Medication) -> Void
    let onCancel: () -> Void

    @State private var selectedTime: Date = Date()
    @State private var showingTimePicker = false
    @State private var note: String = ""

    private var activeMedications: [Medication] {
        profileStore.profile?.medicationSchedule.medications.filter { $0.isActive } ?? []
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            SheetHeader(
                title: Strings.Medications.logMedication,
                icon: .custom(systemName: "pills.fill", color: .otisAccent)
            )

            if activeMedications.isEmpty {
                emptyState
            } else {
                medicationList
            }
        }
        .padding()
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(Strings.Medications.noMedications)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(Strings.Medications.noMedicationsHint)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(Strings.Common.cancel, action: onCancel)
                .buttonStyle(.glassPill(tint: .none))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Medication List

    @ViewBuilder
    private var medicationList: some View {
        VStack(spacing: 12) {
            Text(Strings.Medications.whichMedication)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(activeMedications) { medication in
                        MedicationSelectRow(
                            medication: medication,
                            onSelect: {
                                logMedication(medication)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 300)

            // Time picker
            TimePickerSection(
                selectedTime: $selectedTime,
                showingTimePicker: $showingTimePicker
            )

            // Note field
            LogSheetNoteField(
                note: $note,
                accessibilityIdentifier: "MEDICATION_LOG_NOTE_FIELD"
            )

            // Cancel button
            Button(Strings.Common.cancel, action: onCancel)
                .buttonStyle(.glassPill(tint: .none))
        }
    }

    // MARK: - Actions

    private func logMedication(_ medication: Medication) {
        // Find the next pending time or use first time
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)

        // Find appropriate time slot
        if let pendingTime = medication.times.first(where: { time in
            !medicationStore.isComplete(medicationId: medication.id, timeId: time.id, for: today)
        }) {
            // Mark specific time as complete
            medicationStore.markComplete(
                medicationId: medication.id,
                timeId: pendingTime.id,
                for: today
            )
        } else if let firstTime = medication.times.first {
            // No pending times - mark first as complete (allows manual logging)
            medicationStore.markComplete(
                medicationId: medication.id,
                timeId: firstTime.id,
                for: today
            )
        }

        HapticFeedback.success()
        onComplete(medication)
    }
}

// MARK: - Medication Select Row

private struct MedicationSelectRow: View {
    let medication: Medication
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.otisAccent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: medication.icon)
                        .font(.title3)
                        .foregroundStyle(Color.otisAccent)
                }

                // Name and instructions
                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    if let instructions = medication.instructions, !instructions.isEmpty {
                        Text(instructions)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Strings Extension

extension Strings.Medications {
    static let logMedication = String(localized: "Log Medication", table: "Medications")
    static let whichMedication = String(localized: "Which medication?", table: "Medications")
}

// MARK: - Preview

#Preview("MedicationLogSheet") {
    MedicationLogSheet(
        profileStore: ProfileStore(),
        medicationStore: MedicationStore(),
        onComplete: { med in print("Completed: \(med.name)") },
        onCancel: {}
    )
}
