//
//  SpotDetailView.swift
//  Ollie-app
//
//  Full-screen detail view for a walk spot with inline editing

import SwiftUI
import OllieShared
import MapKit

/// Full detail view for viewing and editing a walk spot
struct SpotDetailView: View {
    @ObservedObject var spotStore: SpotStore
    var momentsViewModel: MomentsViewModel?
    let spot: WalkSpot

    @Environment(\.dismiss) private var dismiss

    @State private var editedName: String
    @State private var editedNotes: String
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedPhotoEvent: PuppyEvent?
    @State private var placeStats: PlaceStats?

    /// Full initializer with photo support
    init(spotStore: SpotStore, spot: WalkSpot, momentsViewModel: MomentsViewModel) {
        self.spotStore = spotStore
        self.spot = spot
        self.momentsViewModel = momentsViewModel
        _editedName = State(initialValue: spot.name)
        _editedNotes = State(initialValue: spot.notes ?? "")
    }

    /// Convenience initializer without photo support (for legacy usage)
    init(spotStore: SpotStore, spot: WalkSpot) {
        self.spotStore = spotStore
        self.spot = spot
        self.momentsViewModel = nil
        _editedName = State(initialValue: spot.name)
        _editedNotes = State(initialValue: spot.notes ?? "")
    }

    // Get the latest version of the spot from the store
    private var currentSpot: WalkSpot {
        spotStore.spot(withId: spot.id) ?? spot
    }

    // Photos taken near this spot
    private var photosHere: [PuppyEvent] {
        momentsViewModel?.photosAtSpot(currentSpot) ?? []
    }

    private let photoGridColumns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map preview
                SpotMapView(
                    latitude: currentSpot.latitude,
                    longitude: currentSpot.longitude,
                    spotName: currentSpot.name
                )
                .frame(height: 200)
                .padding(.horizontal)

                // Spot details card
                VStack(alignment: .leading, spacing: 16) {
                    // Name
                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.WalkLocations.nameThisSpot)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField(Strings.WalkLocations.spotNamePlaceholder, text: $editedName)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        Text(currentSpot.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    // Notes
                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.LogEvent.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField(Strings.LogEvent.notePlaceholder, text: $editedNotes)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else if let notes = currentSpot.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Stats row with photo count
                    HStack(spacing: 16) {
                        // Visit count
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.WalkLocations.visitCount(currentSpot.visitCount))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(Strings.SpotDetail.visits)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Photo count
                        if !photosHere.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(photosHere.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(Strings.SpotDetail.photos)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Created date
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(currentSpot.createdAt, format: .dateTime.month().day().year())
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(Strings.SpotDetail.created)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(LayoutConstants.cornerRadiusM)
                .padding(.horizontal)

                // Place stats section
                if let stats = placeStats, stats.hasStats {
                    placeStatsSection(stats: stats)
                }

                // Photos section
                if !photosHere.isEmpty {
                    photosSection
                }

                // Actions
                VStack(spacing: 12) {
                    // Favorite toggle
                    Button {
                        HapticFeedback.light()
                        spotStore.toggleFavorite(currentSpot)
                    } label: {
                        Label(
                            currentSpot.isFavorite
                                ? Strings.WalkLocations.removeFromFavorites
                                : Strings.WalkLocations.addToFavorites,
                            systemImage: currentSpot.isFavorite ? "star.fill" : "star"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(currentSpot.isFavorite ? .yellow : .primary)

                    // Open in Maps
                    Button {
                        openInMaps()
                    } label: {
                        Label(Strings.WalkLocations.openInMaps, systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)

                    // Delete
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(Strings.WalkLocations.deleteSpot, systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditing ? Strings.Common.edit : currentSpot.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? Strings.Common.save : Strings.Common.edit) {
                    if isEditing {
                        save()
                    }
                    withAnimation {
                        isEditing.toggle()
                    }
                }
                .disabled(isEditing && editedName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .confirmationDialog(
            Strings.WalkLocations.deleteSpot,
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Common.delete, role: .destructive) {
                delete()
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        } message: {
            Text(Strings.SpotDetail.deleteConfirmMessage)
        }
        .fullScreenCover(item: $selectedPhotoEvent) { event in
            MediaPreviewView(
                event: event,
                onDelete: {
                    momentsViewModel?.deleteEvent(event)
                    selectedPhotoEvent = nil
                }
            )
        }
        .task {
            // Load place stats asynchronously
            if let viewModel = momentsViewModel {
                placeStats = await viewModel.loadStatsForSpot(currentSpot)
            }
        }
    }

    // MARK: - Place Stats Section

    private func placeStatsSection(stats: PlaceStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.ollieAccent)
                Text(Strings.SpotDetail.placeStats)
                    .font(.headline)
            }
            .padding(.horizontal)

            // Stats grid
            HStack(spacing: 16) {
                // First visited
                if let firstVisited = stats.firstVisited {
                    statItem(
                        value: firstVisited.formatted(.dateTime.month(.abbreviated).day()),
                        label: Strings.SpotDetail.firstVisited,
                        icon: "calendar",
                        color: .blue
                    )
                }

                // Dogs met
                if stats.dogsMetCount > 0 {
                    statItem(
                        value: "\(stats.dogsMetCount)",
                        label: Strings.SpotDetail.dogsMet,
                        icon: "dog.fill",
                        color: .orange
                    )
                }

                // Potty successes
                if stats.pottySuccessCount > 0 {
                    statItem(
                        value: "\(stats.pottySuccessCount)",
                        label: Strings.SpotDetail.pottySuccesses,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(LayoutConstants.cornerRadiusM)
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundStyle(.pink)
                Text(Strings.SpotDetail.photosHere)
                    .font(.headline)

                Spacer()

                if photosHere.count > 8 {
                    Text(Strings.Places.photoCount(photosHere.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // Photo grid (show up to 8 photos)
            LazyVGrid(columns: photoGridColumns, spacing: 4) {
                ForEach(photosHere.prefix(8)) { event in
                    GalleryThumbnail(event: event)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            selectedPhotoEvent = event
                        }
                }
            }
            .padding(.horizontal)

            // Empty state hint
            if photosHere.isEmpty {
                Text(Strings.SpotDetail.noPhotosHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    private func save() {
        guard var updated = spotStore.spot(withId: spot.id) else { return }
        updated.name = editedName.trimmingCharacters(in: .whitespaces)
        updated.notes = editedNotes.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil
            : editedNotes.trimmingCharacters(in: .whitespaces)
        spotStore.updateSpot(updated)
        HapticFeedback.success()
    }

    private func delete() {
        spotStore.deleteSpot(currentSpot)
        HapticFeedback.warning()
        dismiss()
    }

    private func openInMaps() {
        let location = CLLocation(
            latitude: currentSpot.latitude,
            longitude: currentSpot.longitude
        )
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = currentSpot.name
        mapItem.openInMaps()
    }
}

#Preview("With Photos") {
    let eventStore = EventStore()
    let momentsViewModel = MomentsViewModel(eventStore: eventStore)

    return NavigationStack {
        SpotDetailView(
            spotStore: SpotStore(),
            spot: WalkSpot(
                name: "Kralingse Bos",
                latitude: 51.9225,
                longitude: 4.4792,
                isFavorite: true,
                notes: "Great park with lots of trails",
                visitCount: 15
            ),
            momentsViewModel: momentsViewModel
        )
    }
}

#Preview("Without Photos") {
    NavigationStack {
        SpotDetailView(
            spotStore: SpotStore(),
            spot: WalkSpot(
                name: "Kralingse Bos",
                latitude: 51.9225,
                longitude: 4.4792,
                isFavorite: true,
                notes: "Great park with lots of trails",
                visitCount: 15
            )
        )
    }
}
