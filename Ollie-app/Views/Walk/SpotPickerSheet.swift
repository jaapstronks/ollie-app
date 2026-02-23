//
//  SpotPickerSheet.swift
//  Ollie-app
//
//  Sheet for selecting or creating a walk spot

import SwiftUI
import OllieShared
import CoreLocation

/// Sheet for picking a saved spot or capturing current location
struct SpotPickerSheet: View {
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var locationManager: LocationManager
    let onSelect: (WalkSpot) -> Void
    let onCancel: () -> Void

    @State private var isCapturingLocation = false
    @State private var capturedLocation: CLLocation?
    @State private var newSpotName = ""
    @State private var showingNameInput = false
    @State private var selectedSpot: WalkSpot?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Current location section
                currentLocationSection

                Divider()
                    .padding(.vertical, 8)

                // Saved spots
                savedSpotsSection
            }
            .navigationTitle(Strings.WalkLocations.pickSpot)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Current Location Section

    @ViewBuilder
    private var currentLocationSection: some View {
        VStack(spacing: 12) {
            if showingNameInput, let location = capturedLocation {
                // Name input mode
                VStack(spacing: 12) {
                    // Mini map preview
                    SpotMapView(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    .frame(height: 100)

                    // Name input
                    TextField(Strings.WalkLocations.spotNamePlaceholder, text: $newSpotName)
                        .textFieldStyle(.roundedBorder)

                    // Actions
                    HStack {
                        Button(Strings.Common.cancel) {
                            showingNameInput = false
                            capturedLocation = nil
                            newSpotName = ""
                        }
                        .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            saveAndSelectSpot(location: location)
                        } label: {
                            Text(Strings.WalkLocations.saveSpot)
                                .fontWeight(.semibold)
                        }
                        .disabled(newSpotName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                // Use current location button
                Button {
                    captureCurrentLocation()
                } label: {
                    HStack {
                        if isCapturingLocation {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(Strings.WalkLocations.useCurrentLocation)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.ollieAccent)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(isCapturingLocation)

                // Authorization hint
                if !locationManager.isAuthorized && locationManager.authorizationDetermined {
                    Text(Strings.WalkLocations.enableLocationInSettings)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }

    // MARK: - Saved Spots Section

    @ViewBuilder
    private var savedSpotsSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Favorites
                if !spotStore.favoriteSpots.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.WalkLocations.favorites)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ForEach(spotStore.favoriteSpots) { spot in
                            SpotRowCompact(spot: spot, isSelected: selectedSpot?.id == spot.id)
                                .onTapGesture {
                                    selectSpot(spot)
                                }
                        }
                        .padding(.horizontal)
                    }
                }

                // Recent
                if !spotStore.recentSpots.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.WalkLocations.recent)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ForEach(spotStore.recentSpots) { spot in
                            SpotRowCompact(spot: spot, isSelected: selectedSpot?.id == spot.id)
                                .onTapGesture {
                                    selectSpot(spot)
                                }
                        }
                        .padding(.horizontal)
                    }
                }

                // Empty state
                if spotStore.favoriteSpots.isEmpty && spotStore.recentSpots.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(Strings.WalkLocations.noRecentSpots)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Actions

    private func captureCurrentLocation() {
        isCapturingLocation = true

        Task {
            do {
                let location = try await locationManager.requestLocation()
                capturedLocation = location
                showingNameInput = true
                HapticFeedback.success()
            } catch {
                HapticFeedback.error()
                // Could show error alert here
            }
            isCapturingLocation = false
        }
    }

    private func selectSpot(_ spot: WalkSpot) {
        HapticFeedback.light()
        spotStore.incrementVisitCount(spot)
        onSelect(spot)
    }

    private func saveAndSelectSpot(location: CLLocation) {
        let name = newSpotName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let spot = spotStore.addSpot(
            name: name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        HapticFeedback.success()
        onSelect(spot)
    }
}

#Preview {
    SpotPickerSheet(
        spotStore: SpotStore(),
        locationManager: LocationManager(),
        onSelect: { spot in print("Selected: \(spot.name)") },
        onCancel: {}
    )
}
