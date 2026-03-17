//
//  HapticFeedback.swift
//  Otis-app
//

import UIKit

/// Haptic feedback utilities for tactile responses
@MainActor
enum HapticFeedback {

    // MARK: - Raw Feedback Styles

    /// Light tap - for selections, toggles
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium tap - for button presses, logging events
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy tap - for significant actions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Success - for completed actions
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning - for alerts, confirmations
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error - for failures
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Selection changed - for pickers, segments
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Action-Based Helpers
    // Use these for semantic clarity when the action context is clear

    /// Data saved successfully (profile, event, settings)
    static func onSave() { success() }

    /// Item deleted
    static func onDelete() { warning() }

    /// Toggle switched, checkbox changed
    static func onToggle() { light() }

    /// Option selected from list, picker value changed
    static func onSelect() { selection() }

    /// Button pressed, action initiated
    static func onTap() { medium() }

    /// Action completed successfully (training session, walk logged)
    static func onComplete() { success() }

    /// Multi-select item added/removed
    static func onMultiSelectChange() { light() }

    /// Navigation step (next, back, page change)
    static func onNavigate() { light() }

    /// Milestone achieved, streak reached
    static func onAchievement() { success() }

    /// Undo action performed
    static func onUndo() { medium() }

    /// Quick log action (fast event logging)
    static func onQuickLog() { success() }
}
