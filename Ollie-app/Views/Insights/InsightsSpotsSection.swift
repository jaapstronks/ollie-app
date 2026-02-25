//
//  InsightsSpotsSection.swift
//  Ollie-app
//
//  Spots section with map and favorites
//

import SwiftUI
import OllieShared
import MapKit

/// Spots section showing map and favorite locations
struct InsightsSpotsSection: View {
    @ObservedObject var spotStore: SpotStore
    @Binding var showAllSpots: Bool

    var body: some View {
        if !spotStore.spots.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    InsightsSectionHeader(
                        title: Strings.Stats.spots,
                        icon: "map.fill",
                        tint: .ollieSuccess
                    )

                    Spacer()

                    // See all link
                    Button {
                        showAllSpots = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(Strings.Common.seeAll)
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.ollieAccent)
                    }
                }

                VStack(spacing: 12) {
                    // Mini map preview
                    AllSpotsPreviewMap(spots: spotStore.spots)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onTapGesture {
                            showAllSpots = true
                        }

                    // Favorite spots (top 3)
                    let favorites = spotStore.favoriteSpots.prefix(3)
                    if !favorites.isEmpty {
                        Divider()

                        ForEach(Array(favorites)) { spot in
                            NavigationLink {
                                SpotDetailView(spotStore: spotStore, spot: spot)
                            } label: {
                                InsightsSpotRow(spot: spot)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .glassCard(tint: .success)
            }
        }
    }
}

// MARK: - Spot Row

struct InsightsSpotRow: View {
    let spot: WalkSpot

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: spot.isFavorite ? "star.fill" : "mappin.circle.fill")
                .font(.body)
                .foregroundStyle(spot.isFavorite ? .yellow : Color.ollieAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if spot.visitCount > 0 {
                    Text(Strings.WalkLocations.visitCount(spot.visitCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
