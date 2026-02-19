//
//  LogEventSheet.swift
//  Ollie-app
//

import SwiftUI

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
                    HStack {
                        Text(eventType.emoji)
                            .font(.largeTitle)
                        Text(eventType.label)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }

                Section("Notitie") {
                    TextField("Optionele notitie...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                if eventType == .sociaal {
                    Section("Wie?") {
                        TextField("Naam van persoon of dier", text: $who)
                    }
                }

                if eventType == .training {
                    Section("Training") {
                        TextField("Oefening", text: $exercise)
                        TextField("Resultaat", text: $result)
                    }
                }

                Section("Duur") {
                    TextField("Minuten", text: $durationMin)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") {
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
