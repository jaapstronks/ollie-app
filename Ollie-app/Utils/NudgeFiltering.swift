//
//  NudgeFiltering.swift
//  Ollie-app
//
//  Utilities for filtering nudges and reminders based on user's responsibility level
//  and enabled nudge categories.
//

import SwiftUI
import OtisShared

// MARK: - Nudge Visibility Check

extension View {
    /// Conditionally shows this view based on whether the nudge category is enabled
    /// for the current user. If the category is disabled, the view is hidden.
    ///
    /// Usage:
    /// ```swift
    /// AppointmentNudgeCard(...)
    ///     .visibleForNudge(.appointments)
    /// ```
    @MainActor @ViewBuilder
    func visibleForNudge(_ category: NudgeCategory) -> some View {
        if UserIdentityStore.shared.shouldShowNudge(category) {
            self
        }
    }
}

// MARK: - Nudge Category Helpers

extension NudgeCategory {
    /// Check if this category is enabled for the current user
    @MainActor
    var isEnabledForCurrentUser: Bool {
        UserIdentityStore.shared.shouldShowNudge(self)
    }
}

// MARK: - Convenience for Common Patterns

/// Helper to filter an array of items based on their associated nudge category
extension Array {
    /// Filter items where the given category is enabled for the current user
    @MainActor
    func filterByNudge(_ category: NudgeCategory) -> [Element] {
        guard UserIdentityStore.shared.shouldShowNudge(category) else {
            return []
        }
        return self
    }
}
