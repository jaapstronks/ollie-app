//
//  TimelineSummaryRow.swift
//  Ollie-app
//
//  Summary stats row for the visual timeline (sleep, walks, potty, meals)

import SwiftUI
import OllieShared

/// Summary stats row showing daily totals
struct TimelineSummaryRow: View {
    let summary: ActivityBlockSummary
    let onStatTap: ((StatType) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    enum StatType {
        case sleep
        case walks
        case potty
        case meals
    }

    init(summary: ActivityBlockSummary, onStatTap: ((StatType) -> Void)? = nil) {
        self.summary = summary
        self.onStatTap = onStatTap
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sleep stat
            statItem(
                icon: "moon.zzz.fill",
                value: summary.sleepString,
                color: .ollieSleep,
                type: .sleep
            )

            Divider()
                .frame(height: 24)

            // Walk stat
            statItem(
                icon: "figure.walk",
                value: walkValue,
                color: .ollieSuccess,
                type: .walks
            )

            Divider()
                .frame(height: 24)

            // Potty stat
            statItem(
                icon: "checkmark.circle.fill",
                value: pottyValue,
                color: pottyColor,
                type: .potty
            )

            Divider()
                .frame(height: 24)

            // Meals stat
            statItem(
                icon: "fork.knife",
                value: "\(summary.mealCount)",
                color: .ollieAccent,
                type: .meals
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Stat Item

    private func statItem(icon: String, value: String, color: Color, type: StatType) -> some View {
        Button {
            onStatTap?(type)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onStatTap == nil)
    }

    // MARK: - Computed Values

    private var walkValue: String {
        if summary.walkCount == 0 {
            return "0"
        }
        return "\(summary.walkCount)"
    }

    private var pottyValue: String {
        if summary.totalPottyCount == 0 {
            return "0"
        }
        // Show outdoor/indoor split
        if summary.indoorPottyCount > 0 {
            return "\(summary.outdoorPottyCount)/\(summary.indoorPottyCount)"
        }
        return "\(summary.outdoorPottyCount)"
    }

    private var pottyColor: Color {
        if summary.indoorPottyCount > 0 {
            return .ollieWarning
        }
        return .ollieSuccess
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.ollieCardDark : Color.ollieCardLight
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.ollieBorderDark : Color.ollieBorderLight
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        TimelineSummaryRow(
            summary: ActivityBlockSummary(
                totalSleepMinutes: 750,
                walkCount: 3,
                totalWalkMinutes: 90,
                outdoorPottyCount: 5,
                indoorPottyCount: 0,
                mealCount: 3
            )
        )

        TimelineSummaryRow(
            summary: ActivityBlockSummary(
                totalSleepMinutes: 420,
                walkCount: 2,
                totalWalkMinutes: 60,
                outdoorPottyCount: 4,
                indoorPottyCount: 1,
                mealCount: 2
            )
        )

        TimelineSummaryRow(
            summary: ActivityBlockSummary()
        )
    }
    .padding()
}
