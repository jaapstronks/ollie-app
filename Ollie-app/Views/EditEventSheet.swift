//
//  EditEventSheet.swift
//  Ollie-app
//

import SwiftUI

/// Sheet for editing an existing event
struct EditEventSheet: View {
    let event: PuppyEvent
    let onSave: (PuppyEvent) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var time: Date
    @State private var location: EventLocation?
    @State private var note: String
    @State private var who: String
    @State private var exercise: String
    @State private var result: String
    @State private var durationMin: String
    @State private var weightKg: String

    init(event: PuppyEvent, onSave: @escaping (PuppyEvent) -> Void) {
        self.event = event
        self.onSave = onSave

        // Initialize state with existing values
        _time = State(initialValue: event.time)
        _location = State(initialValue: event.location)
        _note = State(initialValue: event.note ?? "")
        _who = State(initialValue: event.who ?? "")
        _exercise = State(initialValue: event.exercise ?? "")
        _result = State(initialValue: event.result ?? "")
        _durationMin = State(initialValue: event.durationMin.map { String($0) } ?? "")
        _weightKg = State(initialValue: event.weightKg.map { String($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                // Event type header (not editable)
                Section {
                    HStack(spacing: 12) {
                        EventIconLarge(type: event.type, size: 40)
                        Text(event.type.label)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }

                // Time picker
                Section(Strings.QuickLogSheet.time) {
                    DatePicker(
                        Strings.QuickLogSheet.time,
                        selection: $time,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }

                // Location picker (for potty events)
                if event.type.requiresLocation {
                    Section(Strings.LocationPicker.title) {
                        Picker(Strings.LocationPicker.title, selection: $location) {
                            Text(Strings.EventLocation.outside).tag(EventLocation?.some(.buiten))
                            Text(Strings.EventLocation.inside).tag(EventLocation?.some(.binnen))
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Note
                Section(Strings.LogEvent.note) {
                    TextField(Strings.LogEvent.notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Social event: who
                if event.type == .sociaal {
                    Section(Strings.LogEvent.who) {
                        TextField(Strings.LogEvent.whoPlaceholder, text: $who)
                    }
                }

                // Training event: exercise and result
                if event.type == .training {
                    Section(Strings.LogEvent.training) {
                        TextField(Strings.LogEvent.exercise, text: $exercise)
                        TextField(Strings.LogEvent.result, text: $result)
                    }
                }

                // Weight event
                if event.type == .gewicht {
                    Section(Strings.Health.weight) {
                        TextField(Strings.Health.weightPlaceholder, text: $weightKg)
                            .keyboardType(.decimalPad)
                    }
                }

                // Duration (optional for all events)
                Section(Strings.LogEvent.duration) {
                    TextField(Strings.Common.minutesFull, text: $durationMin)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(Strings.Common.edit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveEvent()
                    }
                }
            }
        }
    }

    private func saveEvent() {
        var updatedEvent = event
        updatedEvent.time = time
        updatedEvent.location = location
        updatedEvent.note = note.isEmpty ? nil : note
        updatedEvent.who = who.isEmpty ? nil : who
        updatedEvent.exercise = exercise.isEmpty ? nil : exercise
        updatedEvent.result = result.isEmpty ? nil : result
        updatedEvent.durationMin = Int(durationMin)
        updatedEvent.weightKg = Double(weightKg)

        HapticFeedback.success()
        onSave(updatedEvent)
    }
}

#Preview {
    EditEventSheet(
        event: PuppyEvent(
            time: Date(),
            type: .plassen,
            location: .buiten,
            note: "Good boy!"
        )
    ) { event in
        print("Saved: \(event)")
    }
}
