//
//  WalkMapView.swift
//  Otis-app
//
//  Full-screen map view for GPS-tracked walks
//  Shows live route, timer, distance, and potty logging buttons
//

import MapKit
import OtisShared
import SwiftUI

struct WalkMapView: View {
    @Bindable var viewModel: TimelineViewModel
    @Environment(WalkTrackingService.self) var trackingService
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isFollowingUser = true
    @State private var peeCount = 0
    @State private var poopCount = 0
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            // Map
            mapView

            // Overlay controls
            VStack(spacing: 0) {
                // Top bar with stats
                topBar

                Spacer()

                // Bottom controls
                bottomControls
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            startTrackingIfNeeded()
        }
        .confirmationDialog(
            Strings.WalkMap.endWalkQuestion,
            isPresented: $showEndConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.WalkMap.endWalk, role: .destructive) {
                endWalk()
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            // User location
            UserAnnotation()

            // Route polyline
            if let route = trackingService.currentRoute, route.coordinates.count >= 2 {
                MapPolyline(coordinates: route.coordinates.map(\.coordinate))
                    .stroke(.green, lineWidth: 4)
            }

            // Potty markers would go here when we add event locations
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onChange(of: trackingService.currentLocation) { _, newLocation in
            if isFollowingUser, let location = newLocation {
                withAnimation(.easeInOut(duration: 0.3)) {
                    cameraPosition = .camera(MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: 500,
                        heading: location.course >= 0 ? location.course : 0
                    ))
                }
            }
        }
        .onMapCameraChange { context in
            // Stop following if user manually moves the map
            // (This is a simplification - could be more sophisticated)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 0) {
            // Stats row with proper safe area
            HStack(spacing: 24) {
                // Minimize button
                Button {
                    HapticFeedback.medium()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Spacer()

                // Duration
                VStack(spacing: 2) {
                    Text(trackingService.formattedLiveDurationLong)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text(Strings.WalkMap.duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                // Distance
                VStack(spacing: 2) {
                    Text(trackingService.formattedLiveDistance)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                    Text(Strings.WalkMap.distance)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Re-center button
                Button {
                    isFollowingUser = true
                    if let location = trackingService.currentLocation {
                        withAnimation {
                            cameraPosition = .camera(MapCamera(
                                centerCoordinate: location.coordinate,
                                distance: 500
                            ))
                        }
                    }
                } label: {
                    Image(systemName: isFollowingUser ? "location.fill" : "location")
                        .font(.title3)
                        .foregroundStyle(isFollowingUser ? .blue : .secondary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.top, 50) // Safe area for status bar
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Potty buttons
            HStack(spacing: 16) {
                // Pee button
                pottyButton(
                    icon: EventType.plassen.icon,
                    label: EventType.plassen.label,
                    color: .blue,
                    count: peeCount
                ) {
                    logPee()
                }

                // Poop button
                pottyButton(
                    icon: EventType.poepen.icon,
                    label: EventType.poepen.label,
                    color: .brown,
                    count: poopCount
                ) {
                    logPoop()
                }
            }

            // End walk button
            Button {
                showEndConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "stop.fill")
                    Text(Strings.WalkMap.endWalk)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.red.gradient, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, 16)
        .background(.ultraThinMaterial)
    }

    // MARK: - Potty Button

    @ViewBuilder
    private func pottyButton(
        icon: String,
        label: String,
        color: Color,
        count: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(color)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startTrackingIfNeeded() {
        guard !trackingService.isTracking else { return }

        // Request authorization if needed
        if !trackingService.canTrack {
            trackingService.requestAuthorization()
        }

        // Start tracking with the walk start time from activity manager
        let startTime = viewModel.currentActivityStartTime ?? Date()
        trackingService.startTracking(startTime: startTime)
    }

    private func logPee() {
        peeCount += 1
        viewModel.logPottyDuringWalk(type: .plassen)
        HapticFeedback.success()
    }

    private func logPoop() {
        poopCount += 1
        viewModel.logPottyDuringWalk(type: .poepen)
        HapticFeedback.success()
    }

    private func endWalk() {
        // Stop GPS tracking
        let route = trackingService.stopTracking()

        // End the walk activity (this logs the walk event)
        viewModel.endWalkWithPotty(
            minutesAgo: 0,
            note: nil,
            didPee: false,  // Already logged individually
            didPoop: false  // Already logged individually
        )

        // TODO: Save route to Core Data / associate with walk event
        if let route = route {
            // For now, just log the stats
            print("Walk completed: \(route.formattedDistance()), \(route.formattedDuration)")
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    WalkMapView(viewModel: TimelineViewModel(
        eventStore: EventStore(),
        profileStore: ProfileStore()
    ))
    .environment(WalkTrackingService())
}
