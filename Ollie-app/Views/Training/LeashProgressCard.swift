//
//  LeashProgressCard.swift
//  Ollie-app
//
//  Card for Train tab showing leash training progress

import SwiftUI

/// Compact entry card for leash training in the Train tab
struct LeashProgressCard: View {
    let recentAverage: Double?
    let trend: SentimentTrend?
    let isMastered: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Display string for the current status
    private var statusText: String {
        if isMastered {
            return Strings.Leash.masteredDescription
        }
        if let avg = recentAverage {
            return Strings.Leash.averageRating(avg)
        }
        return Strings.Leash.guideSubtitle
    }

    /// Stat value to display (nil if mastered or no data)
    private var statValue: String? {
        guard !isMastered, let avg = recentAverage else { return nil }
        return String(format: "%.1f", avg)
    }

    /// Color for the stat based on rating
    private var tintColor: Color {
        guard let avg = recentAverage else { return .otisAccent }
        switch avg {
        case 4.5...: return .otisSuccess
        case 3.5...: return .otisAccent
        case 2.5...: return .otisWarning
        default: return .otisDanger
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with checkmark overlay when mastered
                ZStack {
                    Image(systemName: "link")
                        .font(.title2)
                        .foregroundStyle(isMastered ? .secondary : tintColor)
                        .frame(width: 32)

                    if isMastered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.green)
                            .background(Circle().fill(colorScheme == .dark ? Color.black : Color.white).padding(1))
                            .offset(x: 10, y: 10)
                    }
                }
                .accessibilityHidden(true)

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(Strings.Leash.guideTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(isMastered ? .secondary : .primary)

                        // Trend indicator
                        if !isMastered, let trend = trend {
                            Image(systemName: trend.icon)
                                .font(.caption2)
                                .foregroundStyle(trendColor(trend))
                        }
                    }

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Mastered badge or stat badge
                if isMastered {
                    Text(Strings.Leash.mastered)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        )
                } else if let statValue = statValue {
                    Text(statValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(tintColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(tintColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        )
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassStatusCard(tintColor: isMastered ? Color.green.opacity(0.1) : tintColor.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Strings.Leash.guideTitle), \(isMastered ? Strings.Leash.mastered : statusText)")
        .accessibilityHint(isMastered ? "" : (statValue.map { "Current: \($0)" } ?? ""))
        .accessibilityAddTraits(.isButton)
    }

    private func trendColor(_ trend: SentimentTrend) -> Color {
        switch trend {
        case .improving: return .otisSuccess
        case .stable: return .otisAccent
        case .declining: return .otisWarning
        }
    }
}

// MARK: - Preview

#Preview("Various States") {
    VStack(spacing: 12) {
        LeashProgressCard(
            recentAverage: 4.2,
            trend: .improving,
            isMastered: false,
            onTap: {}
        )

        LeashProgressCard(
            recentAverage: 3.5,
            trend: .stable,
            isMastered: false,
            onTap: {}
        )

        LeashProgressCard(
            recentAverage: 2.8,
            trend: .declining,
            isMastered: false,
            onTap: {}
        )

        LeashProgressCard(
            recentAverage: nil,
            trend: nil,
            isMastered: false,
            onTap: {}
        )

        LeashProgressCard(
            recentAverage: nil,
            trend: nil,
            isMastered: true,
            onTap: {}
        )
    }
    .padding()
}
