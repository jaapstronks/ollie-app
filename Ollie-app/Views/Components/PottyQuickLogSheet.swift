//
//  PottyQuickLogSheet.swift
//  Otis-app
//
//  Combined sheet for logging plassen, poepen, or both

import SwiftUI
import OtisShared

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
        case .plassen: return .otisInfo
        case .poepen: return .otisWarning
        case .beide: return .otisInfo
        }
    }
}

/// Sheet for quick logging potty events with plassen/poepen/both selection
struct PottyQuickLogSheet: View {
    let onSave: (PottySelection, Date, EventLocation, String?) -> Void
    let onCancel: () -> Void
    let preselected: PottySelection?

    @State private var selectedPotty: PottySelection?
    @State private var selectedTime: Date = Date()
    @State private var selectedLocation: EventLocation?
    @State private var note: String = ""
    @State private var showingTimePicker: Bool = false

    init(
        onSave: @escaping (PottySelection, Date, EventLocation, String?) -> Void,
        onCancel: @escaping () -> Void,
        preselected: PottySelection? = nil
    ) {
        self.onSave = onSave
        self.onCancel = onCancel
        self.preselected = preselected
        self._selectedPotty = State(initialValue: preselected)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    SheetHeader(
                        title: Strings.PottyQuickLog.toilet,
                        icon: .combined(
                            primary: "drop.fill",
                            secondary: "circle.inset.filled",
                            primaryColor: .otisInfo,
                            secondaryColor: .otisWarning
                        )
                    )

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
                    TimePickerSection(
                        selectedTime: $selectedTime,
                        showingTimePicker: $showingTimePicker,
                        accessibilityLabel: Strings.PottyQuickLog.timeAccessibility(selectedTime.timeString),
                        accessibilityHint: Strings.PottyQuickLog.timeAccessibilityHint,
                        accessibilityIdentifier: "POTTY_TIME_PICKER"
                    )

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
                    LogSheetNoteField(
                        note: $note,
                        label: Strings.PottyQuickLog.noteOptional,
                        placeholder: Strings.PottyQuickLog.notePlaceholder,
                        accessibilityIdentifier: "POTTY_NOTE_FIELD"
                    )
                }
                .padding([.horizontal, .top])
                .padding(.bottom, 8)
            }

            // Action buttons - pinned at bottom
            LogSheetActionButtons(
                canSave: canSave,
                onCancel: onCancel,
                onSave: {
                    guard let potty = selectedPotty, let location = selectedLocation else { return }
                    onSave(potty, selectedTime, location, note.nilIfBlank)
                },
                cancelAccessibilityIdentifier: "POTTY_CANCEL_BUTTON",
                saveAccessibilityIdentifier: "POTTY_LOG_BUTTON"
            )
            .padding()
        }
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
            .cornerRadius(LayoutConstants.cornerRadiusM)
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
                .foregroundStyle(isSelected ? Color.otisInfo : .primary)
        case .poepen:
            Image(systemName: "circle.inset.filled")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? Color.otisWarning : .primary)
        case .beide:
            HStack(spacing: 3) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.otisInfo : .primary)
                Image(systemName: "circle.inset.filled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.otisWarning : .primary)
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
