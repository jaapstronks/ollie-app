//
//  MedicationReminderCard.swift
//  Ollie-app
//
//  Card showing pending medication with swipe-to-complete
//

import SwiftUI
import OllieShared

/// Card displaying a pending medication with swipe-to-complete slider
struct MedicationReminderCard: View {
    let medication: Medication
    let time: MedicationTime
    let scheduledDate: Date
    let isOverdue: Bool
    let onComplete: (String) -> Void  // Now passes medication name for timeline

    @State private var isCompleting = false
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 1.0
    @State private var cardOffset: CGFloat = 0
    @State private var showCompletedBanner = false
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
        ZStack {
            // Main card content
            cardContent
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .offset(x: cardOffset)

            // Completed overlay
            if showCompletedBanner {
                completedOverlay
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showCompletedBanner)
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            if let instructions = medication.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            SwipeToCompleteSlider(
                label: Strings.Medications.markAsDone,
                icon: medication.icon,
                tintColor: tintColor,
                onComplete: handleComplete
            )
        }
        .padding()
        .glassStatusCard(tintColor: tintColor)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Completed Overlay

    @ViewBuilder
    private var completedOverlay: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ollieSuccess)
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(Strings.Medications.completed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.ollieSuccess.opacity(0.6))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassStatusCard(tintColor: .ollieSuccess)
    }

    // MARK: - Header Row

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tintColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: medication.icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(tintColor)
            }

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
                            .background(Capsule().fill(Color.ollieWarning))
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func handleComplete() {
        guard !isCompleting else { return }
        isCompleting = true

        // Show completed banner
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCompletedBanner = true
        }

        // Animate card out after brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardScale = 0.9
                cardOpacity = 0
                cardOffset = -20
            }

            // Notify parent to log event
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onComplete(medication.name)
            }
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

// MARK: - Strings Extension

extension Strings.Medications {
    static let completed = String(localized: "Done! Added to timeline")
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
            onComplete: { name in print("Completed: \(name)") }
        )

        MedicationReminderCard(
            medication: Medication(
                name: "Flea & Tick",
                icon: "ant.fill"
            ),
            time: MedicationTime(targetTime: "09:00"),
            scheduledDate: Date().addingTimeInterval(-3600),
            isOverdue: true,
            onComplete: { name in print("Completed: \(name)") }
        )
    }
    .padding()
}
