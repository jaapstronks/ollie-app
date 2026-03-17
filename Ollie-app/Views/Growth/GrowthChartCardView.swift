//
//  GrowthChartCardView.swift
//  Otis-app
//
//  Shareable weight growth chart card (1080x1350 portrait)
//

import SwiftUI
import Charts
import OtisShared

/// A shareable portrait card showing weight growth chart
/// Designed for social media sharing at 1080x1350 resolution
struct GrowthChartCardView: View {
    let puppyName: String
    let chartPoints: [WeightChartPoint]
    let startWeight: Double
    let currentWeight: Double
    let growthMultiplier: String
    let weightUnit: WeightUnit

    // Card dimensions (4:5 portrait for Instagram)
    private let cardSize = CGSize(width: 1080, height: 1350)

    /// Weight gain formatted
    private var weightGain: Double {
        currentWeight - startWeight
    }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 40) {
                Spacer()

                // Title
                titleSection

                // Chart
                chartSection

                // Stats row
                statsRow

                Spacer()

                // Branding footer
                branding
            }
            .padding(48)
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.otisAccent.opacity(0.2),
                Color(UIColor.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Title Section

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(Strings.GrowthCards.growthJourneyTitle(name: puppyName))
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24))
                Text(Strings.GrowthCards.growthChart)
                    .font(.system(size: 24, weight: .medium))
            }
            .foregroundStyle(Color.otisAccent)
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private var chartSection: some View {
        Chart {
            ForEach(chartPoints) { point in
                LineMark(
                    x: .value("Week", point.ageWeeks),
                    y: .value("Weight", point.weightKg)
                )
                .foregroundStyle(Color.otisAccent)
                .lineStyle(StrokeStyle(lineWidth: 4))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Week", point.ageWeeks),
                    y: .value("Weight", point.weightKg)
                )
                .foregroundStyle(Color.otisAccent)
                .symbolSize(100)
            }

            // Area fill under the line
            ForEach(chartPoints) { point in
                AreaMark(
                    x: .value("Week", point.ageWeeks),
                    y: .value("Weight", point.weightKg)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.otisAccent.opacity(0.3), Color.otisAccent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                AxisValueLabel {
                    if let weeks = value.as(Int.self) {
                        Text("\(weeks)w")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                AxisValueLabel {
                    if let kg = value.as(Double.self) {
                        Text(weightUnit.formatShort(kg))
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 400)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(24)
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 40) {
            statItem(
                label: Strings.GrowthCards.starting,
                value: weightUnit.format(startWeight),
                color: .secondary
            )

            statItem(
                label: Strings.GrowthCards.current,
                value: weightUnit.format(currentWeight),
                color: .otisAccent
            )

            statItem(
                label: Strings.GrowthCards.growth,
                value: growthMultiplier,
                color: .otisPurple
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(20)
    }

    @ViewBuilder
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    // MARK: - Branding

    @ViewBuilder
    private var branding: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 18))
                Text("ollie.pet")
                    .font(.system(size: 20, weight: .medium))
            }
            .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Weight Unit Extension

extension WeightUnit {
    /// Format weight for chart axis (shorter format)
    func formatShort(_ weight: Double) -> String {
        switch self {
        case .kg:
            return String(format: "%.1f", weight)
        case .lbs:
            return String(format: "%.1f", weight * 2.20462)
        }
    }
}

// MARK: - Preview

#Preview("Growth Chart") {
    let points = [
        WeightChartPoint(id: UUID(), date: Date().addingTimeInterval(-90 * 24 * 3600), weightKg: 2.0, ageWeeks: 8),
        WeightChartPoint(id: UUID(), date: Date().addingTimeInterval(-75 * 24 * 3600), weightKg: 3.2, ageWeeks: 10),
        WeightChartPoint(id: UUID(), date: Date().addingTimeInterval(-60 * 24 * 3600), weightKg: 4.5, ageWeeks: 12),
        WeightChartPoint(id: UUID(), date: Date().addingTimeInterval(-45 * 24 * 3600), weightKg: 5.8, ageWeeks: 14),
        WeightChartPoint(id: UUID(), date: Date().addingTimeInterval(-30 * 24 * 3600), weightKg: 6.9, ageWeeks: 16),
        WeightChartPoint(id: UUID(), date: Date().addingTimeInterval(-15 * 24 * 3600), weightKg: 7.8, ageWeeks: 18),
        WeightChartPoint(id: UUID(), date: Date(), weightKg: 8.5, ageWeeks: 20)
    ]

    return GrowthChartCardView(
        puppyName: "Max",
        chartPoints: points,
        startWeight: 2.0,
        currentWeight: 8.5,
        growthMultiplier: "4.3x",
        weightUnit: .kg
    )
    .scaleEffect(0.3)
}
