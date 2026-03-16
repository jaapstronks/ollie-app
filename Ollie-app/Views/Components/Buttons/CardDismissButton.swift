//
//  CardDismissButton.swift
//  Ollie-app
//
//  Standardized dismiss button for cards on the Today tab.
//  Use this for any card that can be dismissed by the user.
//

import SwiftUI

/// Standardized dismiss button (X) for dismissable cards
///
/// Provides consistent styling across all cards:
/// - 24×24 circular button with subtle fill
/// - SF Symbol xmark icon
/// - Secondary foreground color
///
/// Usage:
/// ```swift
/// HStack {
///     Text("Card Title")
///     Spacer()
///     CardDismissButton(action: onDismiss)
/// }
/// ```
struct CardDismissButton: View {
    /// Action to perform when tapped
    let action: () -> Void

    /// Optional custom accessibility label (defaults to "Close")
    var accessibilityLabel: String = Strings.Common.close

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("CardDismissButton") {
    VStack(spacing: 24) {
        // In a card header context
        HStack {
            Label("Latest Moment", systemImage: "photo.on.rectangle.angled")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Spacer()

            CardDismissButton(action: { print("Dismissed") })
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))

        // Standalone
        CardDismissButton(action: { print("Dismissed") })

        // With custom accessibility
        CardDismissButton(
            action: { print("Dismissed") },
            accessibilityLabel: "Dismiss card"
        )
    }
    .padding()
}
