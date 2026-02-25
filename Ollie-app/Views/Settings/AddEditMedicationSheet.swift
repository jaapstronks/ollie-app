//
//  AddEditMedicationSheet.swift
//  Ollie-app
//
//  Form for creating/editing medications
//

import SwiftUI
import OllieShared

/// Sheet for adding or editing a medication
struct AddEditMedicationSheet: View {
    let profileStore: ProfileStore
    let medication: Medication?

    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name: String = ""
    @State private var instructions: String = ""
    @State private var icon: String = "pills.fill"
    @State private var recurrence: RecurrenceType = .daily
    @State private var selectedDays: Set<Int> = Set(0...6)
    @State private var times: [MedicationTime] = [MedicationTime(targetTime: "08:00")]
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date().addingTimeInterval(86400 * 30)
    @State private var isActive: Bool = true

    private var isEditing: Bool { medication != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !times.isEmpty
    }

    // Available icons for medications
    private let availableIcons = [
        "pills.fill",
        "pill.fill",
        "capsule.fill",
        "cross.vial.fill",
        "syringe.fill",
        "bandage.fill",
        "ant.fill",
        "drop.fill",
        "heart.fill",
        "leaf.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                scheduleSection
                timesSection
                durationSection
            }
            .navigationTitle(isEditing ? Strings.Medications.editMedication : Strings.Medications.addMedication)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadExisting()
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var basicSection: some View {
        Section {
            // Name
            TextField(Strings.Medications.name, text: $name)
                .textContentType(.name)

            // Instructions
            TextField(Strings.Medications.instructionsPlaceholder, text: $instructions, axis: .vertical)
                .lineLimit(2...4)

            // Icon picker
            iconPicker
        } header: {
            Text(Strings.Medications.name)
        }
    }

    @ViewBuilder
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Medications.icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableIcons, id: \.self) { iconName in
                        Button {
                            icon = iconName
                            HapticFeedback.selection()
                        } label: {
                            Image(systemName: iconName)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(icon == iconName ? Color.ollieAccent : Color.secondary.opacity(0.1))
                                )
                                .foregroundStyle(icon == iconName ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        Section {
            // Recurrence picker
            Picker(Strings.Medications.schedule, selection: $recurrence) {
                ForEach(RecurrenceType.allCases, id: \.self) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)

            // Day selector (only for weekly)
            if recurrence == .weekly {
                daySelector
            }

            // Active toggle
            Toggle(Strings.Medications.active, isOn: $isActive)
        } header: {
            Text(Strings.Medications.schedule)
        }
    }

    @ViewBuilder
    private var daySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Medications.daysOfWeek)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    Button {
                        if selectedDays.contains(dayIndex) {
                            selectedDays.remove(dayIndex)
                        } else {
                            selectedDays.insert(dayIndex)
                        }
                        HapticFeedback.selection()
                    } label: {
                        Text(Strings.Medications.dayShort(dayIndex))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(selectedDays.contains(dayIndex) ? Color.ollieAccent : Color.secondary.opacity(0.1))
                            )
                            .foregroundStyle(selectedDays.contains(dayIndex) ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var timesSection: some View {
        Section {
            ForEach(times.indices, id: \.self) { index in
                timeRow(at: index)
            }
            .onDelete(perform: deleteTime)

            Button {
                times.append(MedicationTime(targetTime: "12:00"))
                HapticFeedback.light()
            } label: {
                Label(Strings.Medications.addTime, systemImage: "plus")
            }
        } header: {
            Text(Strings.Medications.times)
        }
    }

    @ViewBuilder
    private func timeRow(at index: Int) -> some View {
        HStack {
            DatePicker(
                "",
                selection: Binding(
                    get: { timeFromString(times[index].targetTime) },
                    set: { times[index].targetTime = timeToString($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()

            Spacer()

            // Optional meal linking
            if let mealSchedule = profileStore.profile?.mealSchedule {
                Menu {
                    Button(Strings.Medications.linkToMeal) {
                        // Clear link
                        times[index].linkedMealId = nil
                    }
                    ForEach(mealSchedule.portions) { portion in
                        Button {
                            times[index].linkedMealId = portion.id
                            if let targetTime = portion.targetTime {
                                times[index].targetTime = targetTime
                            }
                        } label: {
                            Text(portion.label)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let linkedId = times[index].linkedMealId,
                           let meal = mealSchedule.portions.first(where: { $0.id == linkedId }) {
                            Image(systemName: "link")
                                .font(.caption)
                            Text(meal.label)
                                .font(.caption)
                        } else {
                            Image(systemName: "link")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var durationSection: some View {
        Section {
            DatePicker(Strings.Medications.startDate, selection: $startDate, displayedComponents: .date)

            Picker(Strings.Medications.duration, selection: $hasEndDate) {
                Text(Strings.Medications.indefinitely).tag(false)
                Text(Strings.Medications.untilDate).tag(true)
            }

            if hasEndDate {
                DatePicker(Strings.Medications.endDate, selection: $endDate, in: startDate..., displayedComponents: .date)
            }
        } header: {
            Text(Strings.Medications.duration)
        }
    }

    // MARK: - Actions

    private func loadExisting() {
        guard let med = medication else { return }

        name = med.name
        instructions = med.instructions ?? ""
        icon = med.icon
        recurrence = med.recurrence
        selectedDays = Set(med.daysOfWeek ?? Array(0...6))
        times = med.times.isEmpty ? [MedicationTime(targetTime: "08:00")] : med.times
        startDate = med.startDate
        hasEndDate = med.endDate != nil
        endDate = med.endDate ?? Date().addingTimeInterval(86400 * 30)
        isActive = med.isActive
    }

    private func save() {
        let newMedication = Medication(
            id: medication?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            instructions: instructions.isEmpty ? nil : instructions,
            icon: icon,
            recurrence: recurrence,
            daysOfWeek: recurrence == .weekly ? Array(selectedDays) : nil,
            times: times,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            isActive: isActive
        )

        if isEditing {
            profileStore.updateMedication(newMedication)
        } else {
            profileStore.addMedication(newMedication)
        }

        HapticFeedback.success()
        dismiss()
    }

    private func deleteTime(at offsets: IndexSet) {
        // Keep at least one time
        guard times.count > 1 else { return }
        times.remove(atOffsets: offsets)
    }

    // MARK: - Helpers

    private func timeFromString(_ string: String) -> Date {
        guard let (hour, minute) = string.parseTimeComponents() else {
            return Date()
        }
        return Date.fromTimeComponents(hour: hour, minute: minute)
    }

    private func timeToString(_ date: Date) -> String {
        date.timeString
    }
}

// MARK: - Preview

#Preview("AddEditMedicationSheet") {
    AddEditMedicationSheet(
        profileStore: ProfileStore(),
        medication: nil
    )
}
