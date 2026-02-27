//
//  WeightChartView.swift
//  Ollie-app
//
//  Growth curve chart using Swift Charts

import SwiftUI
import OllieShared
import Charts

/// Growth curve chart showing puppy weight vs reference
struct WeightChartView: View {
    let measurements: [WeightMeasurement]
    let referenceCurve: [GrowthReference]
    let puppyName: String

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnitRaw = WeightUnit.kg.rawValue

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    // Chart bounds (in display units)
    private var maxWeeks: Int {
        let measurementMax = measurements.map(\.ageWeeks).max() ?? 0
        let referenceMax = referenceCurve.last?.weeks ?? 78
        return max(measurementMax + 4, min(referenceMax, 52))
    }

    private var maxWeight: Double {
        let measurementMaxKg = measurements.map(\.weightKg).max() ?? 0
        let referenceMaxKg = referenceCurve.filter { $0.weeks <= maxWeeks }.map(\.kg).max() ?? 30
        let upperBandKg = referenceMaxKg * (1 + GrowthCurves.tolerancePercent)
        let maxKg = max(measurementMaxKg * 1.1, upperBandKg * 1.1)
        return weightUnit.convert(fromKg: maxKg)
    }

    /// Convert kg to display unit
    private func displayWeight(_ kg: Double) -> Double {
        weightUnit.convert(fromKg: kg)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Legend
            HStack(spacing: 16) {
                legendItem(color: .ollieAccent, label: puppyName)
                legendItem(color: .ollieMuted.opacity(0.5), label: Strings.Health.reference)
            }
            .font(.caption)
            .padding(.horizontal, 4)

            // Chart
            Chart {
                // Reference band (±15%)
                ForEach(referenceCurve.filter { $0.weeks <= maxWeeks }) { point in
                    let band = WeightCalculations.referenceBand(at: point.weeks, curve: referenceCurve)
                    AreaMark(
                        x: .value(Strings.Health.weeks, point.weeks),
                        yStart: .value("Min", displayWeight(band.min)),
                        yEnd: .value("Max", displayWeight(band.max))
                    )
                    .foregroundStyle(Color.ollieMuted.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .interpolationMethod(.catmullRom)
                }

                // Reference center line (dashed)
                ForEach(referenceCurve.filter { $0.weeks <= maxWeeks }) { point in
                    LineMark(
                        x: .value(Strings.Health.weeks, point.weeks),
                        y: .value(weightUnit.symbol, displayWeight(point.kg))
                    )
                    .foregroundStyle(Color.ollieMuted.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .interpolationMethod(.catmullRom)
                }

                // Puppy's actual data line
                ForEach(measurements) { measurement in
                    LineMark(
                        x: .value(Strings.Health.weeks, measurement.ageWeeks),
                        y: .value(weightUnit.symbol, displayWeight(measurement.weightKg))
                    )
                    .foregroundStyle(Color.ollieAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }

                // Puppy's data points
                ForEach(measurements) { measurement in
                    PointMark(
                        x: .value(Strings.Health.weeks, measurement.ageWeeks),
                        y: .value(weightUnit.symbol, displayWeight(measurement.weightKg))
                    )
                    .foregroundStyle(Color.ollieAccent)
                    .symbolSize(60)
                }
            }
            .chartXScale(domain: 0...maxWeeks)
            .chartYScale(domain: 0...maxWeight)
            .chartXAxis {
                AxisMarks(values: .stride(by: Double(weekStride))) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisTick()
                    AxisValueLabel {
                        if let weeks = value.as(Int.self) {
                            Text("\(weeks)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisTick()
                    AxisValueLabel {
                        if let kg = value.as(Double.self) {
                            Text("\(Int(kg))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 220)
        }
    }

    private var weekStride: Int {
        if maxWeeks <= 20 { return 4 }
        if maxWeeks <= 40 { return 8 }
        return 12
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty State

struct WeightChartEmptyView: View {
    let referenceCurve: [GrowthReference]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Legend
            HStack(spacing: 16) {
                legendItem(color: .ollieMuted.opacity(0.5), label: Strings.Health.reference)
            }
            .font(.caption)
            .padding(.horizontal, 4)

            // Chart with only reference
            Chart {
                ForEach(referenceCurve.filter { $0.weeks <= 52 }) { point in
                    let band = WeightCalculations.referenceBand(at: point.weeks, curve: referenceCurve)
                    AreaMark(
                        x: .value(Strings.Health.weeks, point.weeks),
                        yStart: .value("Min", band.min),
                        yEnd: .value("Max", band.max)
                    )
                    .foregroundStyle(Color.ollieMuted.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .interpolationMethod(.catmullRom)
                }

                ForEach(referenceCurve.filter { $0.weeks <= 52 }) { point in
                    LineMark(
                        x: .value(Strings.Health.weeks, point.weeks),
                        y: .value(Strings.Health.kg, point.kg)
                    )
                    .foregroundStyle(Color.ollieMuted.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXScale(domain: 0...52)
            .chartYScale(domain: 0...30)
            .chartXAxis {
                AxisMarks(values: .stride(by: 8.0)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisTick()
                    AxisValueLabel {
                        if let weeks = value.as(Int.self) {
                            Text("\(weeks)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisTick()
                    AxisValueLabel {
                        if let kg = value.as(Double.self) {
                            Text("\(Int(kg))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 220)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "scalemass")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text(Strings.Health.noWeightData)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("With Data") {
    let measurements = [
        WeightMeasurement(id: UUID(), date: Date().addingTimeInterval(-86400 * 14), weightKg: 4.5, ageWeeks: 8),
        WeightMeasurement(id: UUID(), date: Date().addingTimeInterval(-86400 * 7), weightKg: 6.2, ageWeeks: 9),
        WeightMeasurement(id: UUID(), date: Date(), weightKg: 7.8, ageWeeks: 10)
    ]

    return WeightChartView(
        measurements: measurements,
        referenceCurve: GrowthCurves.goldenRetrieverFemale,
        puppyName: "Ollie"
    )
    .padding()
}

#Preview("Empty") {
    WeightChartEmptyView(referenceCurve: GrowthCurves.goldenRetrieverFemale)
        .padding()
}
