//
//  MedicationReminderCard.swift
//  Ollie-app
//
//  Card showing pending medication with swipe-to-complete
//

import SwiftUI

/// Card displaying a pending medication with swipe-to-complete slider
struct MedicationReminderCard: View {
    let medication: Medication
    let time: MedicationTime
    let scheduledDate: Date
    let isOverdue: Bool
    let onComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var tintColor: Color {
        isOverdue ? .ollieWarning : .ollieAccent
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            headerRow

            // Instructions (if present)
            if let instructions = medication.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Swipe to complete
            SwipeToCompleteSlider(
                label: Strings.Medications.markAsDone,
                icon: medication.icon,
                tintColor: tintColor,
                onComplete: onComplete
            )
        }
        .padding()
        .glassStatusCard(tintColor: tintColor)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 12) {
            // Medication icon
            ZStack {
                Circle()
                    .fill(tintColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: medication.icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(tintColor)
            }

            // Name and time
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(timeFormatter.string(from: scheduledDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if isOverdue {
                        Text(Strings.Medications.overdue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.ollieWarning)
                            )
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "\(medication.name), \(Strings.Medications.scheduled) \(timeFormatter.string(from: scheduledDate))"
        if isOverdue {
            label += ", \(Strings.Medications.overdue)"
        }
        if let instructions = medication.instructions {
            label += ". \(instructions)"
        }
        return label
    }
}

// MARK: - Preview

#Preview("MedicationReminderCard") {
    VStack(spacing: 16) {
        MedicationReminderCard(
            medication: Medication(
                name: "Heartgard",
                instructions: "Give with food",
                icon: "pills.fill",
                times: [MedicationTime(targetTime: "08:00")]
            ),
            time: MedicationTime(targetTime: "08:00"),
            scheduledDate: Date(),
            isOverdue: false,
            onComplete: { print("Completed!") }
        )

        MedicationReminderCard(
            medication: Medication(
                name: "Flea & Tick",
                icon: "ant.fill"
            ),
            time: MedicationTime(targetTime: "09:00"),
            scheduledDate: Date().addingTimeInterval(-3600),
            isOverdue: true,
            onComplete: { print("Completed!") }
        )
    }
    .padding()
}
