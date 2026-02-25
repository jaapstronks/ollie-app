//
//  InsightsWeekOverviewSection.swift
//  Ollie-app
//
//  Week overview section with grid and trend chart
//

import SwiftUI
import OllieShared

/// Week overview section showing grid and potty trend
struct InsightsWeekOverviewSection: View {
    let weekStats: [DayStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ollieInfo)
                    .accessibilityHidden(true)

                Text(Strings.Insights.weekOverview)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.isHeader)

            // Week grid
            WeekGridView(weekStats: weekStats)

            // Potty trend chart
            PottyTrendChart(weekStats: weekStats)
        }
    }
}
