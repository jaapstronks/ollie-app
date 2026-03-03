//
//  StaleLoggingBanner.swift
//  Otis-app
//
//  Banner shown when user hasn't logged events for a while
//  Offers a simple "Start fresh" action to resume logging
//

import SwiftUI

/// Banner displayed when logging has gone stale (no events for 4+ hours during daytime)
struct StaleLoggingBanner: View {
    let onStartFresh: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "clock.badge.questionmark")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.StaleLogging.bannerTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.StaleLogging.bannerSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Start fresh button
            Button {
                onStartFresh()
            } label: {
                Text(Strings.StaleLogging.startFresh)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(bannerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.StaleLogging.bannerAccessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var bannerBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color(.secondarySystemBackground))
        }
        return AnyShapeStyle(Color(.secondarySystemBackground))
    }
}

#Preview("Stale Logging Banner") {
    VStack {
        StaleLoggingBanner(onStartFresh: {})
            .padding()
    }
}
