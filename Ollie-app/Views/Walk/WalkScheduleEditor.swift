//
//  WalkScheduleEditor.swift
//  Ollie-app
//
//  Full CRUD editor for walk schedule

import SwiftUI
import OllieShared

/// Editor for walk schedule with mode selection, walk list, and timing settings
struct WalkScheduleEditor: View {
    @Environment(\.dismiss) private var dismiss

    let initialSchedule: WalkSchedule
    let ageInMonths: Int
    let onSave: (WalkSchedule) -> Void

    @State private var schedule: WalkSchedule
    @State private var showingAddWalk = false
    @State private var editingWalk: WalkSchedule.ScheduledWalk?

    init(initialSchedule: WalkSchedule, ageInMonths: Int, onSave: @escaping (WalkSchedule) -> Void) {
        self.initialSchedule = initialSchedule
        self.ageInMonths = ageInMonths
        self.onSave = onSave
        _schedule = State(initialValue: initialSchedule)
    }

    var body: some View {
        NavigationStack {
            Form {
                schedulingModeSection
                walksSection
                if schedule.mode == .flexible {
                    timingSection
                }
                dayBoundariesSection
                exerciseLimitsSection
            }
            .navigationTitle(Strings.WalkScheduleEditor.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        onSave(schedule)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddWalk) {
                AddWalkSheet(schedule: $schedule)
            }
            .sheet(item: $editingWalk) { walk in
                EditScheduledWalkSheet(walk: walk, schedule: $schedule)
            }
        }
    }

    // MARK: - Scheduling Mode Section

    private var schedulingModeSection: some View {
        Section {
            Picker(Strings.WalkScheduleEditor.schedulingMode, selection: $schedule.mode) {
                Text(Strings.WalkScheduleEditor.modeFlexibleRecommended).tag(WalkScheduleMode.flexible)
                Text(Strings.WalkScheduleEditor.modeStrict).tag(WalkScheduleMode.strict)
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text(Strings.WalkScheduleEditor.schedulingMode)
        } footer: {
            Text(schedule.mode == .flexible
                 ? Strings.WalkScheduleEditor.modeFlexibleDescription
                 : Strings.WalkScheduleEditor.modeStrictDescription)
        }
    }

    // MARK: - Walks Section

    private var walksSection: some View {
        Section {
            ForEach(schedule.walks) { walk in
                Button {
                    editingWalk = walk
                } label: {
                    HStack {
                        Text(walk.label)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(walk.targetTime)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteWalks)
            .onMove(perform: moveWalks)

            Button {
                showingAddWalk = true
            } label: {
                Label(Strings.WalkScheduleEditor.addWalk, systemImage: "plus")
            }
        } header: {
            HStack {
                Text(Strings.WalkScheduleEditor.walksSection)
                Spacer()
                Text(Strings.WalkScheduleEditor.walksCount(schedule.walks.count))
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        } footer: {
            Text("Tap a walk to edit. Swipe to delete.")
        }
    }

    // MARK: - Timing Section (Flexible Mode Only)

    private var timingSection: some View {
        Section {
            Stepper(
                value: $schedule.intervalMinutes,
                in: 30...360,
                step: 15
            ) {
                HStack {
                    Text(Strings.WalkScheduleEditor.intervalBetweenWalks)
                    Spacer()
                    Text(Strings.WalkScheduleEditor.intervalMinutes(schedule.intervalMinutes))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text(Strings.WalkScheduleEditor.timingSection)
        } footer: {
            Text(Strings.WalkScheduleEditor.intervalFooter)
        }
    }

    // MARK: - Day Boundaries Section

    private var dayBoundariesSection: some View {
        Section {
            Stepper(
                value: $schedule.dayStartHour,
                in: 4...12
            ) {
                HStack {
                    Text(Strings.WalkScheduleEditor.firstWalkAfter)
                    Spacer()
                    Text(String(format: "%02d:00", schedule.dayStartHour))
                        .foregroundColor(.secondary)
                }
            }

            Stepper(
                value: $schedule.dayEndHour,
                in: 20...24
            ) {
                HStack {
                    Text(Strings.WalkScheduleEditor.lastWalkBefore)
                    Spacer()
                    Text(schedule.dayEndHour == 24 ? "00:00" : String(format: "%02d:00", schedule.dayEndHour))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text(Strings.WalkScheduleEditor.dayBoundaries)
        }
    }

    // MARK: - Exercise Limits Section

    private var exerciseLimitsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.WalkScheduleEditor.maxDurationPerWalk)
                    .font(.headline)

                Text(Strings.WalkScheduleEditor.fiveMinuteRule)
                    .font(.caption)
                    .foregroundColor(.secondary)

                switch schedule.maxDurationRule {
                case .minutesPerMonth(let minutes):
                    Stepper(value: Binding(
                        get: { minutes },
                        set: { schedule.maxDurationRule = .minutesPerMonth($0) }
                    ), in: 1...10) {
                        HStack {
                            Text("\(minutes)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(Strings.WalkScheduleEditor.minutesPerMonthValue(minutes))
                                .foregroundColor(.secondary)
                        }
                    }
                case .fixedMinutes(let minutes):
                    Stepper(value: Binding(
                        get: { minutes },
                        set: { schedule.maxDurationRule = .fixedMinutes($0) }
                    ), in: 5...120, step: 5) {
                        HStack {
                            Text("\(minutes)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(Strings.Common.minutes)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(Strings.WalkScheduleEditor.exerciseLimits)
        } footer: {
            Text(Strings.WalkScheduleEditor.maxDurationFooter(
                age: ageInMonths,
                minutes: schedule.maxDurationRule.maxDuration(ageInMonths: ageInMonths)
            ))
        }
    }

    // MARK: - Actions

    private func deleteWalks(at offsets: IndexSet) {
        schedule.walks.remove(atOffsets: offsets)
    }

    private func moveWalks(from source: IndexSet, to destination: Int) {
        schedule.walks.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Add Walk Sheet

struct AddWalkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var schedule: WalkSchedule

    @State private var label: String = ""
    @State private var targetTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(Strings.WalkScheduleEditor.walkName, text: $label)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    DatePicker(
                        Strings.WalkScheduleEditor.walkTime,
                        selection: $targetTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            .navigationTitle(Strings.WalkScheduleEditor.addWalk)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        addWalk()
                    }
                    .disabled(label.isEmpty)
                }
            }
            .onAppear {
                // Default label based on position
                let count = schedule.walks.count + 1
                label = Strings.Notifications.walkNumber(count)

                // Default time: 2 hours after last walk, or 8am
                if let lastWalk = schedule.walks.last,
                   let lastTime = DateFormatters.timeOnly.date(from: lastWalk.targetTime) {
                    targetTime = lastTime.addingTimeInterval(2 * 60 * 60)
                } else {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                    components.hour = 8
                    components.minute = 0
                    targetTime = Calendar.current.date(from: components) ?? Date()
                }
            }
        }
    }

    private func addWalk() {
        let newWalk = WalkSchedule.ScheduledWalk(
            label: label,
            targetTime: targetTime.timeString
        )
        schedule.walks.append(newWalk)
        // Sort by time
        schedule.walks.sort { $0.targetTime < $1.targetTime }
        dismiss()
    }
}

// MARK: - Edit Walk Sheet

struct EditScheduledWalkSheet: View {
    @Environment(\.dismiss) private var dismiss

    let walk: WalkSchedule.ScheduledWalk
    @Binding var schedule: WalkSchedule

    @State private var label: String = ""
    @State private var targetTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(Strings.WalkScheduleEditor.walkName, text: $label)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    DatePicker(
                        Strings.WalkScheduleEditor.walkTime,
                        selection: $targetTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                Section {
                    Button(role: .destructive) {
                        deleteWalk()
                    } label: {
                        Label(Strings.WalkScheduleEditor.deleteWalk, systemImage: "trash")
                    }
                }
            }
            .navigationTitle(Strings.WalkScheduleEditor.editWalk)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveChanges()
                    }
                    .disabled(label.isEmpty)
                }
            }
            .onAppear {
                label = walk.label
                targetTime = DateFormatters.timeOnly.date(from: walk.targetTime) ?? Date()
            }
        }
    }

    private func saveChanges() {
        guard let index = schedule.walks.firstIndex(where: { $0.id == walk.id }) else {
            dismiss()
            return
        }

        schedule.walks[index].label = label
        schedule.walks[index].targetTime = targetTime.timeString
        // Re-sort by time
        schedule.walks.sort { $0.targetTime < $1.targetTime }
        dismiss()
    }

    private func deleteWalk() {
        schedule.walks.removeAll { $0.id == walk.id }
        dismiss()
    }
}

// MARK: - Wrapper for SettingsView

struct WalkScheduleEditorWrapper: View {
    let initialSchedule: WalkSchedule
    let ageInMonths: Int
    let onSave: (WalkSchedule) -> Void

    var body: some View {
        WalkScheduleEditor(
            initialSchedule: initialSchedule,
            ageInMonths: ageInMonths,
            onSave: onSave
        )
    }
}

#Preview {
    WalkScheduleEditor(
        initialSchedule: WalkSchedule.defaultSchedule(ageWeeks: 16),
        ageInMonths: 4,
        onSave: { _ in }
    )
}
