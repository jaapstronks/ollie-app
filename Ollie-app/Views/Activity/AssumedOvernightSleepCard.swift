//
//  AssumedOvernightSleepCard.swift
//  Ollie-app
//
//  Card shown when the user likely forgot to log overnight sleep
//  Suggests a sleep start time and allows confirming or dismissing

import SwiftUI
import OllieShared

/// Card shown when the app detects the user likely forgot to log overnight sleep
/// Displays a suggested sleep start time and allows user to confirm, adjust, or dismiss
struct AssumedOvernightSleepCard: View {
    let suggestedSleepStart: Date
    let minutesSleeping: Int
    let puppyName: String
    let onConfirmSleeping: (Date) -> Void
    let onConfirmAwake: (Date, Date) -> Void
    let onDismiss: () -> Void

    @State private var adjustedSleepStart: Date
    @State private var showTimePicker = false

    init(
        suggestedSleepStart: Date,
        minutesSleeping: Int,
        puppyName: String,
        onConfirmSleeping: @escaping (Date) -> Void,
        onConfirmAwake: @escaping (Date, Date) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.suggestedSleepStart = suggestedSleepStart
        self.minutesSleeping = minutesSleeping
        self.puppyName = puppyName
        self.onConfirmSleeping = onConfirmSleeping
        self.onConfirmAwake = onConfirmAwake
        self.onDismiss = onDismiss
        _adjustedSleepStart = State(initialValue: suggestedSleepStart)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.ollieSleep)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(Strings.AssumedSleep.title(name: puppyName))
                        .font(.headline)

                    // Subtitle with suggested time
                    Text(Strings.AssumedSleep.subtitle(time: adjustedSleepStart.timeString))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            // Time adjustment row
            HStack {
                Text(Strings.AssumedSleep.fellAsleepAt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTimePicker.toggle()
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack(spacing: 4) {
                        Text(adjustedSleepStart.formatted(date: .abbreviated, time: .shortened))
                            .font(.body.monospacedDigit())
                        Image(systemName: showTimePicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showTimePicker ? Color.ollieSleep.opacity(0.15) : Color(UIColor.tertiarySystemBackground))
                    .foregroundStyle(showTimePicker ? Color.ollieSleep : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            // Time picker (expanded)
            if showTimePicker {
                DatePicker(
                    "",
                    selection: $adjustedSleepStart,
                    in: Date().addingDays(-1)...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }

            // Action buttons
            HStack(spacing: 12) {
                // Still sleeping button
                Button {
                    onConfirmSleeping(adjustedSleepStart)
                } label: {
                    Label(Strings.AssumedSleep.stillSleeping, systemImage: "moon.zzz.fill")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.ollieSleep.opacity(0.15))
                        .foregroundStyle(Color.ollieSleep)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                // Already awake button
                Button {
                    onConfirmAwake(adjustedSleepStart, Date())
                } label: {
                    Label(Strings.AssumedSleep.alreadyAwake, systemImage: "sun.max.fill")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.ollieSuccess.opacity(0.15))
                        .foregroundStyle(Color.ollieSuccess)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.AssumedSleep.accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("Assumed Overnight Sleep") {
    VStack {
        AssumedOvernightSleepCard(
            suggestedSleepStart: Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date().addingDays(-1))!,
            minutesSleeping: 480,
            puppyName: "Luna",
            onConfirmSleeping: { _ in print("Confirmed sleeping") },
            onConfirmAwake: { _, _ in print("Confirmed awake") },
            onDismiss: { print("Dismissed") }
        )
        Spacer()
    }
    .padding()
}
