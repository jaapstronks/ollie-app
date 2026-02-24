//
//  MealScheduleEditor.swift
//  Ollie-app
//
//  Editor for configuring meal schedule with add/delete/reorder support

import SwiftUI
import OllieShared

/// Editor view for meal schedule configuration
struct MealScheduleEditor: View {
    @Binding var mealSchedule: MealSchedule
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
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
                        Label(Strings.Meals.addMeal, systemImage: "plus.circle")
                    }
                } header: {
                    Text(Strings.Meals.mealsSection)
                } footer: {
                    Text(Strings.Meals.footerHint)
                }
            }
            .navigationTitle(Strings.Meals.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        // Update mealsPerDay count to match portions
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

    var body: some View {
        NavigationStack {
            Form {
                Section(Strings.Meals.name) {
                    TextField(Strings.Meals.namePlaceholder, text: $label)
                }

                Section(Strings.Meals.amount) {
                    TextField(Strings.Meals.amountExample, text: $amount)
                }

                Section(Strings.Meals.time) {
                    DatePicker(
                        Strings.Meals.time,
                        selection: $targetTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            .navigationTitle(Strings.Meals.editMeal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
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

        if let timeString = portion.targetTime,
           let parsed = DateFormatters.timeOnly.date(from: timeString) {
            targetTime = parsed
        } else {
            // Default to noon if no time set
            targetTime = Date.fromTimeComponents(hour: 12, minute: 0)
        }
    }

    private func savePortion() {
        portion.label = label
        portion.amount = amount
        portion.targetTime = targetTime.timeString
    }
}

/// Sheet for adding a new meal
struct AddMealSheet: View {
    let onAdd: (MealSchedule.MealPortion) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var label: String = ""
    @State private var amount: String = ""
    @State private var targetTime: Date = Date.fromTimeComponents(hour: 12, minute: 0)

    var body: some View {
        NavigationStack {
            Form {
                Section(Strings.Meals.name) {
                    TextField(Strings.Meals.namePlaceholder, text: $label)
                }

                Section(Strings.Meals.amount) {
                    TextField(Strings.Meals.amountExample, text: $amount)
                }

                Section(Strings.Meals.time) {
                    DatePicker(
                        Strings.Meals.time,
                        selection: $targetTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            .navigationTitle(Strings.Meals.addMeal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.add) {
                        let newPortion = MealSchedule.MealPortion(
                            label: label,
                            amount: amount,
                            targetTime: targetTime.timeString
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
                .init(label: "Breakfast", amount: "80g", targetTime: "07:00"),
                .init(label: "Lunch", amount: "80g", targetTime: "13:00"),
                .init(label: "Dinner", amount: "80g", targetTime: "19:00")
            ]
        ),
        onSave: { _ in }
    )
}
