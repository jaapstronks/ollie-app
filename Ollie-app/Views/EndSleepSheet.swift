//
//  EndSleepSheet.swift
//  Ollie-app
//
//  Sheet for ending an ongoing sleep session with wake-up time adjustment

import SwiftUI
import OllieShared

/// Sheet for logging a wake-up event to end an ongoing sleep session
struct EndSleepSheet: View {
    let sleepStartTime: Date
    let onSave: (Date) -> Void
    let onCancel: () -> Void

    @State private var wakeUpTime: Date = Date()
    @State private var showingTimePicker: Bool = false

    private var currentDuration: String {
        let minutes = wakeUpTime.minutesSince(sleepStartTime)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h\(mins)m"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.title)
                    .foregroundColor(.yellow)

                Text(Strings.SleepSession.endSleep)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 8)

            // Sleep duration summary
            VStack(spacing: 8) {
                Text(Strings.SleepStatus.sleepingFor(duration: currentDuration))
                    .font(.headline)

                Text(Strings.SleepStatus.started(time: sleepStartTime.timeString))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(LayoutConstants.cornerRadiusM)

            // Wake-up time section
            VStack(spacing: 12) {
                Text(Strings.SleepSession.wakeUpTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Tappable time display
                Button {
                    showingTimePicker.toggle()
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(wakeUpTime.timeString)
                            .font(.title3)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                // Quick adjustment buttons (adjust wake-up time backwards)
                HStack(spacing: 10) {
                    TimeAdjustButton(minutes: -5, selectedTime: $wakeUpTime)
                    TimeAdjustButton(minutes: -10, selectedTime: $wakeUpTime)
                    TimeAdjustButton(minutes: -15, selectedTime: $wakeUpTime)
                }

                // Time picker (expandable)
                if showingTimePicker {
                    DatePicker(
                        Strings.SleepSession.wakeUpTime,
                        selection: $wakeUpTime,
                        in: sleepStartTime...Date(),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 16) {
                Button(Strings.Common.cancel) {
                    onCancel()
                }
                .foregroundColor(.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("END_SLEEP_CANCEL_BUTTON")

                Button {
                    HapticFeedback.success()
                    onSave(wakeUpTime)
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text(Strings.SleepSession.logWakeUp)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .cornerRadius(LayoutConstants.cornerRadiusM)
                }
                .accessibilityIdentifier("END_SLEEP_SAVE_BUTTON")
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: showingTimePicker)
    }
}

// MARK: - Previews

#Preview("End Sleep Sheet") {
    EndSleepSheet(
        sleepStartTime: Date().addingTimeInterval(-45 * 60),
        onSave: { time in
            print("Wake up at: \(time)")
        },
        onCancel: {}
    )
}

#Preview("Long Sleep") {
    EndSleepSheet(
        sleepStartTime: Date().addingTimeInterval(-2 * 60 * 60),
        onSave: { time in
            print("Wake up at: \(time)")
        },
        onCancel: {}
    )
}
