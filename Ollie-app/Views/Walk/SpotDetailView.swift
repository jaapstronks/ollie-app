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
    let spot: WalkSpot

    @Environment(\.dismiss) private var dismiss

    @State private var editedName: String
    @State private var editedNotes: String
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false

    init(spotStore: SpotStore, spot: WalkSpot) {
        self.spotStore = spotStore
        self.spot = spot
        _editedName = State(initialValue: spot.name)
        _editedNotes = State(initialValue: spot.notes ?? "")
    }

    // Get the latest version of the spot from the store
    private var currentSpot: WalkSpot {
        spotStore.spot(withId: spot.id) ?? spot
    }

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

                    // Stats
                    HStack(spacing: 24) {
                        // Visit count
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.WalkLocations.visitCount(currentSpot.visitCount))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(Strings.SpotDetail.visits)
                                .font(.caption)
                                .foregroundStyle(.secondary)
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

#Preview {
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
