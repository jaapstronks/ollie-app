//
//  PottyTrendChart.swift
//  Ollie-app
//
//  Line chart showing outdoor potty percentage over the last 7 days

import SwiftUI
import Charts

/// Data point for the potty trend chart
struct PottyTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let percentage: Int

    /// Color based on percentage: green (>=70%), orange (40-69%), red (<40%)
    var color: Color {
        if percentage >= 70 {
            return .ollieSuccess
        } else if percentage >= 40 {
            return .ollieWarning
        } else {
            return .ollieDanger
        }
    }

    /// Short day label (e.g., "ma")
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "E"
        return formatter.string(from: date).lowercased()
    }
}

/// Line chart showing outdoor potty percentage per day
struct PottyTrendChart: View {
    let weekStats: [DayStats]

    @Environment(\.colorScheme) private var colorScheme

    private var trendPoints: [PottyTrendPoint] {
        weekStats.map { day in
            PottyTrendPoint(date: day.date, percentage: day.outdoorPercentage)
        }
    }

    private var hasData: Bool {
        weekStats.contains { $0.outdoorPotty + $0.indoorPotty > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ollieSuccess)

                Text(Strings.Insights.trends)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            if hasData {
                chartView
            } else {
                noDataView
            }
        }
        .padding()
        .glassCard(tint: .success)
    }

    @ViewBuilder
    private var chartView: some View {
        Chart {
            // Area fill
            ForEach(trendPoints) { point in
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Percentage", point.percentage)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.ollieSuccess.opacity(0.3),
                            Color.ollieSuccess.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Line
            ForEach(trendPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Percentage", point.percentage)
                )
                .foregroundStyle(Color.ollieSuccess)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }

            // Points with value labels
            ForEach(trendPoints) { point in
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Percentage", point.percentage)
                )
                .foregroundStyle(point.color)
                .symbolSize(60)
                .annotation(position: .top, spacing: 4) {
                    if point.percentage > 0 {
                        Text("\(point.percentage)%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(point.color)
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .frame(height: 160)
    }

    @ViewBuilder
    private var noDataView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text(Strings.Stats.insufficientData)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleStats = [
        DayStats(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
                 outdoorPotty: 5, indoorPotty: 1, meals: 3, walks: 2, sleepHours: 14, trainingSessions: 1),
        DayStats(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                 outdoorPotty: 6, indoorPotty: 0, meals: 3, walks: 2, sleepHours: 15, trainingSessions: 2),
        DayStats(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
                 outdoorPotty: 4, indoorPotty: 2, meals: 3, walks: 1, sleepHours: 13, trainingSessions: 0),
        DayStats(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                 outdoorPotty: 7, indoorPotty: 0, meals: 3, walks: 3, sleepHours: 16, trainingSessions: 1),
        DayStats(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                 outdoorPotty: 5, indoorPotty: 1, meals: 3, walks: 2, sleepHours: 14, trainingSessions: 0),
        DayStats(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                 outdoorPotty: 6, indoorPotty: 0, meals: 3, walks: 2, sleepHours: 15, trainingSessions: 2),
        DayStats(date: Date(),
                 outdoorPotty: 3, indoorPotty: 0, meals: 2, walks: 1, sleepHours: 8, trainingSessions: 0)
    ]

    return PottyTrendChart(weekStats: sampleStats)
        .padding()
}
