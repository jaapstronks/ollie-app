//
//  WeightGoalView.swift
//  Otis-app
//
//  Full weight goal management view
//

import SwiftUI
import OtisShared

/// Full view for managing weight goals
struct WeightGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RoutineStore.self) private var routineStore
    @Environment(WeightStore.self) private var weightStore

    @State private var showSetGoalSheet = false

    @EnvironmentObject private var unitPreferences: UnitPreferences

    private var weightUnit: WeightUnit {
        unitPreferences.weightUnit
    }

    private var currentWeight: Double? {
        weightStore.latestWeight?.weight
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current goal section
                    if let goal = routineStore.weightGoal {
                        currentGoalCard(goal)
                    } else {
                        noGoalCard
                    }

                    // Goal history
                    if !routineStore.weightGoalHistory.isEmpty {
                        goalHistorySection
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.WeightGoal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSetGoalSheet) {
                SetWeightGoalSheet()
            }
        }
    }

    // MARK: - Current Goal Card

    @ViewBuilder
    private func currentGoalCard(_ goal: WeightGoal) -> some View {
        VStack(spacing: 16) {
            // Direction and target
            HStack {
                Image(systemName: goal.direction.icon)
                    .font(.title2)
                    .foregroundStyle(Color(goal.direction.color))

                VStack(alignment: .leading) {
                    Text(goal.direction.label)
                        .font(.headline)
                    Text("\(Strings.WeightGoal.targetWeight): \(weightUnit.format(goal.targetWeightKg))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let current = currentWeight {
                    VStack(alignment: .trailing) {
                        Text(weightUnit.format(current))
                            .font(.title2.bold())
                        Text(Strings.WeightGoal.currentWeight)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress
            if let current = currentWeight {
                let progress = goal.progressPercentage(currentWeightKg: current)
                let remaining = goal.weightRemaining(currentWeightKg: current)

                VStack(spacing: 8) {
                    ProgressView(value: min(progress / 100, 1.0))
                        .tint(progress >= 100 ? .green : .blue)

                    HStack {
                        Text("\(Int(progress))%")
                            .font(.subheadline.bold())
                            .foregroundStyle(progress >= 100 ? .green : .blue)

                        Spacer()

                        if progress < 100 {
                            Text("\(weightUnit.format(remaining)) \(Strings.WeightGoal.remaining)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(Strings.WeightGoal.achieved)
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            // Target date
            if let targetDate = goal.targetDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)

                    if goal.isOverdue {
                        Text(Strings.WeightGoal.overdue)
                            .foregroundStyle(.red)
                    } else if let days = goal.daysRemaining {
                        Text(Strings.WeightGoal.daysRemaining(days))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(targetDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            // Actions
            HStack {
                Button {
                    showSetGoalSheet = true
                } label: {
                    Label(Strings.WeightGoal.editGoal, systemImage: "pencil")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(role: .destructive) {
                    var updatedGoal = goal
                    updatedGoal.isActive = false
                    routineStore.updateWeightGoal(updatedGoal)
                } label: {
                    Label(Strings.Common.archive, systemImage: "archivebox")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - No Goal Card

    @ViewBuilder
    private var noGoalCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(Strings.WeightGoal.setGoal)
                .font(.headline)

            Text("Set a weight goal to track progress over time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showSetGoalSheet = true
            } label: {
                Label(Strings.WeightGoal.setGoal, systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Goal History Section

    @ViewBuilder
    private var goalHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.BodyCondition.history)
                .font(.headline)

            ForEach(routineStore.weightGoalHistory.filter { !$0.isActive }) { goal in
                HStack {
                    Image(systemName: goal.direction.icon)
                        .foregroundStyle(Color(goal.direction.color))

                    VStack(alignment: .leading) {
                        Text(weightUnit.format(goal.targetWeightKg))
                            .font(.subheadline)
                        Text(goal.startDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("Archived")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Set Weight Goal Sheet

private struct SetWeightGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RoutineStore.self) private var routineStore
    @Environment(WeightStore.self) private var weightStore

    @State private var targetWeight: Double = 25.0
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Date().addingTimeInterval(90 * 24 * 60 * 60) // 90 days
    @State private var note: String = ""

    @EnvironmentObject private var unitPreferences: UnitPreferences

    private var weightUnit: WeightUnit {
        unitPreferences.weightUnit
    }

    private var currentWeight: Double {
        weightStore.latestWeight?.weight ?? 25.0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(Strings.WeightGoal.currentWeight) {
                    Text(weightUnit.format(currentWeight))
                        .foregroundStyle(.secondary)
                }

                Section(Strings.WeightGoal.targetWeight) {
                    HStack {
                        Slider(value: $targetWeight, in: 1...100, step: 0.5)

                        Text(weightUnit.format(targetWeight))
                            .frame(width: 60)
                            .font(.headline)
                    }
                }

                Section {
                    Toggle(Strings.WeightGoal.targetDate, isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker(
                            Strings.WeightGoal.targetDate,
                            selection: $targetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                }

                Section {
                    TextField(Strings.Common.note, text: $note)
                }
            }
            .navigationTitle(Strings.WeightGoal.setGoal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        let goal = WeightGoal(
                            targetWeightKg: targetWeight,
                            startWeightKg: currentWeight,
                            targetDate: hasTargetDate ? targetDate : nil,
                            note: note.isEmpty ? nil : note
                        )
                        routineStore.addWeightGoal(goal)
                        dismiss()
                    }
                }
            }
            .onAppear {
                targetWeight = currentWeight
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WeightGoalView()
        .environment(RoutineStore())
        .environment(WeightStore())
}
