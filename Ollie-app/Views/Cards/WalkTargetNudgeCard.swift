//
//  WalkTargetNudgeCard.swift
//  Otis-app
//
//  Contextual nudge card for walk schedule review on Today view
//  Shows when: 7+ days of data AND 30%+ below configured walk target
//

import SwiftUI
import OtisShared

/// Contextual nudge to encourage walk schedule adjustment
struct WalkTargetNudgeCard: View {
    let actualAverage: Double
    let scheduledTarget: Int
    let onAdjust: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Formatted average walks per day (e.g., "5.2")
    private var formattedAverage: String {
        if actualAverage == actualAverage.rounded() {
            return String(format: "%.0f", actualAverage)
        } else {
            return String(format: "%.1f", actualAverage)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "figure.walk")
                        .font(.body)
                        .foregroundStyle(.orange)
                }
                .accessibilityHidden(true)

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.WalkNudge.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.WalkNudge.subtitle(actual: formattedAverage, target: scheduledTarget))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                // Dismiss button (keep target)
                Button {
                    onDismiss()
                } label: {
                    Text(Strings.WalkNudge.keepTarget)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.secondarySystemFill))
                        )
                }

                // Adjust schedule button
                Button {
                    onAdjust()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                        Text(Strings.WalkNudge.adjustSchedule)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.orange)
                    )
                }
            }
        }
        .padding(14)
        .glassStatusCard(tintColor: .orange.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.WalkNudge.title)
        .accessibilityHint(Strings.WalkNudge.subtitle(actual: formattedAverage, target: scheduledTarget))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        WalkTargetNudgeCard(
            actualAverage: 5.2,
            scheduledTarget: 8,
            onAdjust: { print("Adjust schedule") },
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
}
