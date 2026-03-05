//
//  StatusDashboardWidget.swift
//  OllieWidget
//
//  Smart dashboard widget showing sleep state, potty timer, meals, and walks
//

import WidgetKit
import OtisShared
import SwiftUI

// MARK: - Timeline Provider

struct StatusDashboardProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusDashboardEntry {
        StatusDashboardEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusDashboardEntry) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let entry = StatusDashboardEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusDashboardEntry>) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let currentDate = Date()
        var entries: [StatusDashboardEntry] = []

        // Create entries for next hour, updating every 5 minutes
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = StatusDashboardEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct StatusDashboardEntry: TimelineEntry {
    let date: Date
    let data: WidgetData

    var minutesSinceLastPlas: Int {
        guard let lastPlasTime = data.lastPlasTime else { return 0 }
        return Int(date.timeIntervalSince(lastPlasTime) / 60)
    }

    var minutesSinceSleepStart: Int {
        guard let sleepStart = data.sleepStartTime else { return 0 }
        return Int(date.timeIntervalSince(sleepStart) / 60)
    }

    var minutesSinceLastMeal: Int {
        guard let lastMeal = data.lastMealTime else { return 0 }
        return Int(date.timeIntervalSince(lastMeal) / 60)
    }

    var minutesUntilNextMeal: Int? {
        guard let nextMeal = data.nextScheduledMealTime else { return nil }
        let minutes = Int(nextMeal.timeIntervalSince(date) / 60)
        return minutes > 0 ? minutes : nil
    }

    var minutesSinceLastWalk: Int {
        guard let lastWalk = data.lastWalkTime else { return 0 }
        return Int(date.timeIntervalSince(lastWalk) / 60)
    }

    var minutesUntilNextWalk: Int? {
        guard let nextWalk = data.nextScheduledWalkTime else { return nil }
        let minutes = Int(nextWalk.timeIntervalSince(date) / 60)
        return minutes > 0 ? minutes : nil
    }

    var isMealOverdue: Bool {
        guard let nextMeal = data.nextScheduledMealTime else { return false }
        return date > nextMeal
    }

    var isWalkOverdue: Bool {
        guard let nextWalk = data.nextScheduledWalkTime else { return false }
        return date > nextWalk
    }
}

// MARK: - Widget Views

struct StatusDashboardWidgetEntryView: View {
    var entry: StatusDashboardProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        default:
            mediumWidget
        }
    }

    // MARK: - Medium Widget (2x2 grid)

    private var mediumWidget: some View {
        HStack(spacing: 0) {
            // Left: Sleep/Potty status
            VStack(spacing: 8) {
                if entry.data.isCurrentlySleeping {
                    SleepIndicatorView(
                        minutesSinceSleepStart: entry.minutesSinceSleepStart,
                        minutesSinceLastPlas: entry.minutesSinceLastPlas,
                        colorScheme: colorScheme
                    )
                } else {
                    PottyTimerView(
                        minutesSinceLastPlas: entry.minutesSinceLastPlas,
                        colorScheme: colorScheme
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(.primary.opacity(0.12))
                .frame(width: 1)
                .padding(.vertical, 16)

            // Right: Meal/Walk status
            VStack(spacing: 12) {
                MealStatusView(
                    minutesUntilNextMeal: entry.minutesUntilNextMeal,
                    isMealOverdue: entry.isMealOverdue,
                    mealsLoggedToday: entry.data.mealsLoggedToday,
                    mealsExpectedToday: entry.data.mealsExpectedToday
                )
                WalkStatusView(
                    minutesUntilNextWalk: entry.minutesUntilNextWalk,
                    isWalkOverdue: entry.isWalkOverdue,
                    minutesSinceLastWalk: entry.minutesSinceLastWalk
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(entry.data.puppyName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Sleep badge
                if entry.data.isCurrentlySleeping {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 10))
                        Text(String(localized: "Sleeping"))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.indigo.opacity(0.15), in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Main content
            if entry.data.isCurrentlySleeping {
                sleepingLargeView
            } else {
                awakeLargeView
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Sleeping Large View

    private var sleepingLargeView: some View {
        VStack(spacing: 16) {
            SleepIndicatorLargeView(
                minutesSinceSleepStart: entry.minutesSinceSleepStart,
                minutesSinceLastPlas: entry.minutesSinceLastPlas,
                colorScheme: colorScheme
            )

            // Compact meal/walk status
            HStack(spacing: 16) {
                CompactMealStatusView(
                    mealsLoggedToday: entry.data.mealsLoggedToday,
                    mealsExpectedToday: entry.data.mealsExpectedToday,
                    isOverdue: entry.isMealOverdue
                )
                CompactWalkStatusView(
                    minutesSinceLastWalk: entry.minutesSinceLastWalk,
                    isOverdue: entry.isWalkOverdue
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Awake Large View

    private var awakeLargeView: some View {
        VStack(spacing: 12) {
            // Main stats row: Potty + Streak
            HStack(spacing: 0) {
                PottyTimerLargeView(
                    minutesSinceLastPlas: entry.minutesSinceLastPlas,
                    colorScheme: colorScheme
                )
                .frame(maxWidth: .infinity)

                StreakDisplayView(
                    streak: entry.data.currentStreak,
                    colorScheme: colorScheme
                )
                .frame(maxWidth: .infinity)
            }

            // Meal & Walk cards
            HStack(spacing: 12) {
                MealCardView(
                    minutesUntilNextMeal: entry.minutesUntilNextMeal,
                    isMealOverdue: entry.isMealOverdue,
                    mealsLoggedToday: entry.data.mealsLoggedToday,
                    mealsExpectedToday: entry.data.mealsExpectedToday
                )
                WalkCardView(
                    minutesUntilNextWalk: entry.minutesUntilNextWalk,
                    isWalkOverdue: entry.isWalkOverdue,
                    minutesSinceLastWalk: entry.minutesSinceLastWalk
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: LinearGradient {
        WidgetColorPalette.backgroundGradient(
            isCurrentlySleeping: entry.data.isCurrentlySleeping,
            minutesSinceLastPlas: entry.minutesSinceLastPlas,
            colorScheme: colorScheme
        )
    }
}

// MARK: - Widget Configuration

struct StatusDashboardWidget: Widget {
    let kind: String = "StatusDashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusDashboardProvider()) { entry in
            StatusDashboardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Status Dashboard"))
        .description(String(localized: "See sleep status, potty timer, meals, and walks at a glance."))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    StatusDashboardWidget()
} timeline: {
    // Awake state
    StatusDashboardEntry(date: .now, data: .placeholder)

    // Sleeping state
    StatusDashboardEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-95 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 5,
        bestStreak: 12,
        todayPottyCount: 3,
        todayOutdoorCount: 3,
        isCurrentlySleeping: true,
        sleepStartTime: Date().addingTimeInterval(-25 * 60),
        lastWakeTime: nil,
        lastMealTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledMealTime: Date().addingTimeInterval(30 * 60),
        mealsLoggedToday: 2,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-1 * 60 * 60),
        nextScheduledWalkTime: Date().addingTimeInterval(-10 * 60), // overdue
        puppyName: "Max",
        lastUpdated: Date()
    ))
}

#Preview(as: .systemLarge) {
    StatusDashboardWidget()
} timeline: {
    // Awake state
    StatusDashboardEntry(date: .now, data: .placeholder)

    // Sleeping with potty warning
    StatusDashboardEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-110 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 7,
        bestStreak: 15,
        todayPottyCount: 4,
        todayOutdoorCount: 4,
        isCurrentlySleeping: true,
        sleepStartTime: Date().addingTimeInterval(-45 * 60),
        lastWakeTime: nil,
        lastMealTime: Date().addingTimeInterval(-3 * 60 * 60),
        nextScheduledMealTime: nil,
        mealsLoggedToday: 3,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledWalkTime: nil,
        puppyName: "Max",
        lastUpdated: Date()
    ))
}
