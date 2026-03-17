//
//  InsightsWeekOverviewSection.swift
//  Otis-app
//
//  Week overview section with grid and trend chart
//

import SwiftUI
import OtisShared

/// Week overview section showing grid and potty trend
struct InsightsWeekOverviewSection: View {
    let weekStats: [DayStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.Insights.weekOverview, icon: "calendar.badge.clock", tint: .otisInfo)

            // Week grid
            WeekGridView(weekStats: weekStats)

            // Potty trend chart
            PottyTrendChart(weekStats: weekStats)
        }
    }
}
