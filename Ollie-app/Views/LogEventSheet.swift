//
//  LogEventSheet.swift
//  Ollie-app
//

import SwiftUI
import OllieShared

/// Sheet for adding details to an event (note, who, exercise, etc.)
struct LogEventSheet: View {
    let eventType: EventType
    let onSave: (String?, String?, String?, String?, Int?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var note: String = ""
    @State private var who: String = ""
    @State private var exercise: String = ""
    @State private var result: String = ""
    @State private var durationMin: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        EventIconLarge(type: eventType, size: 40)
                        Text(eventType.label)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }

                Section(Strings.LogEvent.note) {
                    TextField(Strings.LogEvent.notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel(Strings.LogEvent.note)
                        .accessibilityHint(Strings.LogEvent.noteAccessibilityHint)
                }

                if eventType == .sociaal {
                    Section(Strings.LogEvent.who) {
                        TextField(Strings.LogEvent.whoPlaceholder, text: $who)
                            .accessibilityLabel(Strings.LogEvent.whoAccessibility)
                            .accessibilityHint(Strings.LogEvent.whoAccessibilityHint)
                    }
                }

                if eventType == .training {
                    Section(Strings.LogEvent.training) {
                        TextField(Strings.LogEvent.exercise, text: $exercise)
                            .accessibilityLabel(Strings.LogEvent.exercise)
                            .accessibilityHint(Strings.LogEvent.exerciseAccessibilityHint)
                        TextField(Strings.LogEvent.result, text: $result)
                            .accessibilityLabel(Strings.LogEvent.result)
                            .accessibilityHint(Strings.LogEvent.resultAccessibilityHint)
                    }
                }

                Section(Strings.LogEvent.duration) {
                    TextField(Strings.Common.minutesFull, text: $durationMin)
                        .keyboardType(.numberPad)
                        .accessibilityLabel(Strings.LogEvent.durationAccessibility)
                        .accessibilityHint(Strings.LogEvent.durationAccessibilityHint)
                }
            }
            .navigationTitle(Strings.LogEvent.details)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        HapticFeedback.success()
                        let duration = Int(durationMin)
                        onSave(
                            note.isEmpty ? nil : note,
                            who.isEmpty ? nil : who,
                            exercise.isEmpty ? nil : exercise,
                            result.isEmpty ? nil : result,
                            duration
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    LogEventSheet(eventType: .training) { note, who, exercise, result, duration in
        print("Saved: \(note ?? ""), \(who ?? ""), \(exercise ?? ""), \(result ?? ""), \(duration ?? 0)")
    }
}
