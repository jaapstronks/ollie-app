//
//  LogEventSheet.swift
//  Otis-app
//

import SwiftUI
import OtisShared

/// Sheet for adding details to an event (note, who, exercise, etc.)
struct LogEventSheet: View {
    let eventType: EventType
    let onSave: (String?, String?, String?, String?, Int?, UUID?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(ContactStore.self) var contactStore

    @State private var note: String = ""
    @State private var who: String = ""
    @State private var exercise: String = ""
    @State private var result: String = ""
    @State private var durationMin: String = ""
    @State private var linkedContactID: UUID? = nil

    // Available trainer contacts for picker
    private var trainerContacts: [DogContact] {
        contactStore.contacts.filter { $0.contactType == .trainer }
    }

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

                    // Trainer contact picker (optional)
                    if !trainerContacts.isEmpty {
                        Section(Strings.LogEvent.trainer) {
                            Picker(Strings.LogEvent.selectTrainer, selection: $linkedContactID) {
                                Text(Strings.Common.none).tag(nil as UUID?)
                                ForEach(trainerContacts) { contact in
                                    Text(contact.name).tag(contact.id as UUID?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
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
                            note.nilIfBlank,
                            who.nilIfBlank,
                            exercise.nilIfBlank,
                            result.nilIfBlank,
                            duration,
                            linkedContactID
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    LogEventSheet(eventType: .training) { note, who, exercise, result, duration, linkedContactID in
        print("Saved: \(note ?? ""), \(who ?? ""), \(exercise ?? ""), \(result ?? ""), \(duration ?? 0), contact: \(linkedContactID?.uuidString ?? "none")")
    }
    .environment(ContactStore())
}
