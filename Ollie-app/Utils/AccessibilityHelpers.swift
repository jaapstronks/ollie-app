//
//  AccessibilityHelpers.swift
//  Ollie-app
//
//  Reusable accessibility utilities and extensions

import SwiftUI
import OllieShared

// MARK: - Conditional Animation Extension

extension View {
    /// Applies animation only when reduce motion is not enabled
    /// Use this for all spring/bouncy animations throughout the app
    @ViewBuilder
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V, reduceMotion: Bool) -> some View {
        if reduceMotion {
            self
        } else {
            self.animation(animation, value: value)
        }
    }

}

// MARK: - Accessibility Label Helpers

extension String {
    /// Formats a duration in minutes as an accessible string
    /// e.g., 65 -> "1 uur en 5 minuten"
    var accessibleDuration: String {
        guard let minutes = Int(self.replacingOccurrences(of: " min", with: "")
                                   .replacingOccurrences(of: "m", with: "")
                                   .components(separatedBy: "u").last ?? self) else {
            return self
        }

        if minutes < 60 {
            return "\(minutes) minuten"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) uur"
            }
            return "\(hours) uur en \(mins) minuten"
        }
    }
}

// MARK: - Accessible Progress Bar

/// A progress bar with proper accessibility support
struct AccessibleProgressBar: View {
    let progress: Double
    let label: String
    let valueDescription: String
    let progressColor: Color
    let height: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(
        progress: Double,
        label: String,
        valueDescription: String,
        progressColor: Color = .accentColor,
        height: CGFloat = 16
    ) {
        self.progress = progress
        self.label = label
        self.valueDescription = valueDescription
        self.progressColor = progressColor
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track - meets minimum height for touch
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(progressColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: height / 2)
                            .strokeBorder(progressColor.opacity(0.2), lineWidth: 0.5)
                    )

                // Filled portion
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                progressColor,
                                progressColor.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(1, max(0, progress)), height: height)
                    .shadow(color: progressColor.opacity(0.3), radius: 4, y: 2)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(valueDescription)
    }
}

// MARK: - Minimum Tap Target Modifier

extension View {
    /// Ensures minimum 44x44pt tap target as per Apple HIG
    func minimumTapTarget() -> some View {
        self
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}
