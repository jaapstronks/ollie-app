//
//  PhotoPinDetailCard.swift
//  Ollie-app
//
//  Rich detail card for photo pins on the map, showing context and metadata
//

import SwiftUI
import OllieShared

/// Rich detail card showing photo context when tapping a map pin
struct PhotoPinDetailCard: View {
    let cluster: PhotoCluster
    let spots: [WalkSpot]
    let onSelectPhoto: (PuppyEvent) -> Void
    let onSaveSpot: ((Double, Double) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // Check if location is near any saved spot
    private func nearbySpot(for event: PuppyEvent) -> WalkSpot? {
        guard let lat = event.latitude, let lon = event.longitude else { return nil }

        for spot in spots {
            let distance = haversineDistance(
                lat1: lat, lon1: lon,
                lat2: spot.latitude, lon2: spot.longitude
            )
            if distance <= 100 { // Within 100 meters
                return spot
            }
        }
        return nil
    }

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius: Double = 6371000 // meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }

    var body: some View {
        NavigationStack {
            Group {
                if cluster.isSinglePhoto, let event = cluster.firstEvent {
                    // Single photo - show rich detail
                    singlePhotoView(event: event)
                } else {
                    // Multiple photos - show grid
                    multiPhotoView
                }
            }
            .navigationTitle(cluster.isSinglePhoto ? Strings.PhotoPin.moment : Strings.Places.filterPhotos)
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

    // MARK: - Single Photo View

    @ViewBuilder
    private func singlePhotoView(event: PuppyEvent) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Photo with tap to open full screen
                PhotoThumbnailLarge(event: event)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        onSelectPhoto(event)
                    }
                    .padding(.horizontal)

                // Metadata card
                VStack(alignment: .leading, spacing: 12) {
                    // Date and event type
                    HStack {
                        // Date
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.time, format: .dateTime.month().day().year())
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(event.time, format: .dateTime.hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Event type badge
                        EventTypeBadge(eventType: event.type, isMilestone: event.type == .milestone)
                    }

                    // Note (if present)
                    if let note = event.note, !note.isEmpty {
                        Divider()
                        Text(note)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    Divider()

                    // Location info
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.red)

                        if let spot = nearbySpot(for: event) {
                            Text(spot.name)
                                .font(.subheadline)
                        } else if let spotName = event.spotName, !spotName.isEmpty {
                            Text(spotName)
                                .font(.subheadline)
                        } else {
                            Text(Strings.PhotoPin.unknownLocation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    // Save spot button (if not near existing spot)
                    if nearbySpot(for: event) == nil,
                       let lat = event.latitude,
                       let lon = event.longitude,
                       let onSaveSpot = onSaveSpot {
                        Button {
                            onSaveSpot(lat, lon)
                            dismiss()
                        } label: {
                            Label(Strings.PhotoPin.saveThisSpot, systemImage: "mappin.and.ellipse")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.ollieAccent)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Multi Photo View

    private var multiPhotoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with photo count
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(.pink)
                    Text(Strings.Places.photoCount(cluster.count))
                        .font(.headline)

                    // Show milestone indicator if any milestone photos
                    if cluster.hasMilestonePhoto {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)

                // Photo grid
                let columns = [
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4)
                ]

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(cluster.events) { event in
                        ZStack(alignment: .topTrailing) {
                            GalleryThumbnail(event: event)
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    onSelectPhoto(event)
                                }

                            // Milestone badge
                            if event.type == .milestone {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                                    .padding(4)
                                    .background(Circle().fill(.black.opacity(0.5)))
                                    .padding(4)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Supporting Views

/// Large photo thumbnail with loading state
struct PhotoThumbnailLarge: View {
    let event: PuppyEvent
    @State private var image: UIImage?

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .aspectRatio(4/3, contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .task {
            loadImage()
        }
    }

    private func loadImage() {
        // Load full photo (not thumbnail) for detail view
        guard let path = event.photo else { return }
        let url = documentsURL.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url),
              let loaded = UIImage(data: data) else { return }
        image = loaded
    }
}

/// Badge showing event type with optional milestone styling
struct EventTypeBadge: View {
    let eventType: EventType
    let isMilestone: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: eventType.icon)
                .font(.caption)
            Text(eventType.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isMilestone ? Color.yellow.opacity(0.2) : Color(.tertiarySystemBackground))
        )
        .foregroundStyle(isMilestone ? .yellow : .secondary)
        .overlay {
            if isMilestone {
                Capsule()
                    .stroke(Color.yellow, lineWidth: 1)
            }
        }
    }
}

// MARK: - Preview

#Preview("Single Photo") {
    PhotoPinDetailCard(
        cluster: PhotoCluster(
            id: UUID(),
            latitude: 51.9225,
            longitude: 4.4792,
            events: [
                PuppyEvent(
                    type: .moment,
                    note: "Beautiful walk in the park today!"
                )
            ]
        ),
        spots: [],
        onSelectPhoto: { _ in },
        onSaveSpot: nil
    )
}

#Preview("Multiple Photos") {
    PhotoPinDetailCard(
        cluster: PhotoCluster(
            id: UUID(),
            latitude: 51.9225,
            longitude: 4.4792,
            events: [
                PuppyEvent(type: .moment),
                PuppyEvent(type: .milestone),
                PuppyEvent(type: .sociaal)
            ]
        ),
        spots: [],
        onSelectPhoto: { _ in },
        onSaveSpot: nil
    )
}
