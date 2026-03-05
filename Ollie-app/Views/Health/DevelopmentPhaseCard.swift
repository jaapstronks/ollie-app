//
//  DevelopmentPhaseCard.swift
//  Otis-app
//
//  Compact card showing current developmental stage for the Health tab
//  Taps to open DevelopmentJourneySheet for full details
//

import SwiftUI
import OtisShared

/// Compact card displaying current developmental stage
/// Detailed period info is in the DevelopmentJourneySheet
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

    private var uniquePeriodsCount: Int {
        var seen = Set<String>()
        for milestone in activePeriods {
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
            seen.insert(periodType)
        }
        return seen.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with chevron
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(Color.otisPurple)
                    .accessibilityHidden(true)
                Text(Strings.Development.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Stage name and age
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentStageName)
                        .font(.title3)
                        .fontWeight(.semibold)

                    // Age display
                    if ageInWeeks <= 16 {
                        Text(Strings.Socialization.weekNumber(ageInWeeks))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(Strings.Health.monthsOld(ageInMonths))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Active periods count badge
                if uniquePeriodsCount > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(uniquePeriodsCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.otisPurple)
                        Text(Strings.Development.activePeriods)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Tap hint
            Text(Strings.Common.tapToExpand)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .glassCard(tint: .custom(Color.otisPurple))
    }

    // MARK: - Stage Helpers

    private var currentStage: DevelopmentStage {
        DevelopmentStage.stage(for: ageInWeeks)
    }

    private var currentStageName: String {
        currentStage.title
    }
}

// MARK: - Preview

#Preview("Socialization Stage") {
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

#Preview("Juvenile Stage") {
    let birthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date())!

    DevelopmentPhaseCard(
        birthDate: birthDate,
        puppyName: "Luna",
        activePeriods: []
    )
    .padding()
}
