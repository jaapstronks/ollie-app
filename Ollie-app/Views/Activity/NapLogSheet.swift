//
//  NapLogSheet.swift
//  Ollie-app
//
//  Sheet for logging a completed nap with start time, end time, and duration

import SwiftUI
import OllieShared

/// Sheet for logging a completed nap with linked start/end/duration
/// Supports logging naps from previous days and naps spanning midnight
struct NapLogSheet: View {
    let onSave: (Date, Date, String?) -> Void
    let onCancel: () -> Void

    /// Default duration in minutes (average nap time, or 30 if unknown)
    var defaultDurationMinutes: Int = 30

    /// Full start date+time (allows multi-day naps)
    @State private var startDateTime: Date
    /// Full end date+time
    @State private var endDateTime: Date
    @State private var note = ""

    /// Track which picker is expanded
    @State private var showStartPicker = false
    @State private var showEndPicker = false

    private let now = Date()

    init(
        onSave: @escaping (Date, Date, String?) -> Void,
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
        NavigationView {
            Form {
                // Start date+time section
                Section {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
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
                                    .foregroundStyle(showStartPicker ? Color.ollieSleep : .primary)
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
                        withAnimation(.easeInOut(duration: 0.2)) {
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
                                    .foregroundStyle(showEndPicker ? Color.ollieSleep : .primary)
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
                            .foregroundStyle(Color.ollieSleep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ollieSleep.opacity(0.1))
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
                            note.isEmpty ? nil : note
                        )
                    } label: {
                        Text(Strings.NapLog.logNap)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isValid ? Color.ollieSleep : Color.gray)
                            .clipShape(Capsule())
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NapLogSheet(
        onSave: { start, end, note in
            let duration = Int(end.timeIntervalSince(start) / 60)
            print("Nap: \(start) - \(end), \(duration)min, note: \(note ?? "")")
        },
        onCancel: { },
        defaultDurationMinutes: 25
    )
}
