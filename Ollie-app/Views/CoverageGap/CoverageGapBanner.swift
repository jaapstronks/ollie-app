//
//  CoverageGapBanner.swift
//  Ollie-app
//
//  Banner shown when there's an active coverage gap (tracking paused)
//

import SwiftUI
import OllieShared

/// Banner displayed when tracking is paused during a coverage gap
struct CoverageGapBanner: View {
    let gap: PuppyEvent
    let onEnd: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: gap.gapType?.icon ?? "person.badge.clock.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(gap.gapType?.label ?? Strings.CoverageGap.eventLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Text(Strings.CoverageGap.trackingPaused)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Strings.CoverageGap.since(time: gap.time.timeString))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // End button
            Button {
                HapticFeedback.selection()
                onEnd()
            } label: {
                Text(Strings.CoverageGap.endGap)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            .accessibilityHint(Strings.CoverageGap.endGapAccessibilityHint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bannerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private var bannerBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color.orange.opacity(0.15))
        }
        return AnyShapeStyle(Color.orange.opacity(0.08))
    }
}

#Preview("Coverage Gap Banner") {
    VStack {
        CoverageGapBanner(
            gap: PuppyEvent.coverageGap(
                startTime: Date().addingTimeInterval(-3600),
                gapType: .daycare,
                location: "Happy Paws"
            ),
            onEnd: {}
        )

        CoverageGapBanner(
            gap: PuppyEvent.coverageGap(
                startTime: Date().addingTimeInterval(-7200),
                gapType: .family
            ),
            onEnd: {}
        )
    }
}
