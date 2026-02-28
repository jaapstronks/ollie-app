//
//  OllieColors.swift
//  Ollie-app
//
//  Brand colors and semantic color palette

import SwiftUI
import OllieShared

// MARK: - Color Usage Philosophy
//
// CATEGORY COLORS (What type of event/content):
// - Timeline events, filter chips, stats section headers
// - Sleep events → ollieSleep (muted blue)
// - Food/meals → ollieAccent (gold)
// - Walks/outdoor → ollieSuccess (green)
// - Training → olliePurple (purple)
// - Health/medical → ollieHealth (coral)
// - Milestones → ollieRose (rose)
//
// OUTCOME COLORS (Success/failure):
// - Potty location: outdoor = ollieSuccess, indoor = ollieDanger
// - Completion states: completed = ollieSuccess
//
// URGENCY COLORS (Attention level):
// - Status cards, reminders, alerts
// - Just happened/good → ollieSuccess (green)
// - Normal/info → ollieInfo (teal)
// - Attention needed → ollieWarning (gold)
// - Urgent/overdue → ollieDanger (red)

/// Ollie brand color palette
extension Color {
    // MARK: - Brand Colors

    /// Warm gold — primary accent
    static let ollieAccent = Color(hex: "E8A855")

    /// Light gold — backgrounds, badges
    /// Adjusted for WCAG 4.5:1 contrast ratio
    static let ollieAccentLight = Color(hex: "D4A04A")

    /// Deep amber — pressed states
    /// Adjusted for WCAG 4.5:1 contrast ratio on dark backgrounds
    static let ollieAccentDark = Color(hex: "A36B1D")

    // MARK: - Semantic Colors

    /// Green — buiten, positive outcomes, social interactions
    static let ollieSuccess = Color(hex: "5BAA6E")

    /// Gold — caution, transitions (same as accent)
    static let ollieWarning = Color(hex: "E8A855")

    /// Red — binnen, alerts, urgent
    static let ollieDanger = Color(hex: "D4594E")

    /// Teal — stats, neutral data, foundations
    static let ollieInfo = Color(hex: "5BA4B5")

    /// Muted blue — sleep, rest, crate
    static let ollieSleep = Color(hex: "7B8CC2")

    /// Purple — training, mental activities, learning
    static let olliePurple = Color(hex: "9B7BC2")

    /// Rose — milestones, celebrations, care
    static let ollieRose = Color(hex: "E87B9E")

    /// Gray — secondary text, neutral
    /// Adjusted for WCAG 4.5:1 contrast ratio
    static let ollieMuted = Color(hex: "6B7280")

    // MARK: - Health/Medical Colors

    /// Coral — health events (weight, medication, vet)
    static let ollieHealth = Color(hex: "E87B6B")

    /// Light coral — health event backgrounds
    static let ollieHealthTint = Color(hex: "FDF0EE")

    // MARK: - Milestone Category Colors

    /// Health milestones — medical red
    static let ollieHealthRed = Color(hex: "E85555")

    /// Health tint — light background
    static let ollieHealthRedTint = Color(hex: "FDECEC")

    /// Developmental milestones — purple
    static let ollieDevelopmental = Color(hex: "9B7BC2")

    /// Developmental tint — light background
    static let ollieDevelopmentalTint = Color(hex: "F3EDF9")

    /// Administrative milestones — blue
    static let ollieAdministrative = Color(hex: "5BA4B5")

    /// Administrative tint — light background
    static let ollieAdministrativeTint = Color(hex: "EBF5F7")

    /// Custom milestones — orange
    static let ollieCustomOrange = Color(hex: "E8A855")

    /// Custom tint — light background
    static let ollieCustomOrangeTint = Color(hex: "FDF5E8")

    // MARK: - Background Colors

    /// Warm cream background (light mode)
    static let ollieBackgroundLight = Color(hue: 38/360, saturation: 0.60, brightness: 0.97)

    /// Warm dark background (dark mode)
    static let ollieBackgroundDark = Color(hue: 25/360, saturation: 0.20, brightness: 0.08)

    /// Card background (light mode)
    static let ollieCardLight = Color(hue: 38/360, saturation: 0.50, brightness: 0.99)

    /// Card background (dark mode)
    static let ollieCardDark = Color(hue: 25/360, saturation: 0.20, brightness: 0.11)

    /// Border color (light mode)
    static let ollieBorderLight = Color(hue: 38/360, saturation: 0.30, brightness: 0.88)

    /// Border color (dark mode)
    static let ollieBorderDark = Color(hue: 25/360, saturation: 0.15, brightness: 0.18)

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
