//
//  DurationTimePicker.swift
//  Ollie-app
//
//  Reusable component for selecting start time, end time, and duration
//  with linked updates (changing one updates the others)

import SwiftUI
import UIKit

/// A picker component that allows selecting start time, end time, or duration
/// with all values linked (changing one updates the others)
struct DurationTimePicker: View {
    @Binding var startTime: Date
    @Binding var endTime: Date

    /// The primary mode determines which field is "leading" for calculations
    enum Mode {
        case startAndEnd      // User sets start & end, duration is computed
        case startAndDuration // User sets start & duration, end is computed
    }

    var mode: Mode = .startAndEnd

    /// Color accent for the picker
    var accentColor: Color = .accentColor

    /// Maximum allowed end time (typically current time)
    var maxEndTime: Date = Date()

    /// Duration options in minutes for the stepper
    private let durationSteps = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]

    @State private var showStartPicker = false
    @State private var showEndPicker = false

    /// Computed duration in minutes
    private var durationMinutes: Int {
        max(1, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    /// Formatted duration string
    private var durationString: String {
        let mins = durationMinutes
        if mins < 60 {
            return "\(mins) min"
        } else {
            let hours = mins / 60
            let remainingMins = mins % 60
            if remainingMins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMins)m"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Start time row
            HStack {
                Label(Strings.DurationPicker.startTime, systemImage: "play.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showStartPicker.toggle()
                        showEndPicker = false
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack(spacing: 4) {
                        Text(startTime.formatted(date: .omitted, time: .shortened))
                            .font(.body.monospacedDigit())
                        Image(systemName: showStartPicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(showStartPicker ? accentColor.opacity(0.15) : Color(UIColor.tertiarySystemBackground))
                    .foregroundStyle(showStartPicker ? accentColor : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            if showStartPicker {
                DatePicker(
                    "",
                    selection: $startTime,
                    in: ...maxEndTime,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
                .onChange(of: startTime) { _, newStart in
                    // Ensure end time is after start time
                    if newStart >= endTime {
                        endTime = newStart.addingTimeInterval(5 * 60) // Add 5 min minimum
                    }
                    // Clamp end time to max
                    if endTime > maxEndTime {
                        endTime = maxEndTime
                    }
                }
            }

            Divider()

            // End time row
            HStack {
                Label(Strings.DurationPicker.endTime, systemImage: "stop.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showEndPicker.toggle()
                        showStartPicker = false
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack(spacing: 4) {
                        Text(endTime.formatted(date: .omitted, time: .shortened))
                            .font(.body.monospacedDigit())
                        Image(systemName: showEndPicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(showEndPicker ? accentColor.opacity(0.15) : Color(UIColor.tertiarySystemBackground))
                    .foregroundStyle(showEndPicker ? accentColor : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            if showEndPicker {
                DatePicker(
                    "",
                    selection: $endTime,
                    in: startTime.addingTimeInterval(60)...maxEndTime, // At least 1 min after start
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
            }

            Divider()

            // Duration row with quick adjust
            HStack {
                Label(Strings.DurationPicker.duration, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                // Duration display
                Text(durationString)
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Quick duration buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(durationSteps, id: \.self) { mins in
                        Button {
                            setDuration(mins)
                            HapticFeedback.selection()
                        } label: {
                            Text(mins < 60 ? "\(mins)m" : "\(mins/60)h")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(durationMinutes == mins ? accentColor : Color(UIColor.tertiarySystemBackground))
                                .foregroundStyle(durationMinutes == mins ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func setDuration(_ minutes: Int) {
        // Calculate new end time from start time + duration
        let newEnd = startTime.addingTimeInterval(Double(minutes) * 60)

        // If end would be in the future, adjust start time instead
        if newEnd > maxEndTime {
            endTime = maxEndTime
            startTime = maxEndTime.addingTimeInterval(-Double(minutes) * 60)
        } else {
            endTime = newEnd
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var start = Date().addingTimeInterval(-30 * 60)
        @State private var end = Date()

        var body: some View {
            VStack {
                DurationTimePicker(
                    startTime: $start,
                    endTime: $end,
                    accentColor: .purple
                )
                .padding()

                Text("Duration: \(Int(end.timeIntervalSince(start) / 60)) min")
                    .padding()
            }
        }
    }

    return PreviewWrapper()
}
