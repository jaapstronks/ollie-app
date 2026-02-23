//
//  EditWalkSheet.swift
//  Ollie-app
//
//  Sheet for editing an existing walk event

import SwiftUI
import OllieShared

/// Sheet for editing a walk event's details
struct EditWalkSheet: View {
    let walk: PuppyEvent
    let spotStore: SpotStore
    let onSave: (PuppyEvent) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime: Date
    @State private var durationMinutes: String
    @State private var selectedSpot: WalkSpot?
    @State private var note: String
    @State private var showingDeleteConfirmation = false

    init(
        walk: PuppyEvent,
        spotStore: SpotStore,
        onSave: @escaping (PuppyEvent) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.walk = walk
        self.spotStore = spotStore
        self.onSave = onSave
        self.onDelete = onDelete

        _selectedTime = State(initialValue: walk.time)
        _durationMinutes = State(initialValue: walk.durationMin.map { String($0) } ?? "")
        _note = State(initialValue: walk.note ?? "")

        // Find matching spot if walk has spotId
        if let spotId = walk.spotId {
            _selectedSpot = State(initialValue: spotStore.spot(withId: spotId))
        } else {
            _selectedSpot = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Event info header
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.walk")
                            .font(.title)
                            .foregroundStyle(Color.ollieAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.ollieAccent.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.EventType.walk)
                                .font(.headline)
                            Text(walk.time, format: .dateTime.weekday().month().day())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Time
                Section(Strings.QuickLogSheet.time) {
                    DatePicker(
                        Strings.QuickLogSheet.time,
                        selection: $selectedTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .labelsHidden()
                }

                // Duration
                Section(Strings.LogEvent.duration) {
                    HStack {
                        TextField(Strings.Common.minutesFull, text: $durationMinutes)
                            .keyboardType(.numberPad)
                        Text(Strings.Common.minutes)
                            .foregroundStyle(.secondary)
                    }
                }

                // Spot
                Section(Strings.WalkLocations.walkLocation) {
                    if let spot = selectedSpot {
                        HStack {
                            Image(systemName: spot.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                                .foregroundStyle(spot.isFavorite ? .yellow : .ollieAccent)
                            Text(spot.name)
                            Spacer()
                            Button(Strings.EditWalk.changeSpot) {
                                selectedSpot = nil
                            }
                            .font(.caption)
                        }
                    } else if !spotStore.spots.isEmpty {
                        // Spot picker
                        ForEach(spotStore.favoriteSpots.prefix(3)) { spot in
                            Button {
                                selectedSpot = spot
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                    Text(spot.name)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }

                        ForEach(spotStore.recentSpots.prefix(2)) { spot in
                            Button {
                                selectedSpot = spot
                            } label: {
                                HStack {
                                    Image(systemName: "mappin")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                    Text(spot.name)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    } else {
                        Text(Strings.WalkLocations.noRecentSpots)
                            .foregroundStyle(.secondary)
                    }
                }

                // Note
                Section(Strings.LogEvent.note) {
                    TextField(Strings.LogEvent.notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Delete section
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label(Strings.EditWalk.deleteWalk, systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(Strings.EditWalk.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveChanges()
                    }
                }
            }
            .confirmationDialog(
                Strings.EditWalk.deleteWalk,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Common.delete, role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            } message: {
                Text(Strings.EditWalk.deleteConfirmMessage)
            }
        }
    }

    private func saveChanges() {
        var updatedWalk = walk
        updatedWalk.time = selectedTime
        updatedWalk.durationMin = Int(durationMinutes)
        updatedWalk.note = note.isEmpty ? nil : note
        updatedWalk.spotId = selectedSpot?.id
        updatedWalk.spotName = selectedSpot?.name
        updatedWalk.latitude = selectedSpot?.latitude
        updatedWalk.longitude = selectedSpot?.longitude

        HapticFeedback.success()
        onSave(updatedWalk)
        dismiss()
    }
}

#Preview {
    EditWalkSheet(
        walk: PuppyEvent(
            time: Date(),
            type: .uitlaten,
            note: "Morning walk",
            durationMin: 25
        ),
        spotStore: SpotStore(),
        onSave: { _ in },
        onDelete: {}
    )
}
