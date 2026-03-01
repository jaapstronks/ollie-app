//
//  DiscoveredSpotDetailSheet.swift
//  Otis-app
//
//  Detail sheet for discovered dog parks from OpenStreetMap or government data
//

import SwiftUI
import OtisShared
import MapKit

/// Detail sheet for a discovered dog park
struct DiscoveredSpotDetailSheet: View {
    let spot: DiscoveredSpot
    @ObservedObject var spotStore: SpotStore

    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveConfirmation = false
    @State private var hoursExpanded = false

    /// Parsed amenity data for organized display
    private var parsedAmenities: ParsedAmenities {
        ParsedAmenities(amenities: spot.amenities)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Map preview
                    mapPreview

                    // Quick info row
                    quickInfoRow

                    Divider()

                    // Details section
                    detailsSection

                    // Opening hours (if available)
                    if parsedAmenities.hasOpeningHours {
                        openingHoursSection
                    }

                    // Facilities section (if any)
                    if !parsedAmenities.facilities.isEmpty {
                        facilitiesSection
                    }

                    // Contact section (if any)
                    if !parsedAmenities.contactInfo.isEmpty {
                        contactSection
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
        .presentationDragIndicator(.visible)
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
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .mapControlVisibility(.hidden)
    }

    // MARK: - Quick Info Row

    private var quickInfoRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category pill
                HStack(spacing: 6) {
                    Image(systemName: spot.category.icon)
                        .font(.caption)
                    Text(spot.category.label)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(categoryColor.opacity(0.15))
                .foregroundStyle(categoryColor)
                .clipShape(Capsule())

                // Fenced badge
                if spot.isFenced == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                        Text(Strings.Places.fenced)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.otisSuccess.opacity(0.15))
                    .foregroundStyle(Color.otisSuccess)
                    .clipShape(Capsule())
                }

                // Surface badge
                if let surface = spot.surface {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                        Text(surfaceLabel(surface))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemBackground))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Address
            if let address = spot.address {
                DetailRow(icon: "mappin.circle.fill", iconColor: .otisAccent) {
                    Text(address)
                        .font(.subheadline)
                }
            }

            // Phone (if available)
            if let phone = parsedAmenities.phone {
                DetailRow(icon: "phone.circle.fill", iconColor: .otisSuccess) {
                    Link(phone, destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!)
                        .font(.subheadline)
                }
            }

            // Website (if available)
            if let website = parsedAmenities.website {
                DetailRow(icon: "globe", iconColor: .otisInfo) {
                    Link(websiteDisplayName(website), destination: URL(string: website)!)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Opening Hours Section

    private var openingHoursSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoursExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Places.openingHours)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if !hoursExpanded, let summary = parsedAmenities.openingHoursSummary {
                            Text(summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: hoursExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if hoursExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(parsedAmenities.openingHoursFormatted, id: \.day) { hours in
                        HStack {
                            Text(hours.day)
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(width: 36, alignment: .leading)

                            Text(hours.time)
                                .font(.caption)
                                .foregroundStyle(hours.isClosed ? .secondary : .primary)

                            Spacer()
                        }
                    }
                }
                .padding(.leading, 32)
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Facilities Section

    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Places.amenities)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(parsedAmenities.facilities, id: \.self) { facility in
                    FacilityBadge(facility: facility)
                }
            }
        }
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Places.contact)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(parsedAmenities.contactInfo, id: \.self) { info in
                DetailRow(icon: contactIcon(for: info), iconColor: .secondary) {
                    Text(info)
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 10) {
            // Save to My Spots
            Button {
                saveToMySpots()
            } label: {
                Label(Strings.Places.saveToFavorites, systemImage: "heart.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.otisAccent)

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
        .padding(.top, 4)
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
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func saveToMySpots() {
        let walkSpot = spot.toWalkSpot()
        spotStore.addSpot(walkSpot)
        showingSaveConfirmation = true
    }

    private func openInMaps() {
        MapsService.openLocation(
            latitude: spot.latitude,
            longitude: spot.longitude,
            name: spot.name
        )
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

    private func websiteDisplayName(_ url: String) -> String {
        if let host = URL(string: url)?.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return url
    }

    private func contactIcon(for info: String) -> String {
        let lowered = info.lowercased()
        if lowered.contains("@") { return "envelope.fill" }
        if lowered.contains("http") || lowered.contains("www") { return "globe" }
        return "info.circle.fill"
    }

    /// Category-specific color for visual distinction
    private var categoryColor: Color {
        switch spot.category {
        case .dogPark, .offLeashArea, .dogBeach, .dogForest, .dogFriendlyPark:
            return .otisInfo
        case .vetClinic:
            return .otisHealthRed
        case .petStore:
            return .otisAccent
        case .dogFriendlyCafe:
            return .otisPurple
        }
    }
}

// MARK: - Detail Row Component

private struct DetailRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Facility Badge

private struct FacilityBadge: View {
    let facility: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconForFacility(facility))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(labelForFacility(facility))
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func iconForFacility(_ facility: String) -> String {
        let lowered = facility.lowercased()
        if lowered.contains("waste") || lowered.contains("bin") || lowered.contains("trash") { return "trash.fill" }
        if lowered.contains("bench") || lowered.contains("seat") { return "chair.fill" }
        if lowered.contains("water") || lowered.contains("drinking") || lowered.contains("fountain") { return "drop.fill" }
        if lowered.contains("light") { return "lightbulb.fill" }
        if lowered.contains("parking") { return "car.fill" }
        if lowered.contains("toilet") || lowered.contains("restroom") || lowered.contains("wc") { return "toilet.fill" }
        if lowered.contains("wheelchair") || lowered.contains("accessible") { return "figure.roll" }
        if lowered.contains("shade") || lowered.contains("shelter") { return "umbrella.fill" }
        if lowered.contains("wifi") { return "wifi" }
        if lowered.contains("outdoor") { return "sun.max.fill" }
        if lowered.contains("groom") { return "scissors" }
        if lowered.contains("agility") { return "figure.run" }
        return "checkmark.circle.fill"
    }

    private func labelForFacility(_ facility: String) -> String {
        // Clean up common facility names
        let lowered = facility.lowercased()
        if lowered.contains("waste") || lowered.contains("bin") { return Strings.Places.facilityWasteBin }
        if lowered.contains("bench") { return Strings.Places.facilityBench }
        if lowered.contains("water") || lowered.contains("drinking") { return Strings.Places.facilityWater }
        if lowered.contains("light") { return Strings.Places.facilityLighting }
        if lowered.contains("parking") { return Strings.Places.facilityParking }
        if lowered.contains("toilet") || lowered.contains("restroom") { return Strings.Places.facilityRestroom }
        if lowered.contains("wheelchair") { return Strings.Places.facilityAccessible }
        if lowered.contains("shade") || lowered.contains("shelter") { return Strings.Places.facilityShelter }
        if lowered.contains("wifi") { return "WiFi" }
        if lowered.contains("outdoor") { return Strings.Places.facilityOutdoorSeating }
        if lowered.contains("agility") { return Strings.Places.facilityAgility }
        return facility.capitalized
    }
}

// MARK: - Parsed Amenities

private struct ParsedAmenities {
    var openingHours: String?
    var openingHoursFormatted: [DayHours] = []
    var openingHoursSummary: String?
    var phone: String?
    var website: String?
    var facilities: [String] = []
    var contactInfo: [String] = []

    struct DayHours {
        let day: String
        let time: String
        var isClosed: Bool { time.lowercased().contains("closed") || time == "-" }
    }

    var hasOpeningHours: Bool {
        openingHours != nil || !openingHoursFormatted.isEmpty
    }

    init(amenities: [String]) {
        for amenity in amenities {
            let lowered = amenity.lowercased()

            // Phone detection
            if lowered.contains("phone") || lowered.hasPrefix("+") || lowered.hasPrefix("tel:") {
                let cleaned = amenity
                    .replacingOccurrences(of: "phone:", with: "")
                    .replacingOccurrences(of: "tel:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                phone = cleaned
                continue
            }

            // Website detection
            if lowered.contains("http") || lowered.contains("www.") || lowered.contains("website:") {
                let cleaned = amenity
                    .replacingOccurrences(of: "website:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                website = cleaned.hasPrefix("http") ? cleaned : "https://\(cleaned)"
                continue
            }

            // Opening hours detection (OSM format: "Mo-Fr 09:00-18:00; Sa 10:00-16:00")
            if isOpeningHoursFormat(lowered) {
                openingHours = amenity
                openingHoursFormatted = parseOpeningHours(amenity)
                openingHoursSummary = generateHoursSummary(amenity)
                continue
            }

            // Email detection
            if lowered.contains("@") && lowered.contains(".") {
                contactInfo.append(amenity)
                continue
            }

            // Everything else is a facility
            facilities.append(amenity)
        }
    }

    private func isOpeningHoursFormat(_ text: String) -> Bool {
        // OSM opening hours typically contain day abbreviations and times
        let dayPatterns = ["mo", "tu", "we", "th", "fr", "sa", "su", "mon", "tue", "wed", "thu", "fri", "sat", "sun"]
        let hasDay = dayPatterns.contains { text.contains($0) }
        let hasTime = text.contains(":") && (text.contains("-") || text.contains("off") || text.contains("closed"))
        return hasDay && hasTime
    }

    private func parseOpeningHours(_ hours: String) -> [DayHours] {
        // Map day abbreviations to full names
        let dayMap: [(abbrev: [String], full: String)] = [
            (["mo", "mon"], "Mon"),
            (["tu", "tue"], "Tue"),
            (["we", "wed"], "Wed"),
            (["th", "thu"], "Thu"),
            (["fr", "fri"], "Fri"),
            (["sa", "sat"], "Sat"),
            (["su", "sun"], "Sun")
        ]

        var result: [DayHours] = []
        let components = hours.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }

        for component in components {
            let lowered = component.lowercased()

            // Handle day ranges like "Mo-Fr"
            if let rangeMatch = lowered.range(of: #"(mo|tu|we|th|fr|sa|su)-(mo|tu|we|th|fr|sa|su)"#, options: .regularExpression) {
                let range = String(lowered[rangeMatch])
                let parts = range.split(separator: "-")
                if parts.count == 2 {
                    let startDay = String(parts[0])
                    let endDay = String(parts[1])
                    let dayOrder = ["mo", "tu", "we", "th", "fr", "sa", "su"]
                    if let startIdx = dayOrder.firstIndex(of: startDay),
                       let endIdx = dayOrder.firstIndex(of: endDay) {
                        let time = extractTime(from: component)
                        for idx in startIdx...endIdx {
                            let fullDay = dayMap[idx].full
                            if !result.contains(where: { $0.day == fullDay }) {
                                result.append(DayHours(day: fullDay, time: time))
                            }
                        }
                        continue
                    }
                }
            }

            // Find individual days
            for (abbrevs, fullDay) in dayMap {
                if abbrevs.contains(where: { lowered.contains($0) }) {
                    let time = extractTime(from: component)
                    if !result.contains(where: { $0.day == fullDay }) {
                        result.append(DayHours(day: fullDay, time: time))
                    }
                }
            }
        }

        // Sort by day order
        let dayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        result.sort { dayOrder.firstIndex(of: $0.day) ?? 0 < dayOrder.firstIndex(of: $1.day) ?? 0 }

        return result
    }

    private func extractTime(from component: String) -> String {
        // Remove day parts and clean up
        var time = component
        let dayPatterns = ["mo-fr", "mo-su", "mo-sa", "sa-su", "mo", "tu", "we", "th", "fr", "sa", "su",
                          "mon-fri", "mon-sun", "mon-sat", "sat-sun", "mon", "tue", "wed", "thu", "fri", "sat", "sun"]

        for pattern in dayPatterns {
            time = time.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }

        time = time.trimmingCharacters(in: .whitespaces)

        if time.lowercased().contains("off") || time.lowercased().contains("closed") {
            return Strings.Places.hoursClosed
        }

        return time.isEmpty ? "-" : time
    }

    private func generateHoursSummary(_ hours: String) -> String? {
        let lowered = hours.lowercased()

        // Check for 24/7
        if lowered.contains("24/7") || lowered.contains("24h") {
            return Strings.Places.hoursOpen24h
        }

        // Try to extract a simple summary
        if let timeRange = hours.range(of: #"\d{1,2}:\d{2}\s*-\s*\d{1,2}:\d{2}"#, options: .regularExpression) {
            return String(hours[timeRange])
        }

        return nil
    }
}

// MARK: - Amenity Badge (kept for backwards compatibility)

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
        if lowered.contains("waste") { return "trash.fill" }
        if lowered.contains("bench") { return "chair.fill" }
        if lowered.contains("water") || lowered.contains("drinking") { return "drop.fill" }
        if lowered.contains("light") { return "lightbulb.fill" }
        if lowered.contains("emergency") || lowered.contains("24h") { return "cross.case.fill" }
        if lowered.contains("wheelchair") { return "figure.roll" }
        if lowered.contains("grooming") { return "scissors" }
        if lowered.contains("phone") { return "phone.fill" }
        if lowered.contains("outdoor") || lowered.contains("seating") { return "sun.max.fill" }
        if lowered.contains("wifi") { return "wifi" }
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
            amenities: [
                "waste bin",
                "bench",
                "water fountain",
                "Mo-Fr 08:00-20:00; Sa-Su 09:00-18:00",
                "+31 10 123 4567",
                "https://www.kralingse-bos.nl"
            ],
            isFenced: true,
            surface: "grass"
        ),
        spotStore: SpotStore()
    )
}
