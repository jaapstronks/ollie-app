//
//  GroomingScheduleView.swift
//  Otis-app
//
//  Full grooming schedule management view
//

import SwiftUI
import OtisShared

/// Full view for managing grooming schedule
struct GroomingScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var routineStore: RoutineStore

    @State private var editingActivity: GroomingActivity?

    var body: some View {
        NavigationStack {
            List {
                // Overdue section
                if !routineStore.overdueGroomingActivities.isEmpty {
                    Section(Strings.Grooming.overdue) {
                        ForEach(routineStore.overdueGroomingActivities) { activity in
                            GroomingScheduleRow(
                                activity: activity,
                                onMarkComplete: {
                                    routineStore.markGroomingCompleted(activity)
                                },
                                onEdit: {
                                    editingActivity = activity
                                }
                            )
                        }
                    }
                }

                // Due soon section
                let dueSoon = routineStore.dueGroomingActivities.filter { !$0.isOverdue }
                if !dueSoon.isEmpty {
                    Section(Strings.Grooming.due) {
                        ForEach(dueSoon) { activity in
                            GroomingScheduleRow(
                                activity: activity,
                                onMarkComplete: {
                                    routineStore.markGroomingCompleted(activity)
                                },
                                onEdit: {
                                    editingActivity = activity
                                }
                            )
                        }
                    }
                }

                // Upcoming section
                let upcoming = routineStore.groomingActivities.filter { $0.isEnabled && !$0.isDue }
                if !upcoming.isEmpty {
                    Section(Strings.Grooming.upcoming) {
                        ForEach(upcoming.sortedByUrgency()) { activity in
                            GroomingScheduleRow(
                                activity: activity,
                                onMarkComplete: {
                                    routineStore.markGroomingCompleted(activity)
                                },
                                onEdit: {
                                    editingActivity = activity
                                }
                            )
                        }
                    }
                }

                // All activities section (collapsed by default)
                Section {
                    DisclosureGroup("All activities") {
                        ForEach(GroomingType.allCases, id: \.self) { type in
                            let activity = routineStore.groomingActivities.first { $0.type == type }

                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(.purple)
                                    .frame(width: 24)

                                VStack(alignment: .leading) {
                                    Text(type.label)
                                        .font(.subheadline)
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if activity != nil {
                                    Toggle("", isOn: Binding(
                                        get: { activity?.isEnabled ?? false },
                                        set: { enabled in
                                            if var activity = activity {
                                                activity.isEnabled = enabled
                                                routineStore.updateGroomingActivity(activity)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                } else {
                                    Button {
                                        let newActivity = GroomingActivity(type: type)
                                        routineStore.addGroomingActivity(newActivity)
                                    } label: {
                                        Text("Add")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.Grooming.schedule)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingActivity) { activity in
                GroomingEditSheet(activity: activity)
            }
        }
    }
}

// MARK: - Grooming Schedule Row

private struct GroomingScheduleRow: View {
    let activity: GroomingActivity
    let onMarkComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: activity.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(activity.isOverdue ? .red : .purple)
                .frame(width: 32, height: 32)
                .background(
                    (activity.isOverdue ? Color.red : Color.purple)
                        .opacity(0.1)
                )
                .clipShape(Circle())

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.type.label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(activity.statusLabel)
                        .foregroundStyle(activity.isOverdue ? .red : .secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(Strings.Grooming.everyDays(activity.intervalDays))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onMarkComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}

// MARK: - Grooming Edit Sheet

private struct GroomingEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var routineStore: RoutineStore

    let activity: GroomingActivity

    @State private var intervalDays: Int = 7
    @State private var isEnabled: Bool = true
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: activity.type.icon)
                            .foregroundStyle(.purple)
                        Text(activity.type.label)
                            .font(.headline)
                    }

                    Text(activity.type.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section(Strings.Grooming.interval) {
                    Stepper(
                        Strings.Grooming.everyDays(intervalDays),
                        value: $intervalDays,
                        in: 1...365
                    )
                }

                Section {
                    Toggle(Strings.Routine.enabled, isOn: $isEnabled)
                }

                Section(Strings.Grooming.lastCompleted) {
                    if let lastCompleted = activity.lastCompleted {
                        Text(lastCompleted, style: .date)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(Strings.Grooming.notYetDone)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        routineStore.markGroomingCompleted(activity)
                        dismiss()
                    } label: {
                        Label(Strings.Grooming.markComplete, systemImage: "checkmark.circle")
                    }
                }

                Section {
                    TextField(Strings.Common.note, text: $note)
                }
            }
            .navigationTitle(activity.type.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        var updated = activity
                        updated.intervalDays = intervalDays
                        updated.isEnabled = isEnabled
                        updated.note = note.isEmpty ? nil : note
                        routineStore.updateGroomingActivity(updated)
                        dismiss()
                    }
                }
            }
            .onAppear {
                intervalDays = activity.intervalDays
                isEnabled = activity.isEnabled
                note = activity.note ?? ""
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GroomingScheduleView()
        .environmentObject(RoutineStore())
}
