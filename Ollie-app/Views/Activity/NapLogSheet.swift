//
//  NapLogSheet.swift
//  Otis-app
//
//  Sheet for logging a completed nap with start time, end time, and duration

import SwiftUI
import OtisShared

/// Sheet for logging a completed nap with linked start/end/duration
/// Supports logging naps from previous days and naps spanning midnight
struct NapLogSheet: View {
    let onSave: (Date, Date, String?, NapLocation?) -> Void
    let onCancel: () -> Void

    /// Default duration in minutes (average nap time, or 30 if unknown)
    var defaultDurationMinutes: Int = 30

    /// Full start date+time (allows multi-day naps)
    @State private var startDateTime: Date
    /// Full end date+time
    @State private var endDateTime: Date
    @State private var note = ""
    @State private var selectedNapLocation: NapLocation?

    /// Track which picker is expanded
    @State private var showStartPicker = false
    @State private var showEndPicker = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let now = Date()

    init(
        onSave: @escaping (Date, Date, String?, NapLocation?) -> Void,
        onCancel: @escaping () -> Void,
        defaultDurationMinutes: Int = 30
    ) {
        self.onSave = onSave
        self.onCancel = onCancel
        self.defaultDurationMinutes = defaultDurationMinutes

        // Calculate defaults: end time = now, start = end - duration
        let defaultEndTime = Date()
        let defaultStartTime = defaultEndTime.addingTimeInterval(-Double(defaultDurationMinutes) * 60)

        _startDateTime = State(initialValue: defaultStartTime)
        _endDateTime = State(initialValue: defaultEndTime)
    }

    /// Computed duration in minutes
    private var durationMinutes: Int {
        max(1, Int(endDateTime.timeIntervalSince(startDateTime) / 60))
    }

    /// Formatted duration string
    private var durationString: String {
        durationMinutes.formatAsDuration()
    }

    /// Whether the nap spans multiple days
    private var spansMultipleDays: Bool {
        !Calendar.current.isDate(startDateTime, inSameDayAs: endDateTime)
    }

    /// Whether the times are valid (start before end)
    private var isValid: Bool {
        startDateTime < endDateTime
    }

    var body: some View {
        NavigationStack {
            Form {
                // Start date+time section
                Section {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            showStartPicker.toggle()
                            if showStartPicker { showEndPicker = false }
                        }
                        HapticFeedback.selection()
                    } label: {
                        HStack {
                            Label(Strings.NapLog.startTime, systemImage: "moon.zzz.fill")
                                .foregroundStyle(.primary)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(startDateTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.body)
                                    .foregroundStyle(showStartPicker ? Color.otisSleep : .primary)
                            }

                            Image(systemName: showStartPicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if showStartPicker {
                        DatePicker(
                            "",
                            selection: $startDateTime,
                            in: ...now,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .onChange(of: startDateTime) { oldValue, newValue in
                            // Maintain minimum duration of 1 minute
                            if newValue >= endDateTime {
                                endDateTime = newValue.addingTimeInterval(60)
                            }
                        }
                    }
                }

                // End date+time section
                Section {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            showEndPicker.toggle()
                            if showEndPicker { showStartPicker = false }
                        }
                        HapticFeedback.selection()
                    } label: {
                        HStack {
                            Label(Strings.NapLog.endTime, systemImage: "sun.max.fill")
                                .foregroundStyle(.primary)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(endDateTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.body)
                                    .foregroundStyle(showEndPicker ? Color.otisSleep : .primary)
                            }

                            Image(systemName: showEndPicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if showEndPicker {
                        DatePicker(
                            "",
                            selection: $endDateTime,
                            in: startDateTime.addingTimeInterval(60)...now,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                    }
                }

                // Duration display
                Section {
                    HStack {
                        Label(Strings.NapLog.duration, systemImage: "clock")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(durationString)
                            .font(.body.monospacedDigit().weight(.medium))
                            .foregroundStyle(Color.otisSleep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.otisSleep.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Show hint when spanning multiple days
                    if spansMultipleDays {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.stars")
                                .foregroundStyle(.secondary)
                            Text(Strings.NapLog.overnightHint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Location section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Strings.NapLocation.wherePrompt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            ForEach(NapLocation.allCases, id: \.self) { location in
                                NapLogLocationButton(
                                    location: location,
                                    isSelected: selectedNapLocation == location,
                                    colorScheme: colorScheme
                                ) {
                                    HapticFeedback.selection()
                                    if selectedNapLocation == location {
                                        selectedNapLocation = nil
                                    } else {
                                        selectedNapLocation = location
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Note section
                Section {
                    TextField(Strings.NapLog.notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(Strings.NapLog.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        HapticFeedback.success()
                        onSave(
                            startDateTime,
                            endDateTime,
                            note.nilIfBlank,
                            selectedNapLocation
                        )
                    } label: {
                        Text(Strings.NapLog.logNap)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isValid ? Color.otisSleep : Color.gray)
                            .clipShape(Capsule())
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Nap Location Button

/// Button for selecting nap location in the log sheet
private struct NapLogLocationButton: View {
    let location: NapLocation
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: location.icon)
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.otisSleep : Color.otisSleep.opacity(0.1))
                    )
                    .foregroundStyle(isSelected ? .white : Color.otisSleep)

                Text(location.label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.otisSleep : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.otisSleep.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.otisSleep : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NapLogSheet(
        onSave: { start, end, note, location in
            let duration = Int(end.timeIntervalSince(start) / 60)
            print("Nap: \(start) - \(end), \(duration)min, note: \(note ?? ""), location: \(String(describing: location))")
        },
        onCancel: { },
        defaultDurationMinutes: 25
    )
}
