//
//  QuickLogSheet.swift
//  Otis-app
//
//  V2: Unified logging sheet with time adjustment for all events
//  V3: Added walk location support

import SwiftUI
import OtisShared
import CoreLocation

/// Sheet for quick logging with time adjustment
struct QuickLogSheet: View {
    let eventType: EventType
    let onSave: (Date, EventLocation?, String?) -> Void
    let onCancel: () -> Void

    // Optional suggested time (e.g., for overdue meals - use scheduled time as default)
    var suggestedTime: Date?

    // Optional walk location support
    var spotStore: SpotStore?
    var locationManager: LocationManager?
    var onSaveWalk: ((Date, WalkSpot?, Double?, Double?, String?) -> Void)?

    @State private var selectedTime: Date = Date()
    @State private var hasInitializedTime: Bool = false
    @State private var selectedLocation: EventLocation?
    @State private var note: String = ""
    @State private var showingTimePicker: Bool = false

    // Walk location state
    @State private var selectedSpot: WalkSpot?
    @State private var capturedLatitude: Double?
    @State private var capturedLongitude: Double?
    @State private var showingSpotPicker = false
    @State private var isCapturingLocation = false
    @State private var newSpotName = ""
    @State private var showingSpotNameInput = false

    private var isWalkEvent: Bool {
        eventType == .uitlaten && spotStore != nil && locationManager != nil
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            SheetHeader(
                title: eventType.label,
                icon: .eventType(eventType)
            )

            // Time display and adjustment
            TimePickerSection(
                selectedTime: $selectedTime,
                showingTimePicker: $showingTimePicker
            )

            // Walk location section (for walk events)
            if isWalkEvent {
                walkLocationSection
            }

            // Location picker (for potty events only)
            if eventType.requiresLocation {
                VStack(spacing: 8) {
                    Text(Strings.QuickLogSheet.where_)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        LocationToggleButton(
                            location: .buiten,
                            isSelected: selectedLocation == .buiten,
                            action: { selectedLocation = .buiten }
                        )

                        LocationToggleButton(
                            location: .binnen,
                            isSelected: selectedLocation == .binnen,
                            action: { selectedLocation = .binnen }
                        )
                    }
                }
            }

            // Note field
            LogSheetNoteField(
                note: $note,
                accessibilityIdentifier: "QUICK_LOG_NOTE_FIELD"
            )

            // Action buttons
            LogSheetActionButtons(
                canSave: canSave,
                onCancel: onCancel,
                onSave: saveEvent,
                cancelAccessibilityIdentifier: "QUICK_LOG_CANCEL_BUTTON",
                saveAccessibilityIdentifier: "QUICK_LOG_SAVE_BUTTON"
            )
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: showingTimePicker)
        .animation(.easeInOut(duration: 0.2), value: showingSpotNameInput)
        .onAppear {
            // Initialize time from suggested time (e.g., for overdue meals)
            if !hasInitializedTime {
                selectedTime = suggestedTime ?? Date()
                hasInitializedTime = true
            }
        }
        .sheet(isPresented: $showingSpotPicker) {
            if let store = spotStore, let locMgr = locationManager {
                SpotPickerSheet(
                    spotStore: store,
                    locationManager: locMgr,
                    onSelect: { spot in
                        selectedSpot = spot
                        capturedLatitude = spot.latitude
                        capturedLongitude = spot.longitude
                        showingSpotPicker = false
                    },
                    onCancel: {
                        showingSpotPicker = false
                    }
                )
            }
        }
    }

    // MARK: - Walk Location Section

    @ViewBuilder
    private var walkLocationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Strings.WalkLocations.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Strings.WalkLocations.optional)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if showingSpotNameInput, let lat = capturedLatitude, let lon = capturedLongitude {
                // Name input for new spot
                VStack(spacing: 10) {
                    SpotMapView(latitude: lat, longitude: lon)
                        .frame(height: 80)

                    TextField(Strings.WalkLocations.spotNamePlaceholder, text: $newSpotName)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button(Strings.Common.cancel) {
                            showingSpotNameInput = false
                            capturedLatitude = nil
                            capturedLongitude = nil
                            newSpotName = ""
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            saveNewSpot()
                        } label: {
                            Text(Strings.WalkLocations.saveSpot)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .disabled(newSpotName.isBlank)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(LayoutConstants.cornerRadiusM)
            } else if let spot = selectedSpot {
                // Selected spot display
                HStack {
                    SpotMapView(latitude: spot.latitude, longitude: spot.longitude, spotName: spot.name)
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)

                    Button {
                        selectedSpot = nil
                        capturedLatitude = nil
                        capturedLongitude = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // Location buttons
                HStack(spacing: 12) {
                    // "Here" button
                    Button {
                        captureHereLocation()
                    } label: {
                        HStack {
                            if isCapturingLocation {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "location.fill")
                            }
                            Text(Strings.WalkLocations.here)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCapturingLocation)

                    // "Saved spots" button
                    Button {
                        showingSpotPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                            Text(Strings.WalkLocations.savedSpots)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Actions

    private var canSave: Bool {
        // Potty events require location
        if eventType.requiresLocation {
            return selectedLocation != nil
        }
        return true
    }

    private func saveEvent() {
        if isWalkEvent, let onSaveWalkCallback = onSaveWalk {
            // Walk event with location support
            onSaveWalkCallback(selectedTime, selectedSpot, capturedLatitude, capturedLongitude, note.nilIfBlank)
        } else {
            // Regular event
            onSave(selectedTime, selectedLocation, note.nilIfBlank)
        }
    }

    private func captureHereLocation() {
        guard let locMgr = locationManager else { return }

        isCapturingLocation = true

        Task {
            do {
                let location = try await locMgr.requestLocation()
                capturedLatitude = location.coordinate.latitude
                capturedLongitude = location.coordinate.longitude
                showingSpotNameInput = true
                HapticFeedback.success()
            } catch {
                HapticFeedback.error()
            }
            isCapturingLocation = false
        }
    }

    private func saveNewSpot() {
        guard let store = spotStore,
              let lat = capturedLatitude,
              let lon = capturedLongitude,
              let name = newSpotName.nilIfBlank else { return }

        let spot = store.addSpot(name: name, latitude: lat, longitude: lon)
        selectedSpot = spot
        showingSpotNameInput = false
        newSpotName = ""
        HapticFeedback.success()
    }
}

// MARK: - Type Aliases for Backwards Compatibility

/// Type alias pointing to shared component
private typealias LocationToggleButton = LocationSelectionButton

#Preview {
    QuickLogSheet(
        eventType: .plassen,
        onSave: { time, location, note in
            print("Save: \(time), \(location?.rawValue ?? "none"), \(note ?? "")")
        },
        onCancel: {}
    )
}

#Preview("Non-potty") {
    QuickLogSheet(
        eventType: .eten,
        onSave: { time, location, note in
            print("Save: \(time), \(location?.rawValue ?? "none"), \(note ?? "")")
        },
        onCancel: {}
    )
}

#Preview("Walk with location") {
    QuickLogSheet(
        eventType: .uitlaten,
        onSave: { _, _, _ in },
        onCancel: {},
        spotStore: SpotStore(),
        locationManager: LocationManager(),
        onSaveWalk: { time, spot, lat, lon, note in
            print("Walk: \(time), spot: \(spot?.name ?? "none"), lat: \(lat ?? 0), note: \(note ?? "")")
        }
    )
}
