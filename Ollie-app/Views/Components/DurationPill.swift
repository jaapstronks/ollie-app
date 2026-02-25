//
//  DurationPill.swift
//  Ollie-app
//
//  Reusable duration pill component for session rows
//

import SwiftUI
import OllieShared

/// A capsule-shaped pill showing a duration
/// Used in session rows (sleep, walks) to display elapsed time
struct DurationPill: View {
    let text: String
    var color: Color = .secondary
    var isHighlighted: Bool = false

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(isHighlighted ? color : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isHighlighted
                    ? color.opacity(0.15)
                    : Color(.tertiarySystemBackground)
            )
            .clipShape(Capsule())
    }
}

/// Live-updating duration pill for ongoing activities
struct LiveDurationPill: View {
    let startTime: Date
    var color: Color = .ollieSleep

    var body: some View {
        SwiftUI.TimelineView(.periodic(from: Date(), by: 60)) { _ in
            DurationPill(
                text: formatLiveDuration(),
                color: color,
                isHighlighted: true
            )
        }
    }

    private func formatLiveDuration() -> String {
        let minutes = Date().minutesSince(startTime)
        return DurationFormatter.format(minutes, style: .compact)
    }
}

// MARK: - Preview

#Preview("Static Duration") {
    VStack(spacing: 16) {
        DurationPill(text: "25 min")
        DurationPill(text: "1h 30m", color: .ollieSuccess, isHighlighted: true)
        DurationPill(text: "45 min", color: .ollieSleep, isHighlighted: true)
    }
    .padding()
}

#Preview("Live Duration") {
    LiveDurationPill(startTime: Date().addingTimeInterval(-45 * 60))
        .padding()
}
