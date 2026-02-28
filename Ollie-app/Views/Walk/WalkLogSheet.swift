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

    /// Default duration in minutes (15 for walks)
    var defaultDurationMinutes: Int = 15

    private let now = Date()

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var didPee = false
    @State private var didPoop = false
    @State private var selectedSpot: WalkSpot?
    @State private var note = ""
    @State private var showSpotPicker = false

    /// Computed duration in minutes
    private var durationMinutes: Int {
        max(1, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    init(
        onSave: @escaping (Date, Int, Bool, Bool, WalkSpot?, String?) -> Void,
        onCancel: @escaping () -> Void,
        spotStore: SpotStore? = nil,
        locationManager: LocationManager? = nil,
        defaultDurationMinutes: Int = 15
    ) {
        self.onSave = onSave
        self.onCancel = onCancel
        self.spotStore = spotStore
        self.locationManager = locationManager
        self.defaultDurationMinutes = defaultDurationMinutes

        // Calculate defaults: end time = now, start = end - duration
        let defaultEndTime = Date()
        let defaultStartTime = defaultEndTime.addingTimeInterval(-Double(defaultDurationMinutes) * 60)

        _startTime = State(initialValue: defaultStartTime)
        _endTime = State(initialValue: defaultEndTime)
    }

    var body: some View {
        NavigationView {
            Form {
                // Time section with linked start/end/duration
                Section {
                    DurationTimePicker(
                        startTime: $startTime,
                        endTime: $endTime,
                        accentColor: .green,
                        maxEndTime: now
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
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
                    Button {
                        onSave(
                            startTime,
                            durationMinutes,
                            didPee,
                            didPoop,
                            selectedSpot,
                            note.isEmpty ? nil : note
                        )
                    } label: {
                        Text(Strings.WalkLog.logWalk)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.ollieAccent)
                            .clipShape(Capsule())
                    }
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
