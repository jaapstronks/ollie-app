//
//  PlacesMapComponents.swift
//  Ollie-app
//
//  Map-related components for the Places tab
//  Extracted from PlacesTabView for better organization
//

import SwiftUI
import OllieShared
import MapKit

// MARK: - Map Preview with Spots and Photos

/// Interactive map showing spots and clustered photo markers
struct PlacesMapPreview: View {
    let spots: [WalkSpot]
    let photoClusters: [PhotoCluster]
    let onTapSpot: (WalkSpot) -> Void
    let onTapCluster: (PhotoCluster) -> Void

    private var cameraPosition: MapCameraPosition {
        var allLatitudes: [Double] = spots.map { $0.latitude }
        var allLongitudes: [Double] = spots.map { $0.longitude }

        for cluster in photoClusters {
            allLatitudes.append(cluster.latitude)
            allLongitudes.append(cluster.longitude)
        }

        guard let minLat = allLatitudes.min(),
              let maxLat = allLatitudes.max(),
              let minLon = allLongitudes.min(),
              let maxLon = allLongitudes.max() else {
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.9225, longitude: 4.4792),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = max(0.01, (maxLat - minLat) * 1.5)
        let spanLon = max(0.01, (maxLon - minLon) * 1.5)

        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        ))
    }

    var body: some View {
        Map(initialPosition: cameraPosition) {
            ForEach(spots) { spot in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)) {
                    SpotMapMarker(spot: spot)
                        .onTapGesture {
                            onTapSpot(spot)
                        }
                }
            }

            ForEach(photoClusters) { cluster in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: cluster.latitude, longitude: cluster.longitude)) {
                    PhotoClusterMapMarker(cluster: cluster)
                        .onTapGesture {
                            onTapCluster(cluster)
                        }
                }
            }
        }
        .mapControlVisibility(.hidden)
    }
}

// MARK: - Map Markers

struct SpotMapMarker: View {
    let spot: WalkSpot

    var body: some View {
        Image(systemName: spot.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
            .font(.title3)
            .foregroundStyle(spot.isFavorite ? .yellow : .ollieAccent)
            .background(
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
            )
    }
}

/// Map marker for a discovered dog park (from OpenStreetMap or government data)
struct DiscoveredSpotMapMarker: View {
    let spot: DiscoveredSpot

    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(Color.ollieInfo.opacity(0.2))
                .frame(width: 32, height: 32)
                .blur(radius: 3)

            // Main marker
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                // Blue ring to distinguish from saved spots
                Circle()
                    .stroke(Color.ollieInfo, lineWidth: 2)
                    .frame(width: 28, height: 28)

                Image(systemName: spot.category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ollieInfo)
            }

            // Fenced indicator badge
            if spot.isFenced == true {
                Circle()
                    .fill(Color.ollieSuccess)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 10, y: -10)
            }
        }
    }
}

/// Map marker for a contact location
struct ContactMapMarker: View {
    let contact: DogContact

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            Image(systemName: contact.contactType.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(markerColor)
        }
    }

    private var markerColor: Color {
        switch contact.contactType {
        case .vet, .emergencyVet:
            return .ollieHealthRed
        case .daycare, .sitter:
            return .ollieInfo
        case .groomer:
            return .olliePurple
        case .trainer, .walker:
            return .ollieSuccess
        case .petStore:
            return .ollieAccent
        case .breeder:
            return .ollieAccent
        case .other:
            return .ollieMuted
        }
    }
}

/// Map marker for a photo cluster - shows count badge when multiple photos
/// Shows golden ring/glow when cluster contains milestone photos
struct PhotoClusterMapMarker: View {
    let cluster: PhotoCluster

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Golden glow for milestone photos
            if cluster.hasMilestonePhoto {
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .blur(radius: 4)
            }

            // Main marker
            ZStack {
                // White background circle
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                // Golden ring for milestone photos
                if cluster.hasMilestonePhoto {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }

                Image(systemName: cluster.hasMilestonePhoto ? "star.circle.fill" : "camera.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(cluster.hasMilestonePhoto ? .yellow : .pink)
            }

            // Count badge
            if cluster.count > 1 {
                Text("\(cluster.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(cluster.hasMilestonePhoto ? Color.yellow : .pink)
                    )
                    .offset(x: 8, y: -6)
            }
        }
    }
}

// MARK: - Spot Card (Horizontal Scroll)

struct SpotCard: View {
    let spot: WalkSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))

                Image(systemName: spot.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(spot.isFavorite ? .yellow : .ollieAccent)
            }
            .frame(width: 80, height: 60)

            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(Strings.WalkLocations.visitCount(spot.visitCount))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Photo Cluster Preview Sheet

/// Sheet showing photos in a cluster when tapped on map
struct PhotoClusterPreviewSheet: View {
    let cluster: PhotoCluster
    let onSelectPhoto: (PuppyEvent) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundStyle(.pink)
                        Text(Strings.Places.photoCount(cluster.count))
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(cluster.events) { event in
                            GalleryThumbnail(event: event)
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    onSelectPhoto(event)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(Strings.Places.filterPhotos)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}
