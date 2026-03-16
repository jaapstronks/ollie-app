//
//  QuickActionButton.swift
//  Otis-app
//
//  Reusable quick action button with confirmation animation
//

import SwiftUI

/// A compact circular button that shows a confirmation animation after being tapped
///
/// Usage:
/// ```swift
/// QuickActionButton(
///     icon: "plus",
///     confirmedIcon: "checkmark",
///     tint: .otisAccent,
///     confirmTint: .otisSuccess,
///     action: { print("Tapped!") }
/// )
/// ```
struct QuickActionButton: View {
    /// Icon to show in default state
    let icon: String

    /// Icon to show during confirmation
    let confirmedIcon: String

    /// Tint color for default state
    let tint: Color

    /// Tint color during confirmation (defaults to otisSuccess)
    let confirmTint: Color

    /// Background style for default state
    let backgroundStyle: BackgroundStyle

    /// Size of the button
    let size: CGFloat

    /// How long to show confirmation before resetting
    let confirmationDuration: TimeInterval

    /// Action to perform on tap
    let action: () -> Void

    /// Accessibility label
    let accessibilityLabel: String?

    /// Accessibility hint
    let accessibilityHint: String?

    @State private var showConfirmation = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Background Styles

    enum BackgroundStyle {
        case tinted(Color)     // Filled with color at low opacity
        case neutral           // System-appropriate neutral background
        case solid(Color)      // Solid color fill

        func color(for colorScheme: ColorScheme, showingConfirmation: Bool, confirmTint: Color) -> Color {
            if showingConfirmation {
                return confirmTint
            }
            switch self {
            case .tinted(let color):
                return color.opacity(colorScheme == .dark ? 0.2 : 0.15)
            case .neutral:
                return colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
            case .solid(let color):
                return color
            }
        }
    }

    // MARK: - Initializers

    init(
        icon: String,
        confirmedIcon: String = "checkmark",
        tint: Color = .otisAccent,
        confirmTint: Color = .otisSuccess,
        backgroundStyle: BackgroundStyle = .neutral,
        size: CGFloat = 32,
        confirmationDuration: TimeInterval = 1.0,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.confirmedIcon = confirmedIcon
        self.tint = tint
        self.confirmTint = confirmTint
        self.backgroundStyle = backgroundStyle
        self.size = size
        self.confirmationDuration = confirmationDuration
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button {
            action()

            // Show confirmation animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showConfirmation = true
            }

            // Reset after duration
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(confirmationDuration))
                withAnimation(.easeOut(duration: 0.2)) {
                    showConfirmation = false
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(backgroundStyle.color(for: colorScheme, showingConfirmation: showConfirmation, confirmTint: confirmTint))
                    .frame(width: size, height: size)

                Image(systemName: showConfirmation ? confirmedIcon : icon)
                    .font(.system(size: showConfirmation ? size * 0.44 : size * 0.38, weight: .semibold))
                    .foregroundStyle(showConfirmation ? .white : tint)
            }
            .scaleEffect(showConfirmation ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? icon)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Convenience Initializers

extension QuickActionButton {
    /// Quick log / add button (plus icon, neutral background)
    static func quickLog(
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) -> QuickActionButton {
        QuickActionButton(
            icon: "plus",
            confirmedIcon: "checkmark",
            tint: .otisAccent,
            confirmTint: .otisSuccess,
            backgroundStyle: .neutral,
            confirmationDuration: 1.0,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            action: action
        )
    }

    /// Mark as mastered button (star icon, success tinted)
    static func markMastered(
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) -> QuickActionButton {
        QuickActionButton(
            icon: "star.fill",
            confirmedIcon: "checkmark",
            tint: .otisSuccess,
            confirmTint: .otisSuccess,
            backgroundStyle: .tinted(.otisSuccess),
            confirmationDuration: 1.5,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            action: action
        )
    }
}

// MARK: - Preview

#Preview("Quick Action Buttons") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            QuickActionButton(
                icon: "plus",
                action: { print("Add") }
            )

            QuickActionButton(
                icon: "star.fill",
                tint: .otisSuccess,
                backgroundStyle: .tinted(.otisSuccess),
                confirmationDuration: 1.5,
                action: { print("Star") }
            )

            QuickActionButton(
                icon: "heart.fill",
                tint: .pink,
                backgroundStyle: .tinted(.pink),
                action: { print("Heart") }
            )
        }

        HStack(spacing: 16) {
            QuickActionButton.quickLog(
                accessibilityLabel: "Quick log",
                action: { print("Quick log") }
            )

            QuickActionButton.markMastered(
                accessibilityLabel: "Mark mastered",
                action: { print("Mastered") }
            )
        }
    }
    .padding()
}
