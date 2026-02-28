//
//  OlliesWorldSummaryCard.swift
//  Ollie-app
//
//  Summary card showing spots discovered
//

import SwiftUI
import OllieShared

/// Compact summary card showing exploration stats
struct OlliesWorldSummaryCard: View {
    let spotsCount: Int
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

            // Single stat: spots discovered
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.ollieAccent)
                Text(Strings.Places.placesDiscovered(spotsCount))
                    .font(.subheadline)
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
}

// MARK: - Preview

#Preview {
    VStack {
        OlliesWorldSummaryCard(
            spotsCount: 12,
            puppyName: "Ollie"
        )
        .padding()

        OlliesWorldSummaryCard(
            spotsCount: 0,
            puppyName: "Max"
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
