//
//  PlacesTabView.swift
//  Ollie-app
//
//  Explore tab - full-screen map view of saved spots and photo moments
//

import SwiftUI
import OllieShared
import MapKit

/// Explore tab - full-screen map with spots, contacts, and photo pins
struct PlacesTabView: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var contactStore: ContactStore
    @ObservedObject var momentsViewModel: MomentsViewModel
    @ObservedObject var locationManager: LocationManager
    var onSettingsTap: (() -> Void)?
    var onAddMoment: (() -> Void)?

    @EnvironmentObject var profileStore: ProfileStore
    @StateObject private var mapViewModel: PlacesMapViewModel

    // View mode toggle (Map vs Gallery)
    @AppStorage("exploreViewMode") private var viewMode: ExploreViewMode = .map
    @AppStorage("momentsViewMode") private var momentsViewMode: MomentsViewMode = .gallery

    @State private var showingAddSpot = false
    @State private var showingAddContact = false
    @State private var selectedSpot: WalkSpot?
    @State private var selectedDiscoveredSpot: DiscoveredSpot?
    @State private var selectedContact: DogContact?
    @State private var selectedCluster: PhotoCluster?
    @State private var selectedPhotoEvent: PuppyEvent?
    @Namespace private var heroNamespace

    init(
        spotStore: SpotStore,
        contactStore: ContactStore,
        momentsViewModel: MomentsViewModel,
        locationManager: LocationManager,
        onSettingsTap: (() -> Void)? = nil,
        onAddMoment: (() -> Void)? = nil
    ) {
        self.spotStore = spotStore
        self.contactStore = contactStore
        self.momentsViewModel = momentsViewModel
        self.locationManager = locationManager
        self.onSettingsTap = onSettingsTap
        self.onAddMoment = onAddMoment
        self._mapViewModel = StateObject(wrappedValue: PlacesMapViewModel(
            spotStore: spotStore,
            contactStore: contactStore,
            momentsViewModel: momentsViewModel
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewMode {
                case .map:
                    mapContent
                case .gallery:
                    galleryContent
                }
            }
            .navigationTitle(Strings.Places.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // View mode toggle (leading)
                ToolbarItem(placement: .topBarLeading) {
                    ExploreViewModeToggle(mode: $viewMode)
                        .frame(width: 140)
                }
            }
            .profileToolbar(profile: profileStore.profile) {
                onSettingsTap?()
            }
            .sheet(isPresented: $showingAddSpot) {
                AddSpotSheet(spotStore: spotStore, locationManager: locationManager)
            }
            .sheet(isPresented: $showingAddContact) {
                AddEditContactSheet(contactStore: contactStore)
            }
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(
                    spotStore: spotStore,
                    spot: spot,
                    momentsViewModel: momentsViewModel
                )
            }
            .sheet(item: $selectedDiscoveredSpot) { spot in
                DiscoveredSpotDetailSheet(
                    spot: spot,
                    spotStore: spotStore
                )
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact, contactStore: contactStore)
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
                    onSaveSpot: nil
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
            mapViewModel.fitMapToMarkers()
        }
        .task {
            // Discover places near user's location or default location
            let coords = locationManager.currentCoordinates ?? (51.9225, 4.4792) // Rotterdam fallback
            await mapViewModel.discoverPlacesNearby(latitude: coords.0, longitude: coords.1)
        }
        .onChange(of: mapViewModel.selectedDiscoveryTypes) { _, _ in
            // Refresh discovery when selected types change
            Task {
                let coords = locationManager.currentCoordinates ?? (51.9225, 4.4792)
                await mapViewModel.refreshDiscovery(latitude: coords.0, longitude: coords.1)
            }
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        ZStack(alignment: .bottom) {
            // Full-screen map with filter bar
            ZStack(alignment: .top) {
                mapView
                    .ignoresSafeArea(edges: .bottom)

                // Filter bar overlay at top
                VStack(spacing: 0) {
                    PlacesFilterBar(
                        activeFilters: $mapViewModel.activeFilters,
                        selectedContactTypes: $mapViewModel.selectedContactTypes,
                        selectedSpotCategories: $mapViewModel.selectedSpotCategories,
                        selectedDiscoveryTypes: $mapViewModel.selectedDiscoveryTypes
                    )
                    Spacer()
                }
            }

            // Floating Add Button
            HStack {
                Spacer()
                addSpotFAB
            }
        }
    }

    // MARK: - Gallery Content

    private var galleryContent: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if momentsViewModel.isLoading {
                    // Skeleton loading grid
                    ScrollView {
                        LazyVGrid(columns: galleryColumns, spacing: 2) {
                            ForEach(0..<12, id: \.self) { index in
                                SkeletonRect(height: 120, cornerRadius: 0)
                                    .aspectRatio(1, contentMode: .fill)
                                    .animatedAppear(delay: StaggeredAnimation.delay(for: index))
                            }
                        }
                        .padding(.top)
                    }
                    .skeleton(isLoading: true)
                } else if momentsViewModel.events.isEmpty {
                    EmptyMomentsView(onAddMoment: onAddMoment)
                } else {
                    VStack(spacing: 0) {
                        // Gallery/Diary sub-toggle
                        MomentsViewModeToggle(mode: $momentsViewMode)
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                        switch momentsViewMode {
                        case .gallery:
                            galleryGridContent
                        case .diary:
                            diaryListContent
                        }
                    }
                }
            }
            .refreshable {
                momentsViewModel.loadEventsWithMedia()
            }

            // Add Moment FAB
            if let onAddMoment = onAddMoment {
                addMomentFAB(action: onAddMoment)
            }
        }
    }

    private let galleryColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    private var galleryGridContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(Array(momentsViewModel.eventsByMonth.enumerated()), id: \.element.month) { sectionIndex, section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.month)
                            .font(.headline)
                            .padding(.horizontal)
                            .animatedAppear(delay: StaggeredAnimation.delay(for: sectionIndex))

                        LazyVGrid(columns: galleryColumns, spacing: 2) {
                            ForEach(Array(section.events.enumerated()), id: \.element.id) { eventIndex, event in
                                GalleryThumbnail(event: event)
                                    .aspectRatio(1, contentMode: .fill)
                                    .zoomTransitionSource(id: event.id, in: heroNamespace)
                                    .onTapGesture {
                                        selectedPhotoEvent = event
                                    }
                                    .animatedAppear(delay: StaggeredAnimation.delay(for: eventIndex, baseDelay: 0.03, maxDelay: 0.2))
                                    .onAppear {
                                        momentsViewModel.loadMoreIfNeeded(currentEvent: event)
                                    }
                            }
                        }
                    }
                }

                if momentsViewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var diaryListContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(Array(momentsViewModel.eventsPerDay.enumerated()), id: \.element.id) { index, event in
                    DiaryCardView(event: event)
                        .zoomTransitionSource(id: event.id, in: heroNamespace)
                        .onTapGesture {
                            selectedPhotoEvent = event
                        }
                        .animatedAppear(delay: StaggeredAnimation.delay(for: index, baseDelay: 0.05, maxDelay: 0.3))
                        .onAppear {
                            momentsViewModel.loadMoreIfNeeded(currentEvent: event)
                        }
                }

                if momentsViewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $mapViewModel.cameraPosition) {
            // User location
            UserAnnotation()

            // Render all visible markers
            ForEach(mapViewModel.visibleMarkers) { marker in
                switch marker {
                case .spot(let spot):
                    Annotation("", coordinate: marker.coordinate) {
                        SpotMapMarker(spot: spot)
                            .onTapGesture {
                                selectedSpot = spot
                            }
                    }

                case .contact(let contact):
                    Annotation("", coordinate: marker.coordinate) {
                        ContactMapMarker(contact: contact)
                            .onTapGesture {
                                selectedContact = contact
                            }
                    }

                case .discoveredSpot(let spot):
                    Annotation("", coordinate: marker.coordinate) {
                        DiscoveredSpotMapMarker(spot: spot)
                            .onTapGesture {
                                selectedDiscoveredSpot = spot
                            }
                    }

                case .photoCluster(let cluster):
                    Annotation("", coordinate: marker.coordinate) {
                        PhotoClusterMapMarker(cluster: cluster)
                            .onTapGesture {
                                selectedCluster = cluster
                            }
                    }
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // MARK: - Add FAB with Menu

    private var addSpotFAB: some View {
        Menu {
            Button {
                showingAddSpot = true
            } label: {
                Label(Strings.Places.addSpot, systemImage: "mappin.circle.fill")
            }

            Button {
                showingAddContact = true
            } label: {
                Label(Strings.Places.addContact, systemImage: "person.crop.circle.badge.plus")
            }
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
        .accessibilityLabel(Strings.Common.add)
    }

    // MARK: - Add Moment FAB

    private func addMomentFAB(action: @escaping () -> Void) -> some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            Image(systemName: "camera.fill")
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
        .accessibilityLabel(Strings.LogMoment.title)
    }
}

// MARK: - Preview

#Preview {
    PlacesTabView(
        spotStore: SpotStore(),
        contactStore: ContactStore(),
        momentsViewModel: MomentsViewModel(eventStore: EventStore()),
        locationManager: LocationManager()
    )
    .environmentObject(ProfileStore())
}
