//
//  WalkLogSheet.swift
//  Ollie-app
//
//  Sheet for logging a walk with optional potty events

import SwiftUI
import OllieShared

/// Sheet for logging a completed walk with optional pee/poop
struct WalkLogSheet: View {
    let onSave: (Date, Int, Bool, Bool, WalkSpot?, String?) -> Void
    let onCancel: () -> Void
    var spotStore: SpotStore?
    var locationManager: LocationManager?

    @State private var startTime = Date()
    @State private var durationMinutes = 15
    @State private var didPee = false
    @State private var didPoop = false
    @State private var selectedSpot: WalkSpot?
    @State private var note = ""
    @State private var showSpotPicker = false

    private let durationOptions = [5, 10, 15, 20, 30, 45, 60, 90]

    // Time presets: how many minutes ago
    private let timePresets = [
        (label: "Now", minutes: 0),
        (label: "5 min", minutes: 5),
        (label: "10 min", minutes: 10),
        (label: "15 min", minutes: 15),
        (label: "30 min", minutes: 30)
    ]

    var body: some View {
        NavigationView {
            Form {
                // Time section
                Section {
                    DatePicker(
                        Strings.WalkLog.startTime,
                        selection: $startTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    // Quick time presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(timePresets, id: \.minutes) { preset in
                                Button {
                                    startTime = Date().addingTimeInterval(-Double(preset.minutes) * 60)
                                } label: {
                                    Text(preset.label)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isTimePresetSelected(preset.minutes) ? Color.ollieAccent : Color(.tertiarySystemBackground))
                                        .foregroundColor(isTimePresetSelected(preset.minutes) ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Duration section
                Section {
                    Picker(Strings.WalkLog.duration, selection: $durationMinutes) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text(Strings.WalkLog.durationMinutes(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Potty section
                Section(header: Text(Strings.WalkLog.pottyDuringWalk)) {
                    HStack(spacing: 16) {
                        pottyToggle(
                            isOn: $didPee,
                            label: Strings.WalkLog.pee,
                            icon: "drop.fill",
                            color: .ollieInfo
                        )

                        pottyToggle(
                            isOn: $didPoop,
                            label: Strings.WalkLog.poop,
                            icon: "circle.inset.filled",
                            color: .ollieWarning
                        )

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                // Location section
                Section {
                    Button {
                        showSpotPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.ollieAccent)

                            if let spot = selectedSpot {
                                Text(spot.name)
                                    .foregroundColor(.primary)
                            } else {
                                Text(Strings.WalkLog.pickSpot)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Note section
                Section {
                    TextField(Strings.WalkLog.notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(Strings.WalkLog.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.WalkLog.logWalk) {
                        onSave(
                            startTime,
                            durationMinutes,
                            didPee,
                            didPoop,
                            selectedSpot,
                            note.isEmpty ? nil : note
                        )
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSpotPicker) {
                if let store = spotStore, let locManager = locationManager {
                    SpotPickerSheet(
                        spotStore: store,
                        locationManager: locManager,
                        onSelect: { spot in
                            selectedSpot = spot
                            showSpotPicker = false
                        },
                        onCancel: {
                            showSpotPicker = false
                        }
                    )
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func pottyToggle(isOn: Binding<Bool>, label: String, icon: String, color: Color) -> some View {
        Button {
            isOn.wrappedValue.toggle()
            HapticFeedback.selection()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isOn.wrappedValue ? color.opacity(0.2) : Color(.tertiarySystemBackground))
            .foregroundColor(isOn.wrappedValue ? color : .secondary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isOn.wrappedValue ? color : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isOn.wrappedValue ? [.isSelected] : [])
    }

    // MARK: - Helpers

    private func isTimePresetSelected(_ minutesAgo: Int) -> Bool {
        let presetTime = Date().addingTimeInterval(-Double(minutesAgo) * 60)
        // Consider it "selected" if within 30 seconds of the preset
        return abs(startTime.timeIntervalSince(presetTime)) < 30
    }
}

// MARK: - Preview

#Preview {
    WalkLogSheet(
        onSave: { time, duration, pee, poop, spot, note in
            print("Walk: \(time), \(duration)min, pee:\(pee), poop:\(poop)")
        },
        onCancel: { }
    )
}
