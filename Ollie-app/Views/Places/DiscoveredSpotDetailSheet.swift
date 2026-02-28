//
//  DiscoveredSpotDetailSheet.swift
//  Ollie-app
//
//  Detail sheet for discovered dog parks from OpenStreetMap or government data
//

import SwiftUI
import OllieShared
import MapKit

/// Detail sheet for a discovered dog park
struct DiscoveredSpotDetailSheet: View {
    let spot: DiscoveredSpot
    @ObservedObject var spotStore: SpotStore

    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Map preview
                    mapPreview

                    // Info section
                    infoSection

                    // Amenities section (if any)
                    if !spot.amenities.isEmpty {
                        amenitiesSection
                    }

                    // Actions
                    actionsSection

                    // Attribution
                    attributionFooter
                }
                .padding()
            }
            .navigationTitle(spot.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
            .alert(Strings.Places.spotSaved, isPresented: $showingSaveConfirmation) {
                Button(Strings.Common.ok) {
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Map Preview

    private var mapPreview: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))) {
            Annotation("", coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)) {
                DiscoveredSpotMapMarker(spot: spot)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .mapControlVisibility(.hidden)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category badge
            HStack {
                Image(systemName: spot.category.icon)
                    .foregroundStyle(categoryColor)
                Text(spot.category.label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if spot.isFenced == true {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Color.ollieSuccess)
                    Text(Strings.Places.fenced)
                        .font(.subheadline)
                        .foregroundStyle(Color.ollieSuccess)
                }
            }

            // Surface type
            if let surface = spot.surface {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.secondary)
                    Text(surfaceLabel(surface))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Address if available
            if let address = spot.address {
                HStack {
                    Image(systemName: "mappin")
                        .foregroundStyle(.secondary)
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Amenities Section

    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Places.amenities)
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(spot.amenities, id: \.self) { amenity in
                    AmenityBadge(amenity: amenity)
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Save to My Spots
            Button {
                saveToMySpots()
            } label: {
                Label(Strings.Places.saveToMySpots, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.ollieAccent)

            // Open in Apple Maps
            Button {
                openInMaps()
            } label: {
                Label(Strings.WalkLocations.openInMaps, systemImage: "map.fill")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Attribution Footer

    private var attributionFooter: some View {
        HStack {
            Spacer()
            Text(spot.source.attribution)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.top)
    }

    // MARK: - Actions

    private func saveToMySpots() {
        let walkSpot = spot.toWalkSpot()
        spotStore.addSpot(walkSpot)
        showingSaveConfirmation = true
    }

    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = spot.name
        mapItem.openInMaps()
    }

    // MARK: - Helpers

    private func surfaceLabel(_ surface: String) -> String {
        switch surface.lowercased() {
        case "grass": return Strings.Places.surfaceGrass
        case "sand": return Strings.Places.surfaceSand
        case "gravel": return Strings.Places.surfaceGravel
        case "wood_chips", "woodchips": return Strings.Places.surfaceWoodChips
        case "asphalt": return Strings.Places.surfaceAsphalt
        default: return surface.capitalized
        }
    }

    /// Category-specific color for visual distinction
    private var categoryColor: Color {
        switch spot.category {
        case .dogPark, .offLeashArea, .dogBeach, .dogForest, .dogFriendlyPark:
            return .ollieInfo
        case .vetClinic:
            return .ollieHealthRed
        case .petStore:
            return .ollieAccent
        case .dogFriendlyCafe:
            return .olliePurple
        }
    }
}

// MARK: - Amenity Badge

struct AmenityBadge: View {
    let amenity: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForAmenity(amenity))
                .font(.caption)
            Text(amenity.capitalized)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemBackground))
        .clipShape(Capsule())
    }

    private func iconForAmenity(_ amenity: String) -> String {
        let lowered = amenity.lowercased()
        // Dog park amenities
        if lowered.contains("waste") { return "trash.fill" }
        if lowered.contains("bench") { return "chair.fill" }
        if lowered.contains("water") || lowered.contains("drinking") { return "drop.fill" }
        if lowered.contains("light") { return "lightbulb.fill" }
        // Service amenities
        if lowered.contains("emergency") || lowered.contains("24h") { return "cross.case.fill" }
        if lowered.contains("wheelchair") { return "figure.roll" }
        if lowered.contains("grooming") { return "scissors" }
        if lowered.contains("phone") { return "phone.fill" }
        // Cafe amenities
        if lowered.contains("outdoor") || lowered.contains("seating") { return "sun.max.fill" }
        if lowered.contains("wifi") { return "wifi" }
        // Opening hours
        if lowered.contains(":") && (lowered.contains("mo") || lowered.contains("tu")) { return "clock.fill" }

        return "checkmark"
    }
}

// MARK: - Preview

#Preview {
    DiscoveredSpotDetailSheet(
        spot: DiscoveredSpot(
            id: "osm:way:12345",
            name: "Kralingse Bos Dog Park",
            latitude: 51.93,
            longitude: 4.51,
            source: .openStreetMap,
            sourceId: "12345",
            category: .dogPark,
            amenities: ["waste bin", "bench", "water"],
            isFenced: true,
            surface: "grass"
        ),
        spotStore: SpotStore()
    )
}
