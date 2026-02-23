//
//  FavoriteSpotsView.swift
//  Ollie-app
//
//  Settings screen for managing favorite walk spots

import SwiftUI
import MapKit

/// Full-screen view for managing favorite walk spots
struct FavoriteSpotsView: View {
    @ObservedObject var spotStore: SpotStore
    @State private var showingMap = false

    var body: some View {
        List {
            // Map section (if spots exist)
            if !spotStore.spots.isEmpty {
                Section {
                    Button {
                        showingMap = true
                    } label: {
                        Label(Strings.WalkLocations.showOnMap, systemImage: "map")
                    }
                }
            }

            // Favorites section
            if !spotStore.favoriteSpots.isEmpty {
                Section(Strings.WalkLocations.favorites) {
                    ForEach(spotStore.favoriteSpots) { spot in
                        NavigationLink {
                            SpotDetailView(spotStore: spotStore, spot: spot)
                        } label: {
                            SpotRowView(
                                spot: spot,
                                onFavoriteToggle: {
                                    spotStore.toggleFavorite(spot)
                                }
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                spotStore.deleteSpot(spot)
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                openInMaps(spot)
                            } label: {
                                Label(Strings.WalkLocations.openInMaps, systemImage: "map")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }

            // Other spots section
            let otherSpots = spotStore.spots.filter { !$0.isFavorite }
            if !otherSpots.isEmpty {
                Section(Strings.WalkLocations.recent) {
                    ForEach(otherSpots.sorted { $0.visitCount > $1.visitCount }) { spot in
                        NavigationLink {
                            SpotDetailView(spotStore: spotStore, spot: spot)
                        } label: {
                            SpotRowView(
                                spot: spot,
                                onFavoriteToggle: {
                                    spotStore.toggleFavorite(spot)
                                }
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                spotStore.deleteSpot(spot)
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                openInMaps(spot)
                            } label: {
                                Label(Strings.WalkLocations.openInMaps, systemImage: "map")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }

            // Empty state
            if spotStore.spots.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text(Strings.WalkLocations.noRecentSpots)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle(Strings.WalkLocations.favoriteSpots)
        .sheet(isPresented: $showingMap) {
            AllSpotsMapView(spots: spotStore.spots)
        }
    }

    private func openInMaps(_ spot: WalkSpot) {
        let coordinate = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = spot.name
        mapItem.openInMaps()
    }
}

/// Full-screen map showing all spots
struct AllSpotsMapView: View {
    let spots: [WalkSpot]
    @Environment(\.dismiss) private var dismiss

    private var initialPosition: MapCameraPosition {
        // Calculate region to fit all spots
        if let first = spots.first {
            var minLat = first.latitude
            var maxLat = first.latitude
            var minLon = first.longitude
            var maxLon = first.longitude

            for spot in spots {
                minLat = min(minLat, spot.latitude)
                maxLat = max(maxLat, spot.latitude)
                minLon = min(minLon, spot.longitude)
                maxLon = max(maxLon, spot.longitude)
            }

            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            let spanLat = max(0.01, (maxLat - minLat) * 1.5)
            let spanLon = max(0.01, (maxLon - minLon) * 1.5)

            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
            ))
        } else {
            // Default to Rotterdam
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.9225, longitude: 4.4792),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    var body: some View {
        NavigationStack {
            Map(initialPosition: initialPosition) {
                ForEach(spots) { spot in
                    Annotation(spot.name, coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)) {
                        VStack(spacing: 2) {
                            Image(systemName: spot.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(spot.isFavorite ? .yellow : .ollieAccent)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                )

                            Text(spot.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .navigationTitle(Strings.WalkLocations.favoriteSpots)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SpotAnnotation: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let isFavorite: Bool
}

#Preview {
    NavigationStack {
        FavoriteSpotsView(spotStore: SpotStore())
    }
}
