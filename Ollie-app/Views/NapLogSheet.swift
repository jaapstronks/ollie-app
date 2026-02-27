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

    @State private var selectedDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var note = ""
    @State private var spansNight: Bool = false

    private let now = Date()

    init(
        onSave: @escaping (Date, Date, String?) -> Void,
        onCancel: @escaping () -> Void,
        defaultDurationMinutes: Int = 30
    ) {
        self.onSave = onSave
        self.onCancel = onCancel
        self.defaultDurationMinutes = defaultDurationMinutes

        // Calculate defaults: end time = now (or rounded), start = end - duration
        let defaultEndTime = Date()
        let defaultStartTime = defaultEndTime.addingTimeInterval(-Double(defaultDurationMinutes) * 60)

        _selectedDate = State(initialValue: defaultEndTime)
        _startTime = State(initialValue: defaultStartTime)
        _endTime = State(initialValue: defaultEndTime)
    }

    /// Computed duration in minutes
    private var durationMinutes: Int {
        max(1, Int(actualEndTime.timeIntervalSince(actualStartTime) / 60))
    }

    /// The actual start time considering the selected date
    private var actualStartTime: Date {
        // If spans night, start is on the day BEFORE selectedDate
        let calendar = Calendar.current
        let startDate = spansNight ? calendar.date(byAdding: .day, value: -1, to: selectedDate)! : selectedDate

        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        return calendar.date(bySettingHour: startComponents.hour ?? 0,
                            minute: startComponents.minute ?? 0,
                            second: 0,
                            of: startDate) ?? startTime
    }

    /// The actual end time considering the selected date
    private var actualEndTime: Date {
        let calendar = Calendar.current
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        return calendar.date(bySettingHour: endComponents.hour ?? 0,
                            minute: endComponents.minute ?? 0,
                            second: 0,
                            of: selectedDate) ?? endTime
    }

    var body: some View {
        NavigationView {
            Form {
                // Date picker (for logging naps on previous days)
                Section {
                    DatePicker(
                        Strings.NapLog.napDate,
                        selection: $selectedDate,
                        in: ...now,
                        displayedComponents: .date
                    )
                    .onChange(of: selectedDate) { _, newDate in
                        // Update times to match new date while keeping time components
                        let calendar = Calendar.current
                        if let newStart = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                                        minute: calendar.component(.minute, from: startTime),
                                                        second: 0, of: newDate) {
                            startTime = newStart
                        }
                        if let newEnd = calendar.date(bySettingHour: calendar.component(.hour, from: endTime),
                                                      minute: calendar.component(.minute, from: endTime),
                                                      second: 0, of: newDate) {
                            endTime = newEnd
                        }
                    }
                }

                // Toggle for overnight naps (spanning midnight)
                Section {
                    Toggle(Strings.NapLog.startedPreviousNight, isOn: $spansNight)
                } footer: {
                    if spansNight {
                        Text(Strings.NapLog.overnightHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Time section with linked start/end/duration
                Section {
                    DurationTimePicker(
                        startTime: $startTime,
                        endTime: $endTime,
                        accentColor: .purple,
                        maxEndTime: .distantFuture  // Allow any time for historical logging
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
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
                            actualStartTime,
                            actualEndTime,
                            note.isEmpty ? nil : note
                        )
                    } label: {
                        Text(Strings.NapLog.logNap)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .clipShape(Capsule())
                    }
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
