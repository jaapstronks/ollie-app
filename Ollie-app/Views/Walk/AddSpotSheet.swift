//
//  AddSpotSheet.swift
//  Ollie-app
//
//  Sheet for creating a new walk spot with location picker

import CoreLocation
import MapKit
import SwiftUI

/// Sheet for adding a new walk spot
struct AddSpotSheet: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss

    @State private var spotName = ""
    @State private var spotNotes = ""
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var isCapturingCurrentLocation = false
    @State private var showingMapPicker = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                // Location section
                Section {
                    // Current location option
                    Button {
                        captureCurrentLocation()
                    } label: {
                        HStack {
                            Label(Strings.WalkLocations.useCurrentLocation, systemImage: "location.fill")
                            Spacer()
                            if isCapturingCurrentLocation {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isCapturingCurrentLocation)

                    // Pick on map option
                    Button {
                        showingMapPicker = true
                    } label: {
                        Label(Strings.SpotDetail.pickOnMap, systemImage: "map")
                    }

                    // Show selected location
                    if let location = selectedLocation {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(Strings.WalkLocations.locationCaptured)
                            Spacer()
                            Button(Strings.Common.edit) {
                                showingMapPicker = true
                            }
                            .font(.caption)
                        }

                        // Mini map preview
                        SpotMapView(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )
                        .frame(height: 120)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }

                    // Error message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(Strings.WalkLocations.location)
                }

                // Name section
                Section {
                    TextField(Strings.WalkLocations.spotNamePlaceholder, text: $spotName)
                } header: {
                    Text(Strings.WalkLocations.nameThisSpot)
                }

                // Notes section
                Section {
                    TextField(Strings.LogEvent.notePlaceholder, text: $spotNotes)
                } header: {
                    Text(Strings.SpotDetail.notesOptional)
                }
            }
            .navigationTitle(Strings.SpotDetail.addSpot)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(Strings.Common.save) {
                            saveSpot()
                        }
                        .disabled(!canSave)
                    }
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                LocationMapPicker(
                    initialLocation: selectedLocation ?? locationManager.currentLocation?.coordinate,
                    onSelect: { coordinate in
                        selectedLocation = coordinate
                        errorMessage = nil
                    }
                )
            }
        }
    }

    private var canSave: Bool {
        selectedLocation != nil && !spotName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func captureCurrentLocation() {
        isCapturingCurrentLocation = true
        errorMessage = nil

        Task {
            do {
                let location = try await locationManager.requestLocation()
                selectedLocation = location.coordinate
            } catch {
                errorMessage = error.localizedDescription
            }
            isCapturingCurrentLocation = false
        }
    }

    private func saveSpot() {
        guard let location = selectedLocation else { return }
        guard !isSaving else { return } // Prevent double-tap

        isSaving = true

        let trimmedName = spotName.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = spotNotes.trimmingCharacters(in: .whitespaces)

        _ = spotStore.addSpot(
            name: trimmedName,
            latitude: location.latitude,
            longitude: location.longitude,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )

        HapticFeedback.success()

        // Small delay to ensure state updates are processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
}

// MARK: - Location Map Picker

/// Full-screen map for picking a location by tapping
struct LocationMapPicker: View {
    let initialLocation: CLLocationCoordinate2D?
    let onSelect: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D

    init(
        initialLocation: CLLocationCoordinate2D?,
        onSelect: @escaping (CLLocationCoordinate2D) -> Void
    ) {
        self.initialLocation = initialLocation
        self.onSelect = onSelect

        // Default to provided location or Rotterdam center
        let center = initialLocation ?? CLLocationCoordinate2D(latitude: 51.9225, longitude: 4.4792)
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
        _selectedCoordinate = State(initialValue: center)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Interactive map
                Map(position: $cameraPosition) {
                    Annotation("", coordinate: selectedCoordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.ollieAccent)
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 24, height: 24)
                            )
                    }
                }
                .onMapCameraChange { context in
                    selectedCoordinate = context.region.center
                }
                .ignoresSafeArea(edges: .bottom)

                // Crosshair in center
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                        Spacer()
                    }
                    Spacer()
                }

                // Instructions
                VStack {
                    Text(Strings.SpotDetail.moveMapToSelect)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.top, 8)
                    Spacer()
                }
            }
            .navigationTitle(Strings.SpotDetail.pickOnMap)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.SpotDetail.selectLocation) {
                        onSelect(selectedCoordinate)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddSpotSheet(
        spotStore: SpotStore(),
        locationManager: LocationManager()
    )
}
