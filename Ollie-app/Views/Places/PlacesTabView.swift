//
//  PlacesTabView.swift
//  Ollie-app
//
//  Explore tab - map view of saved spots and photo moments
//

import SwiftUI
import OllieShared
import MapKit

/// Explore tab - map view of spots and photos
struct PlacesTabView: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var contactStore: ContactStore
    @ObservedObject var momentsViewModel: MomentsViewModel
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var locationManager: LocationManager
    var onSettingsTap: (() -> Void)?

    @EnvironmentObject var profileStore: ProfileStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingAddSpot = false
    @State private var showingExpandedMap = false
    @State private var selectedSpot: WalkSpot?
    @State private var selectedPhotoEvent: PuppyEvent?
    @State private var selectedCluster: PhotoCluster?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                PlacesMapModeView(
                    spotStore: spotStore,
                    momentsViewModel: momentsViewModel,
                    puppyName: profileStore.profile?.name ?? "Ollie",
                    onShowAllSpots: { showingExpandedMap = true },
                    onSelectSpot: { spot in selectedSpot = spot },
                    onSelectPhoto: { event in selectedPhotoEvent = event },
                    onSelectCluster: { cluster in
                        // Always show detail card (handles single and multi-photo)
                        selectedCluster = cluster
                    }
                )

                // Floating Add Button
                addSpotFAB
            }
            .navigationTitle(Strings.Places.title)
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(profile: profileStore.profile) {
                onSettingsTap?()
            }
            .sheet(isPresented: $showingAddSpot) {
                AddSpotSheet(spotStore: spotStore, locationManager: locationManager)
            }
            .fullScreenCover(isPresented: $showingExpandedMap) {
                ExpandedPlacesMapView(
                    spotStore: spotStore,
                    contactStore: contactStore,
                    momentsViewModel: momentsViewModel,
                    locationManager: locationManager
                )
            }
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(
                    spotStore: spotStore,
                    spot: spot,
                    momentsViewModel: momentsViewModel
                )
            }
            .sheet(item: $selectedCluster) { cluster in
                PhotoPinDetailCard(
                    cluster: cluster,
                    spots: spotStore.spots,
                    onSelectPhoto: { event in
                        selectedCluster = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedPhotoEvent = event
                        }
                    },
                    onSaveSpot: nil // Save spot handled separately
                )
                .presentationDetents([.medium, .large])
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

    // MARK: - Add Spot FAB

    private var addSpotFAB: some View {
        Button {
            showingAddSpot = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.ollieAccent)
                        .shadow(
                            color: Color.ollieAccent.opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
        }
        .padding(.trailing, 16)
        .padding(.bottom, 100) // Above tab bar
        .accessibilityLabel(Strings.Places.addSpot)
    }
}

// MARK: - Map Mode View

/// Map view showing spots and photo pins
struct PlacesMapModeView: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var momentsViewModel: MomentsViewModel
    var puppyName: String = "Ollie"
    let onShowAllSpots: () -> Void
    let onSelectSpot: (WalkSpot) -> Void
    let onSelectPhoto: (PuppyEvent) -> Void
    let onSelectCluster: (PhotoCluster) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary card (only show if there are spots)
                if spotStore.spots.count > 0 {
                    OlliesWorldSummaryCard(
                        spotsCount: spotStore.spots.count,
                        puppyName: puppyName
                    )
                }

                // Map section
                mapSection

                // Favorite spots section
                if !spotStore.favoriteSpots.isEmpty {
                    favoriteSpotsSection
                }

                // All spots section (if any non-favorites)
                if !spotStore.spots.isEmpty {
                    allSpotsSection
                }

                // Empty state when no content
                if spotStore.spots.isEmpty {
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
        contactStore: ContactStore(),
        momentsViewModel: momentsViewModel,
        viewModel: viewModel,
        locationManager: LocationManager()
    )
}
