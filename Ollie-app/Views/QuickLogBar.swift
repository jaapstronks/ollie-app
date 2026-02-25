//
//  QuickLogBar.swift
//  Ollie-app
//

import SwiftUI
import OllieShared

/// Context for smart quick log bar icon display
struct QuickLogContext {
    let sleepState: SleepState
    let mealSchedule: MealSchedule?
    let todayEvents: [PuppyEvent]

    /// Check if we're within meal window (30 min before or 60 min after a scheduled meal time)
    var shouldShowMealIcon: Bool {
        guard let schedule = mealSchedule else { return true }

        let now = Date()
        let calendar = Calendar.current

        // Check if any meal is already logged today
        let mealEventsToday = todayEvents.meals()

        for portion in schedule.portions {
            guard let targetTimeStr = portion.targetTime else { continue }

            // Parse target time (format: "HH:mm")
            let components = targetTimeStr.split(separator: ":").compactMap { Int($0) }
            guard components.count == 2 else { continue }

            var mealComponents = calendar.dateComponents([.year, .month, .day], from: now)
            mealComponents.hour = components[0]
            mealComponents.minute = components[1]

            guard let mealTime = calendar.date(from: mealComponents) else { continue }

            // Check if this meal is already logged (within 1 hour of target time)
            let mealLogged = mealEventsToday.contains { event in
                abs(event.time.timeIntervalSince(mealTime)) < 3600 // Within 1 hour
            }

            if mealLogged { continue }

            // Show icon from configured window before until configured window after
            let windowStart = calendar.date(byAdding: .minute, value: -Constants.mealWindowBeforeMinutes, to: mealTime)!
            let windowEnd = calendar.date(byAdding: .minute, value: Constants.mealWindowAfterMinutes, to: mealTime)!

            if now >= windowStart && now <= windowEnd {
                return true
            }
        }

        return false
    }

    /// Check if we're in a walk window (after meals or scheduled walk times)
    var shouldShowWalkIcon: Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // Check if walk already logged recently
        let recentWalk = todayEvents.first { event in
            event.type == .uitlaten && abs(event.time.timeIntervalSince(now)) < Constants.recentWalkThresholdSeconds
        }
        if recentWalk != nil { return false }

        // Check walk windows from Constants
        for (start, end) in Constants.walkWindows {
            if hour >= start && hour <= end {
                return true
            }
        }

        // Also show after recent meal (within configured window)
        let recentMeal = todayEvents.first { event in
            event.type == .eten && now.minutesSince(event.time) <= Constants.mealWindowBeforeMinutes
        }
        if recentMeal != nil { return true }

        return false
    }
}

/// Bottom bar with smart quick-log buttons for common events
/// Uses liquid glass design for iOS 26 aesthetic
struct QuickLogBar: View {
    let context: QuickLogContext
    let canLogEvents: Bool
    let onPottyTap: () -> Void
    let onQuickLog: (EventType) -> Void
    let onShowAllEvents: () -> Void
    let onCameraTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Compute which icons to show based on context
    private var visibleItems: [QuickLogItem] {
        var items: [QuickLogItem] = []

        // Always show potty (combined plassen+poepen)
        items.append(.potty)

        // Show meal icon only when near mealtime
        if context.shouldShowMealIcon {
            items.append(.event(.eten))
        }

        // Show walk icon only during walk windows
        if context.shouldShowWalkIcon {
            items.append(.event(.uitlaten))
        }

        // Show sleep OR wake based on current state
        switch context.sleepState {
        case .sleeping:
            items.append(.event(.ontwaken))
        case .awake, .unknown:
            items.append(.event(.slapen))
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating glass bar
            HStack(spacing: 8) {
                ForEach(visibleItems, id: \.self) { item in
                    switch item {
                    case .potty:
                        QuickLogIconButton.potty(action: onPottyTap)
                    case .event(let type):
                        QuickLogIconButton.forEventType(type) { onQuickLog(type) }
                    }
                }

                // Camera button for photo moments
                QuickLogIconButton.camera(action: onCameraTap)

                // "+" button to show all event types
                QuickLogIconButton.more(action: onShowAllEvents)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassBackground(.bar)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 16, y: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .opacity(canLogEvents ? 1.0 : 0.5)
        }
    }
}

/// Enum to represent items in the quick log bar
private enum QuickLogItem: Hashable {
    case potty
    case event(EventType)
}

#Preview {
    VStack {
        Spacer()
        QuickLogBar(
            context: QuickLogContext(
                sleepState: .awake(since: Date(), durationMin: 30),
                mealSchedule: nil,
                todayEvents: []
            ),
            canLogEvents: true,
            onPottyTap: {
                print("Potty tapped")
            },
            onQuickLog: { type in
                print("Quick log: \(type)")
            },
            onShowAllEvents: {
                print("Show all events")
            },
            onCameraTap: {
                print("Camera tapped")
            }
        )
    }
}
