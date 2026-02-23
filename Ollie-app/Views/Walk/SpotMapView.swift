//
//  SpotMapView.swift
//  Ollie-app
//
//  MapKit mini-map component for displaying a single location

import SwiftUI
import OllieShared
import MapKit

/// Non-interactive mini-map showing a single pinned location
struct SpotMapView: View {
    let latitude: Double
    let longitude: Double
    var spotName: String?

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private var cameraPosition: MapCameraPosition {
        .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }

    var body: some View {
        Map(initialPosition: cameraPosition, interactionModes: []) {
            Annotation(spotName ?? "", coordinate: coordinate) {
                VStack(spacing: 2) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.ollieAccent)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 20, height: 20)
                        )

                    if let name = spotName {
                        Text(name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        SpotMapView(
            latitude: 51.9225,
            longitude: 4.4792,
            spotName: "Park"
        )
        .frame(height: 120)

        SpotMapView(
            latitude: 51.9225,
            longitude: 4.4792
        )
        .frame(height: 100)
    }
    .padding()
}
