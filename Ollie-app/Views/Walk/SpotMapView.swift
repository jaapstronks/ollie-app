//
//  SpotMapView.swift
//  Ollie-app
//
//  MapKit mini-map component for displaying a single location

import SwiftUI
import MapKit

/// Non-interactive mini-map showing a single pinned location
struct SpotMapView: View {
    let latitude: Double
    let longitude: Double
    var spotName: String?

    @State private var region: MKCoordinateRegion

    init(latitude: Double, longitude: Double, spotName: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.spotName = spotName

        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }

    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: [annotation]) { item in
            MapAnnotation(coordinate: item.coordinate) {
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
        .allowsHitTesting(false) // Non-interactive
        .cornerRadius(12)
    }

    private var annotation: MapAnnotationItem {
        MapAnnotationItem(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }
}

/// Helper struct for map annotations
struct MapAnnotationItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
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
