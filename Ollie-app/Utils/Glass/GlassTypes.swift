//
//  GlassTypes.swift
//  Ollie-app
//
//  iOS 26 "Liquid Glass" design system - Type definitions
//

import SwiftUI

// MARK: - Glass Style Configuration

/// Glass effect variants matching iOS 26 design language
enum GlassStyle {
    /// Default glass for toolbars, buttons, navigation
    case regular
    /// Clearer glass for floating controls over media
    case clear
    /// Subtle glass for cards and containers
    case card
    /// Prominent glass for hero elements
    case prominent
}

/// Tint colors for semantic meaning
enum GlassTint {
    case none
    case accent
    case success
    case warning
    case danger
    case info
    case sleep
    case custom(Color)

    var color: Color? {
        switch self {
        case .none: return nil
        case .accent: return Color.ollieAccent
        case .success: return Color.ollieSuccess
        case .warning: return Color.ollieWarning
        case .danger: return Color.ollieDanger
        case .info: return Color.ollieInfo
        case .sleep: return Color.ollieSleep
        case .custom(let color): return color
        }
    }
}

// MARK: - Glass Button Helpers

/// Shared helpers for glass button backgrounds and effects
/// Reduces code duplication across GlassPillButtonStyle, GlassIconButtonStyle, etc.
enum GlassButtonHelpers {

    /// Calculate base opacity for glass button background
    static func baseOpacity(
        isPressed: Bool,
        colorScheme: ColorScheme,
        pressedLight: Double = 0.95,
        normalLight: Double = 0.8,
        pressedDark: Double = 0.15,
        normalDark: Double = 0.1
    ) -> Double {
        if colorScheme == .dark {
            return isPressed ? pressedDark : normalDark
        } else {
            return isPressed ? pressedLight : normalLight
        }
    }

    /// Calculate tint overlay opacity
    static func tintOpacity(colorScheme: ColorScheme, dark: Double = 0.2, light: Double = 0.12) -> Double {
        colorScheme == .dark ? dark : light
    }

    /// Standard capsule border gradient for glass buttons
    static func capsuleBorderGradient(colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Standard circle border gradient for glass icon buttons
    static func circleBorderGradient(colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Highlight gradient for buttons with top-to-center fade
    static func highlightGradient(colorScheme: ColorScheme, darkOpacity: Double = 0.12, lightOpacity: Double = 0.35) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? darkOpacity : lightOpacity),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .center
        )
    }

    /// Glass color for toggle button backgrounds
    /// Used by StateButton, PottyOptionButton, YesNoButton, GapTypeButton, etc.
    static func glassColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6)
    }

    /// Glass pill background view for button styles
    /// Used by GlassPillButtonStyle and GlassPillCompactButtonStyle
    @ViewBuilder
    static func glassPillBackground(
        isPressed: Bool,
        tint: GlassTint,
        colorScheme: ColorScheme
    ) -> some View {
        ZStack {
            Color.white.opacity(baseOpacity(isPressed: isPressed, colorScheme: colorScheme))
            if let tintColor = tint.color {
                tintColor.opacity(tintOpacity(colorScheme: colorScheme))
            }
        }
        .background(.ultraThinMaterial)
    }
}
