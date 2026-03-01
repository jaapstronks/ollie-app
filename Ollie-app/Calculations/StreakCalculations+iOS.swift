//
//  StreakCalculations+iOS.swift
//  Otis-app
//
//  iOS-only extensions for StreakCalculations that use SwiftUI.Color

import OtisShared
import SwiftUI

// MARK: - iOS-Only Color Extensions

extension StreakCalculations {
    /// Returns appropriate icon color based on streak count
    static func iconColor(for streak: Int) -> Color {
        switch streak {
        case 0: return .otisMuted
        case 1...3: return .otisInfo
        case 4...7: return .otisSuccess
        case 8...14: return .otisAccent
        default: return .otisAccent
        }
    }
}
