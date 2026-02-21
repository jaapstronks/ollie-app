//
//  QuickLogSheet.swift
//  Ollie-app
//
//  V2: Unified logging sheet with time adjustment for all events

import SwiftUI

/// Sheet for quick logging with time adjustment
struct QuickLogSheet: View {
    let eventType: EventType
    let onSave: (Date, EventLocation?, String?) -> Void
    let onCancel: () -> Void

    @State private var selectedTime: Date = Date()
    @State private var selectedLocation: EventLocation?
    @State private var note: String = ""
    @State private var showingTimePicker: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                EventIcon(type: eventType, size: 36)
                Text(eventType.label)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 8)

            // Time display and adjustment
            VStack(spacing: 12) {
                // Tappable time display
                Button {
                    showingTimePicker.toggle()
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(selectedTime.timeString)
                            .font(.title3)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                // Quick adjustment buttons
                HStack(spacing: 10) {
                    TimeAdjustButton(minutes: -5, selectedTime: $selectedTime)
                    TimeAdjustButton(minutes: -10, selectedTime: $selectedTime)
                    TimeAdjustButton(minutes: -15, selectedTime: $selectedTime)
                    TimeAdjustButton(minutes: -30, selectedTime: $selectedTime)
                }

                // Time picker (expandable)
                if showingTimePicker {
                    DatePicker(
                        Strings.QuickLogSheet.time,
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            // Location picker (for potty events only)
            if eventType.requiresLocation {
                VStack(spacing: 8) {
                    Text(Strings.QuickLogSheet.where_)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

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
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.QuickLogSheet.noteOptional)
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField(Strings.QuickLogSheet.notePlaceholder, text: $note)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(Strings.LogEvent.note)
                    .accessibilityHint(Strings.QuickLogSheet.noteAccessibilityHint)
            }
            .padding(.horizontal, 4)

            // Action buttons
            HStack(spacing: 16) {
                Button(Strings.Common.cancel) {
                    onCancel()
                }
                .foregroundColor(.secondary)

                Button {
                    HapticFeedback.success()
                    onSave(selectedTime, selectedLocation, note.isEmpty ? nil : note)
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text(Strings.Common.log)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? Color.accentColor : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!canSave)
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: showingTimePicker)
    }

    private var canSave: Bool {
        // Potty events require location
        if eventType.requiresLocation {
            return selectedLocation != nil
        }
        return true
    }
}

// MARK: - Supporting Views

struct TimeAdjustButton: View {
    let minutes: Int
    @Binding var selectedTime: Date

    var body: some View {
        Button {
            HapticFeedback.light()
            if let newTime = Calendar.current.date(byAdding: .minute, value: minutes, to: selectedTime) {
                selectedTime = newTime
            }
        } label: {
            Text("\(minutes) min")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct LocationToggleButton: View {
    let location: EventLocation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 6) {
                LocationIcon(location: location, size: 32)
                    .accessibilityHidden(true)

                Text(location.label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? location.iconColor : .primary)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? location.iconColor.opacity(0.15) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? location.iconColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.QuickLogSheet.locationAccessibility(location.label))
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isSelected ? Strings.QuickLogSheet.selected : "")
    }
}

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
