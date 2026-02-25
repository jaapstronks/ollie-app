//
//  TimePickerSection.swift
//  Ollie-app
//
//  Reusable time picker section with tappable display, quick adjustments, and expandable picker
//

import SwiftUI
import OllieShared

/// A reusable time picker section that includes:
/// - A tappable time display button
/// - Quick adjustment buttons (-5, -10, -15, -30 minutes)
/// - An expandable DatePicker
struct TimePickerSection: View {
    @Binding var selectedTime: Date
    @Binding var showingTimePicker: Bool

    /// Optional accessibility label for the time button
    var accessibilityLabel: String?
    /// Optional accessibility hint for the time button
    var accessibilityHint: String?
    /// Optional accessibility identifier for the time button
    var accessibilityIdentifier: String?

    var body: some View {
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
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel ?? Strings.QuickLogSheet.time)
            .accessibilityHint(accessibilityHint ?? Strings.QuickLogSheet.timeHint)
            .modifier(OptionalAccessibilityIdentifier(identifier: accessibilityIdentifier))

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
    }
}

/// Helper modifier to conditionally apply accessibility identifier
private struct OptionalAccessibilityIdentifier: ViewModifier {
    let identifier: String?

    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var time = Date()
    @Previewable @State var showingPicker = false

    VStack {
        TimePickerSection(
            selectedTime: $time,
            showingTimePicker: $showingPicker,
            accessibilityIdentifier: "PREVIEW_TIME_PICKER"
        )
    }
    .padding()
}
