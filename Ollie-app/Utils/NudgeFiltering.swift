//
//  NudgeFiltering.swift
//  Ollie-app
//
//  Utilities for filtering nudges and reminders based on user's responsibility level
//  and enabled nudge categories. Settings are per-profile (each user can have different
//  roles for different dogs).
//

import SwiftUI
import OtisShared

// MARK: - Nudge Visibility Check

extension View {
    /// Conditionally shows this view based on whether the nudge category is enabled
    /// for the active profile. If the category is disabled, the view is hidden.
    ///
    /// Usage:
    /// ```swift
    /// AppointmentNudgeCard(...)
    ///     .visibleForNudge(.appointments)
    /// ```
    @MainActor @ViewBuilder
    func visibleForNudge(_ category: NudgeCategory) -> some View {
        if NudgeFilteringHelper.isNudgeEnabled(category) {
            self
        }
    }
}

// MARK: - Nudge Category Helpers

extension NudgeCategory {
    /// Check if this category is enabled for the active profile
    @MainActor
    var isEnabledForCurrentUser: Bool {
        NudgeFilteringHelper.isNudgeEnabled(self)
    }
}

// MARK: - Convenience for Common Patterns

/// Helper to filter an array of items based on their associated nudge category
extension Array {
    /// Filter items where the given category is enabled for the active profile
    @MainActor
    func filterByNudge(_ category: NudgeCategory) -> [Element] {
        guard NudgeFilteringHelper.isNudgeEnabled(category) else {
            return []
        }
        return self
    }
}

// MARK: - Helper

/// Internal helper to check nudge visibility for the active profile
@MainActor
enum NudgeFilteringHelper {
    /// Check if a nudge category is enabled for the active profile
    static func isNudgeEnabled(_ category: NudgeCategory) -> Bool {
        guard let profile = ProfileStoreProvider.shared.store.activeProfile else {
            // Fallback to global setting if no active profile
            return UserIdentityStore.shared.shouldShowNudge(category)
        }
        return UserIdentityStore.shared.shouldShowNudge(
            category,
            for: profile.id,
            ownership: profile.ownership
        )
    }
}
