//
//  PlacesTabView.swift
//  Ollie-app
//
//  Places tab combining spots (map) and moments (photos) with a view toggle
//

import SwiftUI
import OllieShared
import MapKit

/// View mode for the Places tab
enum PlacesViewMode: String, CaseIterable {
    case map
    case timeline

    var label: String {
        switch self {
        case .map: return Strings.Places.mapView
        case .timeline: return Strings.Places.timelineView
        }
    }

    var icon: String {
        switch self {
        case .map: return "map"
        case .timeline: return "calendar"
        }
    }
}

/// Places tab - map view of spots and photos, with timeline toggle
struct PlacesTabView: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var momentsViewModel: MomentsViewModel
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var locationManager: LocationManager
    var onSettingsTap: (() -> Void)?

    @State private var viewMode: PlacesViewMode = .map
    @State private var showingAddSpot = false
    @State private var showingAllSpotsMap = false
    @State private var selectedSpot: WalkSpot?
    @State private var selectedPhotoEvent: PuppyEvent?
    @State private var selectedCluster: PhotoCluster?

    var body: some View {
        NavigationStack {
            Group {
                switch viewMode {
                case .map:
                    PlacesMapModeView(
                        spotStore: spotStore,
                        momentsViewModel: momentsViewModel,
                        onShowAllSpots: { showingAllSpotsMap = true },
                        onSelectSpot: { spot in selectedSpot = spot },
                        onSelectPhoto: { event in selectedPhotoEvent = event },
                        onSelectCluster: { cluster in
                            // For single photo clusters, show the photo directly
                            // For multi-photo clusters, show cluster preview
                            if cluster.isSinglePhoto, let event = cluster.firstEvent {
                                selectedPhotoEvent = event
                            } else {
                                selectedCluster = cluster
                            }
                        }
                    )
                case .timeline:
                    PlacesTimelineView(
                        momentsViewModel: momentsViewModel,
                        viewModel: viewModel,
                        onSelectPhoto: { event in selectedPhotoEvent = event }
                    )
                }
            }
            .navigationTitle(Strings.Places.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // View mode toggle
                    Picker("View", selection: $viewMode) {
                        ForEach(PlacesViewMode.allCases, id: \.self) { mode in
                            Label(mode.label, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddSpot = true
                        } label: {
                            Label(Strings.Places.addSpot, systemImage: "mappin.and.ellipse")
                        }

                        // TODO: Add moment button - will open camera
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Strings.Places.addSpot)
                }
            }
            .sheet(isPresented: $showingAddSpot) {
                AddSpotSheet(spotStore: spotStore, locationManager: locationManager)
            }
            .sheet(isPresented: $showingAllSpotsMap) {
                AllSpotsMapView(spots: spotStore.spots)
            }
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(
                    spotStore: spotStore,
                    spot: spot,
                    momentsViewModel: momentsViewModel
                )
            }
            .sheet(item: $selectedCluster) { cluster in
                PhotoClusterPreviewSheet(
                    cluster: cluster,
                    onSelectPhoto: { event in
                        selectedCluster = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedPhotoEvent = event
                        }
                    }
                )
                .presentationDetents([.medium])
            }
            .fullScreenCover(item: $selectedPhotoEvent) { event in
                MediaPreviewView(
                    event: event,
                    onDelete: {
                        momentsViewModel.deleteEvent(event)
                        selectedPhotoEvent = nil
                    }
                )
            }
        }
        .onAppear {
            momentsViewModel.loadEventsWithMedia()
        }
    }
}

// MARK: - Map Mode View

/// Map view showing spots and recent moments
struct PlacesMapModeView: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var momentsViewModel: MomentsViewModel
    let onShowAllSpots: () -> Void
    let onSelectSpot: (WalkSpot) -> Void
    let onSelectPhoto: (PuppyEvent) -> Void
    let onSelectCluster: (PhotoCluster) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map section
                mapSection

                // Favorite spots section
                if !spotStore.favoriteSpots.isEmpty {
                    favoriteSpotsSection
                }

                // Recent moments section
                if !momentsViewModel.events.isEmpty {
                    recentMomentsSection
                }

                // All spots section (if any non-favorites)
                if !spotStore.spots.isEmpty {
                    allSpotsSection
                }

                // Empty state when no content
                if spotStore.spots.isEmpty && momentsViewModel.events.isEmpty {
                    emptyStateView
                }
            }
            .padding()
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(
                    title: Strings.WalksTab.yourSpots,
                    icon: "map.fill",
                    tint: .ollieSuccess
                )

                Spacer()

                if !spotStore.spots.isEmpty {
                    Button {
                        onShowAllSpots()
                    } label: {
                        Text(Strings.Places.expandMap)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.ollieAccent)
                    }
                }
            }

            // Map with spots and clustered photo markers
            PlacesMapPreview(
                spots: spotStore.spots,
                photoClusters: momentsViewModel.clusterPhotos(),
                onTapSpot: onSelectSpot,
                onTapCluster: onSelectCluster
            )
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Favorite Spots Section

    private var favoriteSpotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.Places.favoriteSpots,
                icon: "star.fill",
                tint: .yellow
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(spotStore.favoriteSpots.prefix(5)) { spot in
                        SpotCard(spot: spot)
                            .onTapGesture {
                                onSelectSpot(spot)
                            }
                    }
                }
            }
        }
    }

    // MARK: - Recent Moments Section

    private var recentMomentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(
                    title: Strings.Places.recentMoments,
                    icon: "photo.fill",
                    tint: .ollieAccent
                )

                Spacer()

                // TODO: Navigate to full gallery
            }

            // 3x2 grid of recent photos
            let columns = [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ]

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(momentsViewModel.events.prefix(6)) { event in
                    GalleryThumbnail(event: event)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            onSelectPhoto(event)
                        }
                }
            }
        }
    }

    // MARK: - All Spots Section

    private var allSpotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.Places.allSpots,
                icon: "mappin.circle.fill",
                tint: .secondary
            )

            VStack(spacing: 8) {
                // Show favorites first, then recents
                let orderedSpots = spotStore.favoriteSpots + spotStore.recentSpots
                let uniqueSpots = orderedSpots.reduce(into: [WalkSpot]()) { result, spot in
                    if !result.contains(where: { $0.id == spot.id }) {
                        result.append(spot)
                    }
                }

                ForEach(uniqueSpots.prefix(5)) { spot in
                    SpotRowCompact(spot: spot, isSelected: false)
                        .onTapGesture {
                            onSelectSpot(spot)
                        }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            Image(systemName: "map")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(Strings.Places.noSpotsYet)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(Strings.Places.noSpotsHint)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
                .frame(height: 40)
        }
        .padding()
    }
}

// MARK: - Preview
// Map components (PlacesMapPreview, SpotMapMarker, PhotoClusterMapMarker, SpotCard, PhotoClusterPreviewSheet)
// are in PlacesMapComponents.swift

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let momentsViewModel = MomentsViewModel(eventStore: eventStore)

    return PlacesTabView(
        spotStore: SpotStore(),
        momentsViewModel: momentsViewModel,
        viewModel: viewModel,
        locationManager: LocationManager()
    )
}
