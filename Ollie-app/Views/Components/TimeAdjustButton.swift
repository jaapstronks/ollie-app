//
//  TimeAdjustButton.swift
//  Ollie-app
//
//  Reusable time adjustment button for quick log sheets
//

import SwiftUI
import OllieShared

/// Button that adjusts a time by a specified number of minutes
struct TimeAdjustButton: View {
    let minutes: Int
    @Binding var selectedTime: Date
    var label: String?

    var body: some View {
        Button {
            HapticFeedback.light()
            if let newTime = Calendar.current.date(byAdding: .minute, value: minutes, to: selectedTime) {
                selectedTime = newTime
            }
        } label: {
            Text(label ?? Strings.PottyQuickLog.minutesAgo(minutes))
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.TimeAdjust.accessibilityLabel(abs(minutes)))
        .accessibilityHint(Strings.TimeAdjust.accessibilityHint)
        .accessibilityIdentifier("TIME_ADJUST_\(abs(minutes))")
    }
}

#Preview {
    @Previewable @State var time = Date()

    HStack(spacing: 10) {
        TimeAdjustButton(minutes: -5, selectedTime: $time)
        TimeAdjustButton(minutes: -10, selectedTime: $time)
        TimeAdjustButton(minutes: -15, selectedTime: $time)
        TimeAdjustButton(minutes: -30, selectedTime: $time)
    }
    .padding()
}
