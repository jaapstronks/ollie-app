//
//  WalksTabView.swift
//  Ollie-app
//
//  Walks tab showing walk weather, today's walks, map, and favorite spots

import SwiftUI
import MapKit

/// Walks tab - map, weather, spots, and today's walks
struct WalksTabView: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var viewModel: TimelineViewModel

    @State private var showingAllSpots = false
    @State private var showingAddSpot = false

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var todaysWalks: [PuppyEvent] {
        viewModel.events.filter { $0.type == .uitlaten }
    }

    private var totalWalkMinutes: Int {
        todaysWalks.compactMap { $0.durationMin }.reduce(0, +)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weather section for walks
                    weatherSection

                    // Today's walks section
                    todaysWalksSection

                    // Map section
                    mapSection

                    // Favorite spots section
                    favoriteSpotsSection

                    // Recent spots section
                    recentSpotsSection
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.WalksTab.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.quickLog(type: .uitlaten)
                        } label: {
                            Label(Strings.FAB.walk, systemImage: "figure.walk")
                        }

                        Button {
                            showingAddSpot = true
                        } label: {
                            Label(Strings.WalkLocations.addSpot, systemImage: "mappin.and.ellipse")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAllSpots) {
                AllSpotsMapView(spots: spotStore.spots)
            }
            .sheet(isPresented: $showingAddSpot) {
                AddSpotSheet(spotStore: spotStore, locationManager: locationManager)
            }
        }
    }

    // MARK: - Weather Section

    @ViewBuilder
    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: Strings.WalksTab.walkWeather,
                icon: "cloud.sun.fill",
                tint: .ollieInfo
            )

            WeatherSection(
                forecasts: weatherService.upcomingForecasts(hours: 6),
                alert: weatherService.smartAlert(predictedPottyTime: nil),
                isLoading: weatherService.isLoading
            )
            .padding()
            .glassCard(tint: .info)
        }
    }

    // MARK: - Today's Walks Section

    @ViewBuilder
    private var todaysWalksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: Strings.WalksTab.todaysWalks,
                icon: "figure.walk",
                tint: .ollieAccent
            )

            if todaysWalks.isEmpty {
                // Empty state with call to action
                VStack(spacing: 16) {
                    Image(systemName: "figure.walk")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text(Strings.WalksTab.noWalksToday)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        viewModel.quickLog(type: .uitlaten)
                    } label: {
                        Label(Strings.WalksTab.startWalk, systemImage: "plus")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ollieAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassCard(tint: .accent)
            } else {
                // Walk summary card
                VStack(spacing: 12) {
                    HStack {
                        // Walk count
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.WalksTab.walksCount(todaysWalks.count))
                                .font(.headline)
                            if totalWalkMinutes > 0 {
                                Text(Strings.WalksTab.totalDuration(totalWalkMinutes))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Walk icon
                        Image(systemName: "figure.walk")
                            .font(.title)
                            .foregroundStyle(Color.ollieAccent)
                    }

                    // List of walks
                    Divider()

                    ForEach(todaysWalks) { walk in
                        walkRow(walk)
                    }
                }
                .padding()
                .glassCard(tint: .accent)
            }
        }
    }

    @ViewBuilder
    private func walkRow(_ walk: PuppyEvent) -> some View {
        HStack(spacing: 12) {
            // Time
            Text(walk.time, format: .dateTime.hour().minute())
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(width: 50, alignment: .leading)

            // Duration (if available)
            if let duration = walk.durationMin {
                Text("\(duration) \(Strings.Common.minutes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Spot name (if available)
            if let spotName = walk.spotName {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                    Text(spotName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Note indicator
            if let note = walk.note, !note.isEmpty {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Map Section

    @ViewBuilder
    private var mapSection: some View {
        if !spotStore.spots.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionHeader(
                        title: Strings.WalksTab.yourSpots,
                        icon: "map.fill",
                        tint: .ollieSuccess
                    )

                    Spacer()

                    // View all button
                    Button {
                        showingAllSpots = true
                    } label: {
                        Text(Strings.WalksTab.allSpots)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.ollieAccent)
                    }
                }

                // Map preview
                AllSpotsPreviewMap(spots: spotStore.spots)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture {
                        showingAllSpots = true
                    }
            }
        }
    }

    // MARK: - Favorite Spots Section

    @ViewBuilder
    private var favoriteSpotsSection: some View {
        let favorites = spotStore.favoriteSpots
        if !favorites.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(
                    title: Strings.WalkLocations.favorites,
                    icon: "star.fill",
                    tint: .yellow
                )

                VStack(spacing: 0) {
                    ForEach(Array(favorites.prefix(3))) { spot in
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
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)

                        if spot.id != favorites.prefix(3).last?.id {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .glassCard(tint: .accent)
            }
        }
    }

    // MARK: - Recent Spots Section

    @ViewBuilder
    private var recentSpotsSection: some View {
        let recent = spotStore.spots.filter { !$0.isFavorite }.sorted { $0.visitCount > $1.visitCount }
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(
                    title: Strings.WalkLocations.recent,
                    icon: "clock.fill",
                    tint: .secondary
                )

                VStack(spacing: 0) {
                    ForEach(Array(recent.prefix(3))) { spot in
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
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)

                        if spot.id != recent.prefix(3).last?.id {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .glassCard(tint: .none)
            }
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - All Spots Preview Map (non-interactive mini version)

struct AllSpotsPreviewMap: View {
    let spots: [WalkSpot]

    @State private var region: MKCoordinateRegion

    init(spots: [WalkSpot]) {
        self.spots = spots

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

            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
            ))
        } else {
            // Default to Rotterdam
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.9225, longitude: 4.4792),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: annotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                Image(systemName: item.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(item.isFavorite ? .yellow : .ollieAccent)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 16, height: 16)
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private var annotations: [SpotAnnotation] {
        spots.map { spot in
            SpotAnnotation(
                id: spot.id,
                name: spot.name,
                coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
                isFavorite: spot.isFavorite
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return WalksTabView(
        spotStore: SpotStore(),
        weatherService: WeatherService(),
        locationManager: LocationManager(),
        viewModel: viewModel
    )
}
