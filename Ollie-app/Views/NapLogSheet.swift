//
//  NapLogSheet.swift
//  Ollie-app
//
//  Sheet for logging a completed nap with start time, end time, and duration

import SwiftUI
import OllieShared

/// Sheet for logging a completed nap with linked start/end/duration
struct NapLogSheet: View {
    let onSave: (Date, Date, String?) -> Void
    let onCancel: () -> Void

    /// Default duration in minutes (average nap time, or 30 if unknown)
    var defaultDurationMinutes: Int = 30

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var note = ""

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

        _startTime = State(initialValue: defaultStartTime)
        _endTime = State(initialValue: defaultEndTime)
    }

    /// Computed duration in minutes
    private var durationMinutes: Int {
        max(1, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    var body: some View {
        NavigationView {
            Form {
                // Time section with linked start/end/duration
                Section {
                    DurationTimePicker(
                        startTime: $startTime,
                        endTime: $endTime,
                        accentColor: .purple,
                        maxEndTime: now
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
                            startTime,
                            endTime,
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
