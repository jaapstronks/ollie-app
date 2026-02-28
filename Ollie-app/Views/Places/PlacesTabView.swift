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

    @EnvironmentObject var profileStore: ProfileStore
    @StateObject private var mapViewModel: PlacesMapViewModel

    @State private var showingAddSpot = false
    @State private var selectedSpot: WalkSpot?
    @State private var selectedDiscoveredSpot: DiscoveredSpot?
    @State private var selectedContact: DogContact?
    @State private var selectedCluster: PhotoCluster?
    @State private var selectedPhotoEvent: PuppyEvent?

    init(
        spotStore: SpotStore,
        contactStore: ContactStore,
        momentsViewModel: MomentsViewModel,
        locationManager: LocationManager,
        onSettingsTap: (() -> Void)? = nil
    ) {
        self.spotStore = spotStore
        self.contactStore = contactStore
        self.momentsViewModel = momentsViewModel
        self.locationManager = locationManager
        self.onSettingsTap = onSettingsTap
        self._mapViewModel = StateObject(wrappedValue: PlacesMapViewModel(
            spotStore: spotStore,
            contactStore: contactStore,
            momentsViewModel: momentsViewModel
        ))
    }

    var body: some View {
        NavigationStack {
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
                            selectedSpotCategories: $mapViewModel.selectedSpotCategories
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
            .navigationTitle(Strings.Places.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        mapViewModel.centerOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .profileToolbar(profile: profileStore.profile) {
                onSettingsTap?()
            }
            .sheet(isPresented: $showingAddSpot) {
                AddSpotSheet(spotStore: spotStore, locationManager: locationManager)
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
            // Discover dog parks near user's location or default location
            let coords = locationManager.currentCoordinates ?? (51.9225, 4.4792) // Rotterdam fallback
            await mapViewModel.discoverDogParksNearby(latitude: coords.0, longitude: coords.1)
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
