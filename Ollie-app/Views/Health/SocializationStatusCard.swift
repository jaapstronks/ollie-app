//
//  SocializationStatusCard.swift
//  Otis-app
//
//  Compact card showing socialization window status for the Health tab
//  Taps to open SocializationWindowSheet
//

import SwiftUI
import OtisShared

/// Compact card showing socialization window status
struct SocializationStatusCard: View {
    let ageInWeeks: Int
    let totalExposures: Int
    let totalComfortable: Int

    @Environment(\.colorScheme) private var colorScheme

    private var windowStatus: SocializationWindowStatus {
        SocializationWindowStatus(ageInWeeks: ageInWeeks)
    }

    private var weeksRemaining: Int? {
        SocializationWindowStatus.weeksRemaining(ageInWeeks: ageInWeeks)
    }

    private var windowProgress: Double {
        SocializationWindowStatus.progressPercentage(ageInWeeks: ageInWeeks)
    }

    private var progressPercent: Int {
        Int(windowProgress * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)
                Text(Strings.Socialization.socializationWindowTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if windowStatus.isOpen {
                // Window is open - show progress
                openWindowContent
            } else {
                // Window closed - show summary
                closedWindowContent
            }
        }
        .padding()
        .glassCard(tint: .custom(statusColor))
    }

    // MARK: - Open Window Content

    @ViewBuilder
    private var openWindowContent: some View {
        // Progress bar with percentage
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * windowProgress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(progressPercent)%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)

                Spacer()

                if let weeks = weeksRemaining {
                    Text(Strings.Socialization.weeksRemaining(weeks))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        // Stats row
        HStack(spacing: 16) {
            statItem(
                value: "\(totalExposures)",
                label: Strings.Socialization.exposureCount(totalExposures)
            )

            Divider()
                .frame(height: 24)

            statItem(
                value: "\(totalComfortable)",
                label: Strings.Socialization.comfortable
            )
        }

        // Tap hint
        Text(Strings.Common.tapToExpand)
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    // MARK: - Closed Window Content

    @ViewBuilder
    private var closedWindowContent: some View {
        HStack(spacing: 12) {
            // Status badge
            VStack(alignment: .leading, spacing: 4) {
                Text(windowStatus.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(Strings.Socialization.exposureCount(totalExposures))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Comfortable count badge
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(totalComfortable)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
                Text(Strings.Socialization.comfortable)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }

        // Encouragement
        Text(Strings.Socialization.socializationDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statItem(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var statusColor: Color {
        switch windowStatus {
        case .peak: return .otisSuccess
        case .closing: return .otisWarning
        case .justClosed: return .orange
        case .closed: return .secondary
        }
    }
}

// MARK: - Preview

#Preview("Window Open - Peak") {
    SocializationStatusCard(
        ageInWeeks: 10,
        totalExposures: 64,
        totalComfortable: 28
    )
    .padding()
}

#Preview("Window Closing") {
    SocializationStatusCard(
        ageInWeeks: 14,
        totalExposures: 87,
        totalComfortable: 45
    )
    .padding()
}

#Preview("Window Closed") {
    SocializationStatusCard(
        ageInWeeks: 20,
        totalExposures: 112,
        totalComfortable: 58
    )
    .padding()
}
