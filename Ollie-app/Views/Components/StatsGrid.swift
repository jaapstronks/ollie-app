//
//  StatsGrid.swift
//  Ollie-app
//
//  Reusable grid component for displaying statistics
//  Reduces boilerplate in StatsCards.swift
//

import SwiftUI

// MARK: - Stat Item Data

/// Data model for a single stat item
struct StatItemData: Identifiable {
    let id = UUID()
    let value: String
    let label: String
    let iconName: String
    let iconColor: Color

    init(value: String, label: String, iconName: String, iconColor: Color) {
        self.value = value
        self.label = label
        self.iconName = iconName
        self.iconColor = iconColor
    }
}

// MARK: - Stats Row

/// A row of stat items with separators
struct StatsRow: View {
    let items: [StatItemData]

    var body: some View {
        HStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                StatItem(
                    value: item.value,
                    label: item.label,
                    iconName: item.iconName,
                    iconColor: item.iconColor
                )

                if index < items.count - 1 {
                    GlassSeparator()
                }
            }
        }
    }
}

// MARK: - Stats Grid

/// A grid of stat items organized in rows with dividers
struct StatsGrid<Footer: View>: View {
    let rows: [[StatItemData]]
    let footer: Footer?

    init(rows: [[StatItemData]], @ViewBuilder footer: () -> Footer) {
        self.rows = rows
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spacingM) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                StatsRow(items: row)

                if index < rows.count - 1 {
                    GlassDivider()
                }
            }

            if let footer {
                GlassDivider()
                footer
            }
        }
    }
}

// Empty footer extension
extension StatsGrid where Footer == EmptyView {
    init(rows: [[StatItemData]]) {
        self.rows = rows
        self.footer = nil
    }
}

// MARK: - Stats Card Wrapper

/// Complete stats card with grid layout and glass styling
struct StatsCardView<Footer: View>: View {
    let rows: [[StatItemData]]
    let tint: GlassTint
    let footer: Footer?

    init(
        rows: [[StatItemData]],
        tint: GlassTint = .accent,
        @ViewBuilder footer: () -> Footer
    ) {
        self.rows = rows
        self.tint = tint
        self.footer = footer()
    }

    var body: some View {
        StatsGrid(rows: rows) {
            if let footer {
                footer
            } else {
                EmptyView()
            }
        }
        .cardPadding()
        .glassCard(tint: tint)
    }
}

extension StatsCardView where Footer == EmptyView {
    init(rows: [[StatItemData]], tint: GlassTint = .accent) {
        self.rows = rows
        self.tint = tint
        self.footer = nil
    }
}

// MARK: - Simple Two-Column Stats Card

/// Convenience view for a simple two-column stats display
struct TwoColumnStatsCard: View {
    let leftItem: StatItemData
    let rightItem: StatItemData
    let tint: GlassTint
    let accentText: String?

    init(
        left: StatItemData,
        right: StatItemData,
        tint: GlassTint = .accent,
        accentText: String? = nil
    ) {
        self.leftItem = left
        self.rightItem = right
        self.tint = tint
        self.accentText = accentText
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spacingM) {
            HStack {
                StatItem(
                    value: leftItem.value,
                    label: leftItem.label,
                    iconName: leftItem.iconName,
                    iconColor: leftItem.iconColor
                )

                GlassSeparator()

                StatItem(
                    value: rightItem.value,
                    label: rightItem.label,
                    iconName: rightItem.iconName,
                    iconColor: rightItem.iconColor
                )
            }

            if let text = accentText {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(tint.color ?? Color.ollieAccent)
            }
        }
        .cardPadding()
        .glassCard(tint: tint)
    }
}

// MARK: - Preview

#Preview("Stats Grid") {
    ScrollView {
        VStack(spacing: 20) {
            // Two column card
            TwoColumnStatsCard(
                left: StatItemData(
                    value: "5",
                    label: "Current Streak",
                    iconName: "flame.fill",
                    iconColor: .orange
                ),
                right: StatItemData(
                    value: "12",
                    label: "Best Ever",
                    iconName: "trophy.fill",
                    iconColor: .ollieAccent
                ),
                tint: .accent,
                accentText: "Great job! Keep it up!"
            )

            // Multi-row grid
            StatsCardView(
                rows: [
                    [
                        StatItemData(value: "1h 15m", label: "Median", iconName: "chart.bar.fill", iconColor: .ollieInfo),
                        StatItemData(value: "1h 20m", label: "Average", iconName: "chart.line.uptrend.xyaxis", iconColor: .ollieInfo)
                    ],
                    [
                        StatItemData(value: "45m", label: "Shortest", iconName: "bolt.fill", iconColor: .ollieWarning),
                        StatItemData(value: "2h 30m", label: "Longest", iconName: "tortoise.fill", iconColor: .ollieMuted)
                    ]
                ],
                tint: .info
            ) {
                HStack {
                    Label("15 outside", systemImage: "leaf.fill")
                        .foregroundStyle(Color.ollieSuccess)
                        .font(.subheadline)

                    Spacer()

                    Label("2 inside", systemImage: "house.fill")
                        .foregroundStyle(Color.ollieDanger)
                        .font(.subheadline)

                    Spacer()

                    Text("88%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.ollieSuccess)
                }
            }

            // Simple grid without footer
            StatsCardView(
                rows: [
                    [
                        StatItemData(value: "8", label: "Times Peed", iconName: "drop.fill", iconColor: .ollieInfo),
                        StatItemData(value: "3", label: "Meals", iconName: "fork.knife", iconColor: .ollieAccent),
                        StatItemData(value: "2", label: "Poops", iconName: "circle.inset.filled", iconColor: .ollieAccent)
                    ]
                ],
                tint: .success
            )
        }
        .padding()
    }
}
