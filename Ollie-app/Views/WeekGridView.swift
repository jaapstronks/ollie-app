//
//  WeekGridView.swift
//  Ollie-app
//
//  Week overview grid showing 7 days of metrics

import SwiftUI

/// Row configuration for the week grid
private struct WeekGridRow: Identifiable {
    let id = UUID()
    let emoji: String
    let label: String
    let color: Color
    let getValue: (DayStats) -> String
}

/// 7-day grid showing daily counts for key metrics
struct WeekGridView: View {
    let weekStats: [DayStats]

    @Environment(\.colorScheme) private var colorScheme

    private let rows: [WeekGridRow] = [
        WeekGridRow(emoji: "🚽", label: "Buiten", color: .ollieSuccess) { stats in
            stats.outdoorPotty > 0 ? "\(stats.outdoorPotty)" : "–"
        },
        WeekGridRow(emoji: "⚠️", label: "Binnen", color: .ollieDanger) { stats in
            stats.indoorPotty > 0 ? "\(stats.indoorPotty)" : "–"
        },
        WeekGridRow(emoji: "🍽️", label: "Eten", color: .ollieAccent) { stats in
            stats.meals > 0 ? "\(stats.meals)" : "–"
        },
        WeekGridRow(emoji: "🚶", label: "Uitlaten", color: .ollieInfo) { stats in
            stats.walks > 0 ? "\(stats.walks)" : "–"
        },
        WeekGridRow(emoji: "😴", label: "Slapen", color: .ollieSleep) { stats in
            stats.sleepHours > 0 ? String(format: "%.0f", stats.sleepHours) : "–"
        },
        WeekGridRow(emoji: "🎓", label: "Training", color: Color(hex: "9B59B6")) { stats in
            stats.trainingSessions > 0 ? "\(stats.trainingSessions)" : "–"
        }
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header row with dates
            headerRow

            // Metric rows
            ForEach(rows) { row in
                metricRow(row)
            }
        }
        .padding(12)
        .glassCard(tint: .none)
    }

    // MARK: - Header Row

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 0) {
            // Empty corner cell
            Text("")
                .frame(width: 60)

            // Date headers
            ForEach(weekStats) { day in
                Text(day.shortDateLabel)
                    .font(.caption2)
                    .fontWeight(day.isToday ? .bold : .regular)
                    .foregroundStyle(day.isToday ? Color.ollieAccent : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        day.isToday ?
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.15))
                        : nil
                    )
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Metric Row

    @ViewBuilder
    private func metricRow(_ row: WeekGridRow) -> some View {
        HStack(spacing: 0) {
            // Row label
            HStack(spacing: 4) {
                Text(row.emoji)
                    .font(.caption)
                Text(row.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60, alignment: .leading)

            // Values for each day
            ForEach(weekStats) { day in
                let value = row.getValue(day)
                let isZero = value == "–"

                Text(value)
                    .font(.caption)
                    .fontWeight(isZero ? .regular : .semibold)
                    .foregroundStyle(isZero ? Color.gray.opacity(0.4) : row.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        day.isToday ?
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.1 : 0.08))
                        : nil
                    )
            }
        }

        if row.label != "Training" {
            Divider()
                .opacity(0.5)
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

    return WeekGridView(weekStats: sampleStats)
        .padding()
}
