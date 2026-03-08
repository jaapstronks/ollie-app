//
//  WeightGoalCard.swift
//  Otis-app
//
//  Compact weight goal display card
//

import SwiftUI
import OtisShared

/// Compact card showing weight goal progress and latest BCS
struct WeightGoalCard: View {
    let goal: WeightGoal?
    let currentWeight: Double?
    let latestBCS: BodyConditionScore?
    let onGoalTap: () -> Void
    let onBCSTap: () -> Void

    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnitRaw = WeightUnit.kg.rawValue

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Weight goal section
                Button(action: onGoalTap) {
                    weightGoalSection
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 60)

                // BCS section
                Button(action: onBCSTap) {
                    bcsSection
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weight Goal Section

    @ViewBuilder
    private var weightGoalSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let goal = goal, let current = currentWeight {
                // Progress display
                let progress = goal.progressPercentage(currentWeightKg: current)

                HStack(spacing: 4) {
                    Image(systemName: goal.direction.icon)
                        .font(.caption)
                        .foregroundStyle(Color(goal.direction.color))

                    Text(weightUnit.format(goal.targetWeightKg))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                // Progress bar
                ProgressView(value: min(progress / 100, 1.0))
                    .tint(progressColor(for: progress))

                Text("\(Int(progress))% \(Strings.WeightGoal.progress)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // No goal state
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(Strings.WeightGoal.setGoal)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - BCS Section

    @ViewBuilder
    private var bcsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let bcs = latestBCS {
                HStack(spacing: 4) {
                    Text("\(bcs.score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(bcs.category.color))

                    Text("/9")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Text(bcs.category.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(bcs.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(Strings.BodyCondition.logScore)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func progressColor(for progress: Double) -> Color {
        if progress >= 100 {
            return .green
        } else if progress >= 50 {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // With goal and BCS
        WeightGoalCard(
            goal: WeightGoal.loseWeight(from: 32.0, to: 28.0),
            currentWeight: 30.5,
            latestBCS: BodyConditionScore(score: 6),
            onGoalTap: {},
            onBCSTap: {}
        )

        // No goal, no BCS
        WeightGoalCard(
            goal: nil,
            currentWeight: nil,
            latestBCS: nil,
            onGoalTap: {},
            onBCSTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
