//
//  DayNavigationModifier.swift
//  Ollie-app
//
//  Reusable modifier for swipe-to-navigate between days
//

import SwiftUI

/// View modifier that adds horizontal swipe gesture for day navigation
struct DayNavigationModifier: ViewModifier {
    /// Whether navigation forward (to tomorrow/next day) is allowed
    let canGoForward: Bool

    /// Called when user swipes right (go to previous day)
    let onPreviousDay: () -> Void

    /// Called when user swipes left (go to next day)
    let onNextDay: () -> Void

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Minimum drag distance required to trigger navigation
    private let swipeThreshold: CGFloat = 50

    func body(content: Content) -> some View {
        content
            .gesture(dayNavigationGesture)
    }

    private var dayNavigationGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    // Swipe right -> previous day
                    HapticFeedback.selection()
                    if reduceMotion {
                        onPreviousDay()
                    } else {
                        withAnimation {
                            onPreviousDay()
                        }
                    }
                } else if value.translation.width < -swipeThreshold && canGoForward {
                    // Swipe left -> next day
                    HapticFeedback.selection()
                    if reduceMotion {
                        onNextDay()
                    } else {
                        withAnimation {
                            onNextDay()
                        }
                    }
                }
                dragOffset = 0
            }
    }
}

// MARK: - View Extension

extension View {
    /// Adds horizontal swipe gesture for day navigation
    /// - Parameters:
    ///   - canGoForward: Whether navigation to the next day is allowed
    ///   - onPreviousDay: Called when user swipes right
    ///   - onNextDay: Called when user swipes left
    func dayNavigation(
        canGoForward: Bool,
        onPreviousDay: @escaping () -> Void,
        onNextDay: @escaping () -> Void
    ) -> some View {
        modifier(DayNavigationModifier(
            canGoForward: canGoForward,
            onPreviousDay: onPreviousDay,
            onNextDay: onNextDay
        ))
    }
}
