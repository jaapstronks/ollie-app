//
//  DevelopmentPhaseCard.swift
//  Otis-app
//
//  Card showing current developmental phase and active periods (socialization window, sensitive phases)
//  for the Health tab

import SwiftUI
import OtisShared

/// Card displaying current developmental stage and active periods
struct DevelopmentPhaseCard: View {
    let birthDate: Date
    let puppyName: String
    let activePeriods: [Milestone]

    @Environment(\.colorScheme) private var colorScheme

    private var ageInWeeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0
    }

    private var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(Color.otisPurple)
                    .accessibilityHidden(true)
                Text(Strings.Development.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            // Current stage indicator
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Development.currentStage)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(currentStageName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Age badge
                VStack(alignment: .trailing, spacing: 2) {
                    if ageInWeeks <= 16 {
                        Text(Strings.Socialization.weekNumber(ageInWeeks))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.otisPurple)
                    } else {
                        Text(Strings.Health.monthsOld(ageInMonths))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.otisPurple)
                    }
                }
            }

            // Stage description
            Text(currentStageDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Active periods (if any)
            if !activePeriods.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Development.activePeriods)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ForEach(uniquePeriods) { milestone in
                        activePeriodRow(for: milestone)
                    }
                }
            }
        }
        .padding()
        .glassCard(tint: .custom(Color.otisPurple))
    }

    // MARK: - Active Period Row

    @ViewBuilder
    private func activePeriodRow(for milestone: Milestone) -> some View {
        let isSocialization = milestone.labelKey.contains("socialization")

        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(periodColor(for: milestone).opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: periodIcon(for: milestone))
                    .font(.system(size: 14))
                    .foregroundStyle(periodColor(for: milestone))
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(periodTitle(for: milestone))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(periodAdvice(for: milestone))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Weeks remaining (for socialization)
            if isSocialization, let weeksRemaining = socializationWeeksRemaining {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(weeksRemaining)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.otisAccent)
                    Text(weeksRemaining == 1 ? Strings.Common.week : Strings.Common.weeks)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(periodColor(for: milestone).opacity(colorScheme == .dark ? 0.1 : 0.05))
        )
    }

    // MARK: - Stage Helpers

    private var currentStageName: String {
        switch ageInWeeks {
        case 0..<2:
            return Strings.Development.stageNeonatal
        case 2..<3:
            return Strings.Development.stageTransitional
        case 3...16:
            return Strings.Development.stageSocialization
        case 17...26: // ~4-6 months
            return Strings.Development.stageJuvenile
        case 27...78: // ~6-18 months
            return Strings.Development.stageAdolescent
        default:
            return Strings.Development.stageAdult
        }
    }

    private var currentStageDescription: String {
        switch ageInWeeks {
        case 0..<2:
            return Strings.Development.stageNeonatalDesc
        case 2..<3:
            return Strings.Development.stageTransitionalDesc
        case 3...16:
            return Strings.Development.stageSocializationDesc
        case 17...26:
            return Strings.Development.stageJuvenileDesc
        case 27...78:
            return Strings.Development.stageAdolescentDesc
        default:
            return Strings.Development.stageAdultDesc
        }
    }

    // MARK: - Period Helpers

    private var uniquePeriods: [Milestone] {
        var seen = Set<String>()
        return activePeriods.filter { milestone in
            let periodType: String
            if milestone.labelKey.contains("socialization") {
                periodType = "socialization"
            } else if milestone.labelKey.contains("fearPeriod1") {
                periodType = "fearPeriod1"
            } else if milestone.labelKey.contains("fearPeriod2") {
                periodType = "fearPeriod2"
            } else {
                periodType = milestone.labelKey
            }

            if seen.contains(periodType) {
                return false
            }
            seen.insert(periodType)
            return true
        }
    }

    private func periodTitle(for milestone: Milestone) -> String {
        if milestone.labelKey.contains("socialization") {
            return Strings.Development.socializationWindow
        } else if milestone.labelKey.contains("fearPeriod") {
            return Strings.Development.sensitivePeriod
        }
        return milestone.localizedLabel
    }

    private func periodAdvice(for milestone: Milestone) -> String {
        if milestone.labelKey.contains("socialization") {
            return Strings.Development.socializationAdvice
        } else if milestone.labelKey.contains("fearPeriod") {
            return Strings.Development.sensitivePeriodAdvice(name: puppyName)
        }
        return milestone.localizedDetail ?? ""
    }

    private func periodIcon(for milestone: Milestone) -> String {
        if milestone.labelKey.contains("socialization") {
            return "person.3.fill"
        } else if milestone.labelKey.contains("fearPeriod") {
            return "heart.fill"
        }
        return milestone.icon
    }

    private func periodColor(for milestone: Milestone) -> Color {
        if milestone.labelKey.contains("socialization") {
            return .otisAccent
        } else if milestone.labelKey.contains("fearPeriod") {
            return .otisRose
        }
        return .otisInfo
    }

    private var socializationWeeksRemaining: Int? {
        let socializationEndWeek = 16
        let remaining = socializationEndWeek - ageInWeeks

        if remaining > 0 && remaining <= 12 {
            return remaining
        }
        return nil
    }
}

// MARK: - Preview

#Preview("With Active Periods") {
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -10, to: Date())!

    let milestones = [
        Milestone(
            category: .developmental,
            labelKey: "milestone.socializationPeak",
            targetAgeWeeks: 12,
            icon: "person.3.fill",
            isActionable: false
        ),
        Milestone(
            category: .developmental,
            labelKey: "milestone.fearPeriod1",
            targetAgeWeeks: 8,
            icon: "heart.fill",
            isActionable: false
        )
    ]

    DevelopmentPhaseCard(
        birthDate: birthDate,
        puppyName: "Luna",
        activePeriods: milestones
    )
    .padding()
}

#Preview("No Active Periods") {
    let birthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date())!

    DevelopmentPhaseCard(
        birthDate: birthDate,
        puppyName: "Luna",
        activePeriods: []
    )
    .padding()
}
