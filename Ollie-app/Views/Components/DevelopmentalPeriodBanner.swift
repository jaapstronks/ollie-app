//
//  DevelopmentalPeriodBanner.swift
//  Ollie-app
//
//  Banner component for displaying active developmental periods
//  (socialization window, fear periods) at the top of the Calendar view

import SwiftUI
import OllieShared

/// Banner displaying active developmental periods as prominent status indicators
struct DevelopmentalPeriodBanner: View {
    let milestone: Milestone
    let birthDate: Date

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(periodColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: periodIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(periodColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(periodTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(periodAdvice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Weeks remaining indicator (for socialization window)
            if let weeksRemaining = weeksRemaining {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(weeksRemaining)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(periodColor)
                    Text(weeksRemaining == 1 ? Strings.Common.week : Strings.Common.weeks)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(periodColor.opacity(colorScheme == .dark ? 0.15 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(periodColor.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(periodTitle)
        .accessibilityValue(periodAdvice)
    }

    // MARK: - Computed Properties

    private var periodTitle: String {
        if milestone.labelKey.contains("socialization") {
            return Strings.Development.socializationWindow
        } else if milestone.labelKey.contains("fearPeriod") {
            return Strings.Development.fearPeriod
        }
        return milestone.localizedLabel
    }

    private var periodAdvice: String {
        if milestone.labelKey.contains("socialization") {
            return Strings.Development.socializationAdvice
        } else if milestone.labelKey.contains("fearPeriod") {
            return Strings.Development.fearPeriodAdvice
        }
        return milestone.localizedDetail ?? ""
    }

    private var periodIcon: String {
        if milestone.labelKey.contains("socialization") {
            return "person.3.fill"
        } else if milestone.labelKey.contains("fearPeriod") {
            return "exclamationmark.triangle.fill"
        }
        return milestone.icon
    }

    private var periodColor: Color {
        if milestone.labelKey.contains("socialization") {
            return .ollieAccent
        } else if milestone.labelKey.contains("fearPeriod") {
            return .ollieWarning
        }
        return .ollieInfo
    }

    private var weeksRemaining: Int? {
        // Only show weeks remaining for socialization window
        guard milestone.labelKey.contains("socialization") else { return nil }

        let calendar = Calendar.current
        let ageInWeeks = calendar.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0

        // Socialization window ends at 16 weeks
        let socializationEndWeek = 16
        let remaining = socializationEndWeek - ageInWeeks

        // Only show if positive and reasonable
        if remaining > 0 && remaining <= 12 {
            return remaining
        }
        return nil
    }
}

// MARK: - Banner Stack

/// Container for displaying multiple developmental period banners
struct DevelopmentalPeriodBanners: View {
    let milestones: [Milestone]
    let birthDate: Date

    var body: some View {
        if !milestones.isEmpty {
            VStack(spacing: 8) {
                ForEach(uniquePeriods) { milestone in
                    DevelopmentalPeriodBanner(
                        milestone: milestone,
                        birthDate: birthDate
                    )
                }
            }
        }
    }

    /// Filter to show only one banner per period type
    private var uniquePeriods: [Milestone] {
        var seen = Set<String>()
        return milestones.filter { milestone in
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
}

// MARK: - Preview

#Preview("Socialization Window") {
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -10, to: Date())!

    let milestone = Milestone(
        category: .developmental,
        labelKey: "milestone.socializationPeak",
        detailKey: "milestone.socializationPeak.detail",
        targetAgeWeeks: 12,
        icon: "person.3.fill",
        isActionable: false
    )

    DevelopmentalPeriodBanner(
        milestone: milestone,
        birthDate: birthDate
    )
    .padding()
}

#Preview("Fear Period") {
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -8, to: Date())!

    let milestone = Milestone(
        category: .developmental,
        labelKey: "milestone.fearPeriod1",
        detailKey: "milestone.fearPeriod1.detail",
        targetAgeWeeks: 8,
        icon: "exclamationmark.triangle.fill",
        isActionable: false
    )

    DevelopmentalPeriodBanner(
        milestone: milestone,
        birthDate: birthDate
    )
    .padding()
}

#Preview("Multiple Banners") {
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -9, to: Date())!

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
            icon: "exclamationmark.triangle.fill",
            isActionable: false
        )
    ]

    DevelopmentalPeriodBanners(
        milestones: milestones,
        birthDate: birthDate
    )
    .padding()
}
