//
//  LocationPickerMapView.swift
//  Ollie-app
//
//  Map-based location picker for selecting contact locations
//

import SwiftUI
import MapKit
import CoreLocation

/// A map view for picking a location by tapping
struct LocationPickerMapView: View {
    @Binding var selectedLatitude: Double?
    @Binding var selectedLongitude: Double?
    var address: String?
    var onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var geocoder = GeocoderService()

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var isGeocoding = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Map with tap gesture
                mapView

                // Crosshair in center for easier targeting
                crosshairOverlay

                // Bottom card with coordinates and confirm
                VStack {
                    Spacer()
                    confirmationCard
                }
            }
            .navigationTitle(Strings.Places.selectLocation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        centerOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .onAppear {
                setupInitialPosition()
            }
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                UserAnnotation()

                if let coordinate = pinCoordinate {
                    Annotation("", coordinate: coordinate) {
                        LocationPin()
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    withAnimation(.spring(response: 0.3)) {
                        pinCoordinate = coordinate
                    }
                }
            }
        }
    }

    // MARK: - Crosshair Overlay

    private var crosshairOverlay: some View {
        Image(systemName: "plus")
            .font(.system(size: 24, weight: .light))
            .foregroundStyle(.secondary.opacity(0.5))
            .allowsHitTesting(false)
    }

    // MARK: - Confirmation Card

    private var confirmationCard: some View {
        VStack(spacing: 12) {
            if let coordinate = pinCoordinate {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.ollieAccent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Places.selectedLocation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(coordinateString(coordinate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "hand.tap")
                        .foregroundStyle(.secondary)
                    Text(Strings.Places.tapToSelectLocation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            // Geocode from address button
            if let address = address, !address.isEmpty {
                Button {
                    geocodeAddress(address)
                } label: {
                    HStack {
                        if isGeocoding {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.magnifyingglass")
                        }
                        Text(Strings.Places.useAddress)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isGeocoding)
            }

            // Confirm button
            Button {
                if let coordinate = pinCoordinate {
                    selectedLatitude = coordinate.latitude
                    selectedLongitude = coordinate.longitude
                    onConfirm()
                    dismiss()
                }
            } label: {
                Text(Strings.Places.confirmLocation)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(pinCoordinate == nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
        .padding()
    }

    // MARK: - Helpers

    private func setupInitialPosition() {
        if let lat = selectedLatitude, let lon = selectedLongitude {
            // Use existing coordinates
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            pinCoordinate = coordinate
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            // Default to user location
            cameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.9225, longitude: 4.4792),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )))
        }
    }

    private func centerOnUserLocation() {
        withAnimation(.easeInOut) {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }

    private func geocodeAddress(_ address: String) {
        isGeocoding = true
        geocoder.geocode(address: address) { result in
            isGeocoding = false
            switch result {
            case .success(let coordinate):
                withAnimation(.spring(response: 0.3)) {
                    pinCoordinate = coordinate
                    cameraPosition = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            case .failure:
                // Geocoding failed - could show an alert here
                break
            }
        }
    }

    private func coordinateString(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - Location Pin

struct LocationPin: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.ollieAccent)

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.ollieAccent)
                .offset(y: -6)
        }
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
    }
}

// MARK: - Geocoder Service

struct GeocoderService {
    func geocode(address: String, completion: @escaping @Sendable @MainActor (Result<CLLocationCoordinate2D, Error>) -> Void) {
        Task {
            do {
                let coordinate = try await geocodeAddress(address)
                await MainActor.run {
                    completion(.success(coordinate))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    private func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let location = placemarks.first?.location else {
            throw NSError(domain: "GeocoderService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No results found"])
        }
        return location.coordinate
    }
}

// MARK: - Preview

#Preview {
    LocationPickerMapView(
        selectedLatitude: .constant(nil),
        selectedLongitude: .constant(nil),
        address: "Coolsingel 40, Rotterdam",
        onConfirm: {}
    )
}
