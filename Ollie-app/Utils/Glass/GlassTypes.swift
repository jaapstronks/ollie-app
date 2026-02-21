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

    var color: Color? {
        switch self {
        case .none: return nil
        case .accent: return Color.ollieAccent
        case .success: return Color.ollieSuccess
        case .warning: return Color.ollieWarning
        case .danger: return Color.ollieDanger
        case .info: return Color.ollieInfo
        case .sleep: return Color.ollieSleep
        }
    }
}
