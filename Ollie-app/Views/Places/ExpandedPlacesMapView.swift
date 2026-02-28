//
//  ExpandedPlacesMapView.swift
//  Ollie-app
//
//  Full-screen map view with filters for spots, contacts, and photos
//

import SwiftUI
import MapKit
import OllieShared

/// Full-screen map view with filter chips and all marker types
struct ExpandedPlacesMapView: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var contactStore: ContactStore
    @ObservedObject var momentsViewModel: MomentsViewModel
    @ObservedObject var locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlacesMapViewModel

    @State private var selectedSpot: WalkSpot?
    @State private var selectedDiscoveredSpot: DiscoveredSpot?
    @State private var selectedContact: DogContact?
    @State private var selectedCluster: PhotoCluster?
    @State private var selectedPhotoEvent: PuppyEvent?

    init(
        spotStore: SpotStore,
        contactStore: ContactStore,
        momentsViewModel: MomentsViewModel,
        locationManager: LocationManager
    ) {
        self.spotStore = spotStore
        self.contactStore = contactStore
        self.momentsViewModel = momentsViewModel
        self.locationManager = locationManager
        self._viewModel = StateObject(wrappedValue: PlacesMapViewModel(
            spotStore: spotStore,
            contactStore: contactStore,
            momentsViewModel: momentsViewModel
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Full-screen map
                mapView
                    .ignoresSafeArea(edges: .bottom)

                // Filter bar overlay at top
                VStack(spacing: 0) {
                    PlacesFilterBar(
                        activeFilters: $viewModel.activeFilters,
                        selectedContactTypes: $viewModel.selectedContactTypes,
                        selectedSpotCategories: $viewModel.selectedSpotCategories
                    )

                    Spacer()
                }
            }
            .navigationTitle(Strings.Places.expandedMap)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.centerOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
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
            viewModel.fitMapToMarkers()
        }
        .task {
            // Discover dog parks near user's location or default location
            let coords = locationManager.currentCoordinates ?? (51.9225, 4.4792) // Rotterdam fallback
            await viewModel.discoverDogParksNearby(latitude: coords.0, longitude: coords.1)
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $viewModel.cameraPosition) {
            // User location
            UserAnnotation()

            // Render all visible markers
            ForEach(viewModel.visibleMarkers) { marker in
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
                                // Always show detail card (handles single and multi-photo)
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
}

// MARK: - Preview

#Preview {
    ExpandedPlacesMapView(
        spotStore: SpotStore(),
        contactStore: ContactStore(),
        momentsViewModel: MomentsViewModel(eventStore: EventStore()),
        locationManager: LocationManager()
    )
}
