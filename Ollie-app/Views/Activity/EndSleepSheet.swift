//
//  EndSleepSheet.swift
//  Otis-app
//
//  Sheet for ending an ongoing sleep session with wake-up time adjustment

import SwiftUI
import OtisShared

/// Sheet for logging a wake-up event to end an ongoing sleep session
struct EndSleepSheet: View {
    let sleepStartTime: Date
    let onSave: (Date) -> Void
    let onCancel: () -> Void
    let onStartWalk: (() -> Void)?

    init(
        sleepStartTime: Date,
        onSave: @escaping (Date) -> Void,
        onCancel: @escaping () -> Void,
        onStartWalk: (() -> Void)? = nil
    ) {
        self.sleepStartTime = sleepStartTime
        self.onSave = onSave
        self.onCancel = onCancel
        self.onStartWalk = onStartWalk
    }

    @State private var wakeUpTime: Date = Date()
    @State private var showingTimePicker: Bool = false
    @State private var isWakeUpLogged: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentDurationMinutes: Int {
        wakeUpTime.minutesSince(sleepStartTime)
    }

    private var currentDuration: String {
        let minutes = currentDurationMinutes
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

    private var sleepDurationText: String {
        let minutes = currentDurationMinutes
        if minutes <= 1 {
            return Strings.SleepStatus.justFellAsleep
        } else if minutes <= 15 {
            return Strings.SleepStatus.sleepingBriefly(duration: currentDuration)
        }
        return Strings.SleepStatus.sleepingFor(duration: currentDuration)
    }

    var body: some View {
        VStack(spacing: 20) {
            if isWakeUpLogged {
                // Post-wake state: offer to start a walk
                postWakeContent
            } else {
                // Initial state: wake-up time adjustment
                wakeUpContent
            }
        }
        .padding()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showingTimePicker)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: isWakeUpLogged)
    }

    // MARK: - Wake-up Content (Initial State)

    @ViewBuilder
    private var wakeUpContent: some View {
        // Header
        HStack(spacing: 12) {
            Image(systemName: "sun.max.fill")
                .font(.title)
                .foregroundStyle(.yellow)

            Text(Strings.SleepSession.endSleep)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding(.top, 8)

        // Sleep duration summary
        VStack(spacing: 8) {
            Text(sleepDurationText)
                .font(.headline)

            Text(Strings.SleepStatus.started(time: sleepStartTime.timeString))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.otisSleep.opacity(0.1))
        .cornerRadius(LayoutConstants.cornerRadiusM)

        // Wake-up time section
        VStack(spacing: 12) {
            Text(Strings.SleepSession.wakeUpTime)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Tappable time display
            Button {
                showingTimePicker.toggle()
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(wakeUpTime.timeString)
                        .font(.title3)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))
            }
        }

        Spacer()

        // Action buttons
        HStack(spacing: 16) {
            Button(Strings.Common.cancel) {
                onCancel()
            }
            .foregroundStyle(.secondary)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier("END_SLEEP_CANCEL_BUTTON")

            Button {
                HapticFeedback.success()
                onSave(wakeUpTime)
                // If walk callback is provided, show post-wake state instead of dismissing
                if onStartWalk != nil {
                    isWakeUpLogged = true
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                    Text(Strings.SleepSession.logWakeUp)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .cornerRadius(LayoutConstants.cornerRadiusM)
            }
            .accessibilityIdentifier("END_SLEEP_SAVE_BUTTON")
        }
    }

    // MARK: - Post-Wake Content (After logging wake-up)

    @ViewBuilder
    private var postWakeContent: some View {
        Spacer()

        // Success indicator
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text(Strings.SleepSession.wakeUpLogged)
                .font(.title2)
                .fontWeight(.semibold)

            Text(Strings.SleepSession.postWakeWalkPrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }

        Spacer()

        // Walk prompt
        VStack(spacing: 12) {
            Button {
                HapticFeedback.medium()
                onStartWalk?()
            } label: {
                HStack {
                    Image(systemName: "figure.walk")
                    Text(Strings.SleepSession.startWalk)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.otisSuccess)
                .cornerRadius(LayoutConstants.cornerRadiusM)
            }
            .accessibilityIdentifier("POST_WAKE_START_WALK_BUTTON")

            Button {
                onCancel()
            } label: {
                Text(Strings.SleepSession.maybeLater)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier("POST_WAKE_DISMISS_BUTTON")
        }
    }
}

// MARK: - Previews

#Preview("End Sleep Sheet") {
    EndSleepSheet(
        sleepStartTime: Date().addingTimeInterval(-45 * 60),
        onSave: { time in
            print("Wake up at: \(time)")
        },
        onCancel: {},
        onStartWalk: {
            print("Start walk")
        }
    )
}

#Preview("Long Sleep") {
    EndSleepSheet(
        sleepStartTime: Date().addingTimeInterval(-2 * 60 * 60),
        onSave: { time in
            print("Wake up at: \(time)")
        },
        onCancel: {},
        onStartWalk: {
            print("Start walk")
        }
    )
}

#Preview("Post-Wake State") {
    PostWakePreviewWrapper()
}

/// Helper for previewing the post-wake state
private struct PostWakePreviewWrapper: View {
    @State private var showPostWake = true

    var body: some View {
        EndSleepSheet(
            sleepStartTime: Date().addingTimeInterval(-45 * 60),
            onSave: { _ in },
            onCancel: {},
            onStartWalk: {
                print("Start walk")
            }
        )
        .onAppear {
            // Simulate the wake-up already logged state by using the view's internal state
        }
    }
}
