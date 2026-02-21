//
//  PottyQuickLogSheet.swift
//  Ollie-app
//
//  Combined sheet for logging plassen, poepen, or both

import SwiftUI

/// Selection options for potty events
enum PottySelection: String, CaseIterable {
    case plassen
    case poepen
    case beide

    var label: String {
        switch self {
        case .plassen: return Strings.PottyQuickLog.pee
        case .poepen: return Strings.PottyQuickLog.poop
        case .beide: return Strings.PottyQuickLog.both
        }
    }

    var iconName: String {
        switch self {
        case .plassen: return "drop.fill"
        case .poepen: return "circle.inset.filled"
        case .beide: return "drop.fill" // Combined handled separately
        }
    }

    var iconColor: Color {
        switch self {
        case .plassen: return .ollieInfo
        case .poepen: return .ollieWarning
        case .beide: return .ollieInfo
        }
    }
}

/// Sheet for quick logging potty events with plassen/poepen/both selection
struct PottyQuickLogSheet: View {
    let onSave: (PottySelection, Date, EventLocation, String?) -> Void
    let onCancel: () -> Void

    @State private var selectedPotty: PottySelection?
    @State private var selectedTime: Date = Date()
    @State private var selectedLocation: EventLocation?
    @State private var note: String = ""
    @State private var showingTimePicker: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                // Combined potty icon
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.ollieInfo)
                    Image(systemName: "circle.inset.filled")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.ollieWarning)
                }
                .frame(width: 44, height: 44)
                .background(Color.ollieInfo.opacity(0.1))
                .clipShape(Circle())

                Text(Strings.PottyQuickLog.toilet)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 8)

            // Potty type selection
            VStack(spacing: 8) {
                Text(Strings.PottyQuickLog.what)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    ForEach(PottySelection.allCases, id: \.self) { potty in
                        PottyToggleButton(
                            potty: potty,
                            isSelected: selectedPotty == potty,
                            action: { selectedPotty = potty }
                        )
                    }
                }
            }

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
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                // Quick adjustment buttons
                HStack(spacing: 10) {
                    PottyTimeAdjustButton(minutes: -5, selectedTime: $selectedTime)
                    PottyTimeAdjustButton(minutes: -10, selectedTime: $selectedTime)
                    PottyTimeAdjustButton(minutes: -15, selectedTime: $selectedTime)
                    PottyTimeAdjustButton(minutes: -30, selectedTime: $selectedTime)
                }

                // Time picker (expandable)
                if showingTimePicker {
                    DatePicker(
                        Strings.PottyQuickLog.time,
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            // Location picker
            VStack(spacing: 8) {
                Text(Strings.PottyQuickLog.where_)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    PottyLocationButton(
                        location: .buiten,
                        isSelected: selectedLocation == .buiten,
                        action: { selectedLocation = .buiten }
                    )

                    PottyLocationButton(
                        location: .binnen,
                        isSelected: selectedLocation == .binnen,
                        action: { selectedLocation = .binnen }
                    )
                }
            }

            // Note field
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.PottyQuickLog.noteOptional)
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField(Strings.PottyQuickLog.notePlaceholder, text: $note)
                    .textFieldStyle(.roundedBorder)
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
                    guard let potty = selectedPotty, let location = selectedLocation else { return }
                    onSave(potty, selectedTime, location, note.isEmpty ? nil : note)
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
        selectedPotty != nil && selectedLocation != nil
    }
}

// MARK: - Supporting Views

struct PottyToggleButton: View {
    let potty: PottySelection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 6) {
                pottyIcon
                    .frame(width: 36, height: 36)

                Text(potty.label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? potty.iconColor : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? potty.iconColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? potty.iconColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var pottyIcon: some View {
        switch potty {
        case .plassen:
            Image(systemName: "drop.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(isSelected ? Color.ollieInfo : .primary)
        case .poepen:
            Image(systemName: "circle.inset.filled")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? Color.ollieWarning : .primary)
        case .beide:
            HStack(spacing: 3) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.ollieInfo : .primary)
                Image(systemName: "circle.inset.filled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.ollieWarning : .primary)
            }
        }
    }
}

struct PottyTimeAdjustButton: View {
    let minutes: Int
    @Binding var selectedTime: Date

    var body: some View {
        Button {
            HapticFeedback.light()
            if let newTime = Calendar.current.date(byAdding: .minute, value: minutes, to: selectedTime) {
                selectedTime = newTime
            }
        } label: {
            Text(Strings.PottyQuickLog.minutesAgo(minutes))
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct PottyLocationButton: View {
    let location: EventLocation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: location == .buiten ? "sun.max.fill" : "house.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? iconColor : .primary)

                Text(location.label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? iconColor : .primary)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? iconColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? iconColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconColor: Color {
        location == .buiten ? .ollieSuccess : .ollieWarning
    }
}

#Preview {
    PottyQuickLogSheet(
        onSave: { potty, time, location, note in
            print("Save: \(potty), \(time), \(location), \(note ?? "")")
        },
        onCancel: {}
    )
}
