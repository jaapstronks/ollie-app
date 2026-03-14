//
//  PlacesTabView.swift
//  Otis-app
//
//  Explore tab - full-screen map view of saved spots and photo moments
//

import SwiftUI
import OtisShared
import MapKit

/// Explore tab - full-screen map with spots, contacts, and photo pins
struct PlacesTabView: View {
    var spotStore: SpotStore
    var contactStore: ContactStore
    var momentsViewModel: MomentsViewModel
    @ObservedObject var locationManager: LocationManager
    var appointmentStore: AppointmentStore?
    var onSettingsTap: (() -> Void)?
    var onAddMoment: (() -> Void)?

    @Environment(ProfileStore.self) var profileStore
    @State private var mapViewModel: PlacesMapViewModel

    // View mode toggle (Map vs Gallery)
    @AppStorage("exploreViewMode") private var viewMode: ExploreViewMode = .map
    @AppStorage("momentsViewMode") private var momentsViewMode: MomentsViewMode = .gallery

    // First-visit tip tracking
    @AppStorage("hasSeenPlacesTip") private var hasSeenPlacesTip = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showingAddSpot = false
    @State private var showingAddContact = false
    @State private var selectedSpot: WalkSpot?
    @State private var selectedDiscoveredSpot: DiscoveredSpot?
    @State private var selectedContact: DogContact?
    @State private var selectedCluster: PhotoCluster?
    @State private var selectedPhotoEvent: PuppyEvent?
    @State private var hasBootstrappedExplore = false
    @State private var hasDiscoveredNearbyPlaces = false
    @State private var discoveryRefreshTask: Task<Void, Never>?
    @Namespace private var heroNamespace

    init(
        spotStore: SpotStore,
        contactStore: ContactStore,
        momentsViewModel: MomentsViewModel,
        locationManager: LocationManager,
        appointmentStore: AppointmentStore? = nil,
        onSettingsTap: (() -> Void)? = nil,
        onAddMoment: (() -> Void)? = nil
    ) {
        self.spotStore = spotStore
        self.contactStore = contactStore
        self.momentsViewModel = momentsViewModel
        self.locationManager = locationManager
        self.appointmentStore = appointmentStore
        self.onSettingsTap = onSettingsTap
        self.onAddMoment = onAddMoment
        self._mapViewModel = State(initialValue: PlacesMapViewModel(
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
                        .frame(minWidth: 120, idealWidth: 160, maxWidth: 220)
                }
            }
            .profileToolbar(profile: profileStore.profile) {
                onSettingsTap?()
            }
            .sheet(isPresented: $showingAddSpot) {
                AddSpotSheet(spotStore: spotStore, locationManager: locationManager)
                    .adaptivePresentationDetents(
                        compact: [.large],
                        regular: [.medium, .large]
                    )
            }
            .sheet(isPresented: $showingAddContact) {
                AddEditContactSheet(contactStore: contactStore)
                    .adaptivePresentationDetents(
                        compact: [.large],
                        regular: [.medium, .large]
                    )
            }
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(
                    spotStore: spotStore,
                    spot: spot,
                    momentsViewModel: momentsViewModel,
                    hideMapPreview: true  // Hide map when presented as sheet over map view
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedDiscoveredSpot) { spot in
                DiscoveredSpotDetailSheet(
                    spot: spot,
                    spotStore: spotStore,
                    hideMapPreview: true  // Hide map when presented over map view
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact, contactStore: contactStore, appointmentStore: appointmentStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedCluster) { cluster in
                PhotoPinDetailCard(
                    cluster: cluster,
                    spots: spotStore.spots,
                    onSelectPhoto: { event in
                        selectedCluster = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.3))
                            selectedPhotoEvent = event
                        }
                    },
                    onSaveSpot: nil
                )
                .adaptivePresentationDetents(
                    compact: [.medium, .large],
                    regular: [.medium, .large]
                )
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
        .task(id: viewMode) {
            await bootstrapExploreIfNeeded()
            if viewMode == .map {
                await discoverNearbyPlacesIfNeeded()
            }
        }
        .onChange(of: mapViewModel.selectedDiscoveryTypes) { _, _ in
            // Refresh discovery when selected types change, debounced to avoid churn.
            discoveryRefreshTask?.cancel()
            discoveryRefreshTask = Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
                let coords = locationManager.currentCoordinates ?? (51.9225, 4.4792)
                await mapViewModel.refreshDiscovery(latitude: coords.0, longitude: coords.1)
            }
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        ZStack(alignment: .bottomTrailing) {
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

                // First-visit tip overlay
                if !hasSeenPlacesTip {
                    VStack {
                        Spacer()
                        FeatureTipCard(
                            tip: .placesIntro,
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    hasSeenPlacesTip = true
                                }
                            }
                        )
                        .padding()
                        .padding(.bottom, FABLayout.bottomPadding + FABLayout.size + 16) // Space for FAB
                    }
                }
            }

            // Floating Add Button
            addSpotFAB
        }
    }

    // MARK: - Gallery Content

    private var galleryContent: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if momentsViewModel.isLoading {
                    // Skeleton loading grid - single shimmer on container only (no per-item animations)
                    ScrollView {
                        LazyVGrid(columns: galleryColumns, spacing: 2) {
                            ForEach(0..<12, id: \.self) { _ in
                                SkeletonRect(height: 120, cornerRadius: 0)
                                    .aspectRatio(1, contentMode: .fill)
                            }
                        }
                        .padding(.top)
                        .adaptiveContainer(maxWidth: iPadLayout.maxWideContentWidth)
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
                    .adaptiveContainer(maxWidth: iPadLayout.maxWideContentWidth)
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

    /// Adaptive grid columns - 3 fixed on iPhone, adaptive on iPad
    private var galleryColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            // iPad: adaptive columns based on available width
            return [GridItem(.adaptive(minimum: iPadLayout.adaptiveGridMinWidth), spacing: 2)]
        } else {
            // iPhone: fixed 3 columns
            return [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ]
        }
    }

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
                                mapViewModel.panForSheetPresentation(coordinate: marker.coordinate)
                                selectedSpot = spot
                            }
                    }

                case .contact(let contact):
                    Annotation("", coordinate: marker.coordinate) {
                        ContactMapMarker(contact: contact)
                            .onTapGesture {
                                mapViewModel.panForSheetPresentation(coordinate: marker.coordinate)
                                selectedContact = contact
                            }
                    }

                case .discoveredSpot(let spot):
                    Annotation("", coordinate: marker.coordinate) {
                        DiscoveredSpotMapMarker(spot: spot)
                            .onTapGesture {
                                mapViewModel.panForSheetPresentation(coordinate: marker.coordinate)
                                selectedDiscoveredSpot = spot
                            }
                    }

                case .photoCluster(let cluster):
                    Annotation("", coordinate: marker.coordinate) {
                        PhotoClusterMapMarker(cluster: cluster)
                            .onTapGesture {
                                mapViewModel.panForSheetPresentation(coordinate: marker.coordinate)
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
        SimpleFAB(accessibilityLabel: Strings.Common.add) {
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
                FABLabel()
            }
        }
    }

    // MARK: - Add Moment FAB

    private func addMomentFAB(action: @escaping () -> Void) -> some View {
        SimpleFAB(accessibilityLabel: Strings.LogMoment.title) {
            Button {
                HapticFeedback.medium()
                action()
            } label: {
                FABLabel(icon: "camera.fill")
            }
        }
    }

    // MARK: - Deferred Startup Work

    private func bootstrapExploreIfNeeded() async {
        guard !hasBootstrappedExplore else { return }
        hasBootstrappedExplore = true

        // Let tab transition finish before starting heavier setup work.
        await Task.yield()
        try? await Task.sleep(nanoseconds: 180_000_000)

        guard !Task.isCancelled else { return }
        momentsViewModel.loadEventsWithMedia()
        mapViewModel.fitMapToMarkers()
    }

    private func discoverNearbyPlacesIfNeeded() async {
        guard !hasDiscoveredNearbyPlaces else { return }
        hasDiscoveredNearbyPlaces = true

        // Keep network-bound discovery off the first animation frames.
        try? await Task.sleep(nanoseconds: 150_000_000)
        guard !Task.isCancelled else { return }

        let coords = locationManager.currentCoordinates ?? (51.9225, 4.4792)
        await mapViewModel.discoverPlacesNearby(latitude: coords.0, longitude: coords.1)
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
    .environment(ProfileStore())
}
