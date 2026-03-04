//
//  FirstWeekCard.swift
//  Otis-app
//
//  Daily summary card for the first week with a new puppy.
//  Shows contextual guidance and progress on potty/crate training.
//  Dismissable for the day but referenceable (can be expanded again).
//

import SwiftUI

/// First week summary card with collapsible content
struct FirstWeekCard: View {
    let stats: FirstWeekStats
    let isCollapsed: Bool
    let onToggle: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            headerSection

            // Content (collapsible)
            if !isCollapsed {
                contentSection
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onToggle()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.FirstWeek.accessibilityLabel(day: stats.daysHome, name: stats.puppyName))
        .accessibilityHint(isCollapsed ? Strings.FirstWeek.expandHint : Strings.FirstWeek.collapseHint)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // Day badge
            Text(Strings.FirstWeek.cardTitle(day: stats.daysHome, name: stats.puppyName))
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Collapse/expand chevron
            Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main message
            Text(stats.mainMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Stats lines (if any)
            if stats.pottyLine != nil || stats.crateLine != nil {
                VStack(alignment: .leading, spacing: 6) {
                    if let pottyLine = stats.pottyLine {
                        statLine(text: pottyLine, icon: "leaf.fill", color: .green)
                    }
                    if let crateLine = stats.crateLine {
                        statLine(text: crateLine, icon: "house.fill", color: .orange)
                    }
                }
            }

            // Encouragement
            Text(stats.encouragementLine)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private func statLine(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Background

    private var cardBackground: some ShapeStyle {
        // Subtle warm background to feel encouraging
        AnyShapeStyle(Color.accentColor.opacity(colorScheme == .dark ? 0.15 : 0.08))
    }
}

// MARK: - Preview

#Preview("Day 1 - Expanded") {
    let stats = FirstWeekStats(
        daysHome: 1,
        puppyName: "Luna",
        outdoorPottyCount: 0,
        totalPottyCount: 0,
        crateNapCount: 0,
        totalQualifyingNaps: 0,
        napsWithLocationSpecified: 0,
        hasEverSpecifiedNapLocation: false,
        daysWithNapsLogged: 0
    )

    FirstWeekCard(stats: stats, isCollapsed: false) {
        print("Toggle")
    }
    .padding()
}

#Preview("Day 3 - With Stats") {
    let stats = FirstWeekStats(
        daysHome: 3,
        puppyName: "Max",
        outdoorPottyCount: 4,
        totalPottyCount: 6,
        crateNapCount: 2,
        totalQualifyingNaps: 4,
        napsWithLocationSpecified: 3,
        hasEverSpecifiedNapLocation: true,
        daysWithNapsLogged: 2
    )

    FirstWeekCard(stats: stats, isCollapsed: false) {
        print("Toggle")
    }
    .padding()
}

#Preview("Day 5 - Collapsed") {
    let stats = FirstWeekStats(
        daysHome: 5,
        puppyName: "Bella",
        outdoorPottyCount: 8,
        totalPottyCount: 10,
        crateNapCount: 5,
        totalQualifyingNaps: 5,
        napsWithLocationSpecified: 5,
        hasEverSpecifiedNapLocation: true,
        daysWithNapsLogged: 4
    )

    FirstWeekCard(stats: stats, isCollapsed: true) {
        print("Toggle")
    }
    .padding()
}
