//
//  MealScheduleEditor.swift
//  Ollie-app
//
//  Editor for configuring meal schedule

import SwiftUI

/// Editor view for meal schedule configuration
struct MealScheduleEditor: View {
    @Binding var mealSchedule: MealSchedule
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editingPortion: MealSchedule.MealPortion?
    @State private var showingAddMeal = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($mealSchedule.portions) { $portion in
                        MealPortionDisplayRow(portion: $portion)
                    }
                    .onDelete(perform: deleteMeal)
                    .onMove(perform: moveMeal)

                    Button {
                        showingAddMeal = true
                    } label: {
                        Label("Maaltijd toevoegen", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Maaltijden")
                } footer: {
                    Text("Tik op een maaltijd om te bewerken. Veeg om te verwijderen.")
                }
            }
            .navigationTitle("Maaltijden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        // Update mealsPerDay count
                        mealSchedule.mealsPerDay = mealSchedule.portions.count
                        onSave()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealSheet { newPortion in
                    mealSchedule.portions.append(newPortion)
                }
            }
        }
    }

    private func deleteMeal(at offsets: IndexSet) {
        mealSchedule.portions.remove(atOffsets: offsets)
    }

    private func moveMeal(from source: IndexSet, to destination: Int) {
        mealSchedule.portions.move(fromOffsets: source, toOffset: destination)
    }
}

/// Row for displaying and editing a single meal portion
struct MealPortionDisplayRow: View {
    @Binding var portion: MealSchedule.MealPortion
    @State private var showingEditor = false

    var body: some View {
        Button {
            showingEditor = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(portion.label)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label(portion.amount, systemImage: "scalemass")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let time = portion.targetTime {
                            Label(time, systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingEditor) {
            EditMealSheet(portion: $portion)
        }
    }
}

/// Sheet for editing an existing meal
struct EditMealSheet: View {
    @Binding var portion: MealSchedule.MealPortion
    @Environment(\.dismiss) private var dismiss

    @State private var label: String = ""
    @State private var amount: String = ""
    @State private var targetTime: Date = Date()
    @State private var hasTargetTime: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Naam") {
                    TextField("Bijv. Ontbijt", text: $label)
                }

                Section("Hoeveelheid") {
                    TextField("Bijv. 80g", text: $amount)
                }

                Section("Tijd") {
                    Toggle("Streeftijd instellen", isOn: $hasTargetTime)

                    if hasTargetTime {
                        DatePicker(
                            "Tijd",
                            selection: $targetTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
            }
            .navigationTitle("Maaltijd bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        savePortion()
                        dismiss()
                    }
                    .disabled(label.isEmpty || amount.isEmpty)
                }
            }
            .onAppear {
                loadPortion()
            }
        }
    }

    private func loadPortion() {
        label = portion.label
        amount = portion.amount

        if let timeString = portion.targetTime {
            hasTargetTime = true
            targetTime = parseTime(timeString) ?? Date()
        } else {
            hasTargetTime = false
        }
    }

    private func savePortion() {
        portion.label = label
        portion.amount = amount
        portion.targetTime = hasTargetTime ? formatTime(targetTime) : nil
    }

    private func parseTime(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: string)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/// Sheet for adding a new meal
struct AddMealSheet: View {
    let onAdd: (MealSchedule.MealPortion) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var label: String = ""
    @State private var amount: String = ""
    @State private var targetTime: Date = Date()
    @State private var hasTargetTime: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Naam") {
                    TextField("Bijv. Ontbijt", text: $label)
                }

                Section("Hoeveelheid") {
                    TextField("Bijv. 80g", text: $amount)
                }

                Section("Tijd") {
                    Toggle("Streeftijd instellen", isOn: $hasTargetTime)

                    if hasTargetTime {
                        DatePicker(
                            "Tijd",
                            selection: $targetTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
            }
            .navigationTitle("Maaltijd toevoegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Voeg toe") {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"

                        let newPortion = MealSchedule.MealPortion(
                            label: label,
                            amount: amount,
                            targetTime: hasTargetTime ? formatter.string(from: targetTime) : nil
                        )
                        onAdd(newPortion)
                        dismiss()
                    }
                    .disabled(label.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

/// Wrapper that owns the state for editing
struct MealScheduleEditorWrapper: View {
    let initialSchedule: MealSchedule
    let onSave: (MealSchedule) -> Void

    @State private var schedule: MealSchedule

    init(initialSchedule: MealSchedule, onSave: @escaping (MealSchedule) -> Void) {
        self.initialSchedule = initialSchedule
        self.onSave = onSave
        self._schedule = State(initialValue: initialSchedule)
    }

    var body: some View {
        MealScheduleEditor(mealSchedule: $schedule) {
            onSave(schedule)
        }
    }
}

#Preview {
    MealScheduleEditorWrapper(
        initialSchedule: MealSchedule(
            mealsPerDay: 3,
            portions: [
                .init(label: "Ontbijt", amount: "80g", targetTime: "07:00"),
                .init(label: "Middag", amount: "80g", targetTime: "13:00"),
                .init(label: "Avond", amount: "80g", targetTime: "19:00")
            ]
        ),
        onSave: { _ in }
    )
}
