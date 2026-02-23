//
//  PottyQuickLogSheet.swift
//  Ollie-app
//
//  Combined sheet for logging plassen, poepen, or both

import SwiftUI
import OllieShared

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
                .accessibilityHidden(true)

                Text(Strings.PottyQuickLog.toilet)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)

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
                            .accessibilityHidden(true)
                        Text(selectedTime.timeString)
                            .font(.title3)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.PottyQuickLog.timeAccessibility(selectedTime.timeString))
                .accessibilityHint(Strings.PottyQuickLog.timeAccessibilityHint)
                .accessibilityIdentifier("POTTY_TIME_PICKER")

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
                    LocationSelectionButton(
                        location: .buiten,
                        isSelected: selectedLocation == .buiten,
                        action: { selectedLocation = .buiten }
                    )

                    LocationSelectionButton(
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
                    .accessibilityLabel(Strings.PottyQuickLog.noteOptional)
                    .accessibilityHint(Strings.QuickLogSheet.noteAccessibilityHint)
                    .accessibilityIdentifier("POTTY_NOTE_FIELD")
            }
            .padding(.horizontal, 4)

            // Action buttons
            HStack(spacing: 16) {
                Button(Strings.Common.cancel) {
                    onCancel()
                }
                .foregroundColor(.secondary)
                .accessibilityIdentifier("POTTY_CANCEL_BUTTON")

                Button {
                    HapticFeedback.success()
                    guard let potty = selectedPotty, let location = selectedLocation else { return }
                    onSave(potty, selectedTime, location, note.isEmpty ? nil : note)
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
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
                .accessibilityLabel(Strings.PottyQuickLog.logAccessibility)
                .accessibilityHint(canSave ? Strings.PottyQuickLog.logAccessibilityHint : Strings.PottyQuickLog.selectRequiredFields)
                .accessibilityIdentifier("POTTY_LOG_BUTTON")
            }
        }
        .padding()
        .modifier(ReduceMotionAnimation(value: showingTimePicker))
    }

    private var canSave: Bool {
        selectedPotty != nil && selectedLocation != nil
    }
}

// MARK: - Reduce Motion Support

/// Animation modifier that respects reduce motion setting
private struct ReduceMotionAnimation<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: value)
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
                    .accessibilityHidden(true)

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
        .accessibilityLabel(potty.label)
        .accessibilityHint(Strings.PottyQuickLog.pottyTypeHint(potty.label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("POTTY_TYPE_\(potty.rawValue.uppercased())")
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


#Preview {
    PottyQuickLogSheet(
        onSave: { potty, time, location, note in
            print("Save: \(potty), \(time), \(location), \(note ?? "")")
        },
        onCancel: {}
    )
}
