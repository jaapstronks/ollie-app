//
//  OlliesWorldSummaryCard.swift
//  Ollie-app
//
//  Summary card showing exploration stats: places discovered, walks logged, distance explored
//

import SwiftUI
import OllieShared

/// Compact summary card showing exploration stats
struct OlliesWorldSummaryCard: View {
    let placesCount: Int
    let walksCount: Int
    let estimatedKm: Double
    let puppyName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.title3)
                    .foregroundStyle(Color.ollieAccent)
                Text(worldTitle)
                    .font(.headline)

                Spacer()
            }

            // Stats row
            HStack(spacing: 0) {
                // Places discovered
                statItem(
                    value: "\(placesCount)",
                    icon: "mappin.circle.fill",
                    color: .ollieAccent
                )

                Divider()
                    .frame(height: 32)

                // Walks logged
                statItem(
                    value: "\(walksCount)",
                    icon: "figure.walk",
                    color: .ollieSuccess
                )

                Divider()
                    .frame(height: 32)

                // Distance explored
                statItem(
                    value: String(format: "%.1f km", estimatedKm),
                    icon: "point.topleft.down.to.point.bottomright.curvepath.fill",
                    color: .ollieInfo
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // World title using puppy name
    private var worldTitle: String {
        // Using localized string with puppy name
        String(localized: "\(puppyName)'s World", table: "Places")
    }

    private func statItem(value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        OlliesWorldSummaryCard(
            placesCount: 12,
            walksCount: 47,
            estimatedKm: 23.5,
            puppyName: "Ollie"
        )
        .padding()

        OlliesWorldSummaryCard(
            placesCount: 0,
            walksCount: 0,
            estimatedKm: 0,
            puppyName: "Max"
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
