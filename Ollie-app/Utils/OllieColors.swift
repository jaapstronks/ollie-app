//
//  OllieColors.swift
//  Ollie-app
//
//  Brand colors and semantic color palette

import SwiftUI

/// Ollie brand color palette
extension Color {
    // MARK: - Brand Colors

    /// Warm gold — primary accent
    static let ollieAccent = Color(hex: "E8A855")

    /// Light gold — backgrounds, badges
    static let ollieAccentLight = Color(hex: "F5D08E")

    /// Deep amber — pressed states
    static let ollieAccentDark = Color(hex: "C4872E")

    // MARK: - Semantic Colors

    /// Green — buiten, positive outcomes
    static let ollieSuccess = Color(hex: "5BAA6E")

    /// Gold — caution, transitions (same as accent)
    static let ollieWarning = Color(hex: "E8A855")

    /// Red — binnen, alerts
    static let ollieDanger = Color(hex: "D4594E")

    /// Teal — stats, neutral data
    static let ollieInfo = Color(hex: "5BA4B5")

    /// Muted blue — sleep events
    static let ollieSleep = Color(hex: "7B8CC2")

    /// Gray — secondary text, neutral
    static let ollieMuted = Color(hex: "9CA3AF")

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
