//
//  StatusDashboardWidget.swift
//  OllieWidget
//
//  Smart dashboard widget showing sleep state, potty timer, meals, and walks

import WidgetKit
import OllieShared
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
                // Sleep indicator
                if entry.data.isCurrentlySleeping {
                    sleepingIndicator
                } else {
                    pottyTimer
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
                mealStatus
                walkStatus
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
                // Sleeping view: show sleep time + potty warning
                sleepingLargeView
            } else {
                // Awake view: standard dashboard
                awakeLargeView
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Sleep Components

    private var sleepingIndicator: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(sleepIconBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(sleepIconColor)
            }

            Text(formatDuration(entry.minutesSinceSleepStart))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "sleeping"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            // Potty warning while sleeping
            if entry.minutesSinceLastPlas > 90 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                    Text("\(formatDuration(entry.minutesSinceLastPlas))")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(pottyUrgencyColor)
                .padding(.top, 2)
            }
        }
    }

    private var sleepingLargeView: some View {
        VStack(spacing: 16) {
            // Sleep duration
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(sleepIconBackground)
                        .frame(width: 64, height: 64)

                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(sleepIconColor)
                }

                Text(formatDuration(entry.minutesSinceSleepStart))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(String(localized: "asleep"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Potty alert if overdue while sleeping
            if entry.minutesSinceLastPlas > 90 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text(String(localized: "Potty break needed when awake"))
                        .font(.system(size: 12, weight: .semibold))
                    Text("(\(formatDuration(entry.minutesSinceLastPlas)))")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(pottyUrgencyColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(pottyUrgencyColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            }

            // Compact meal/walk status
            HStack(spacing: 16) {
                compactMealStatus
                compactWalkStatus
            }
            .padding(.horizontal, 16)
        }
    }

    private var awakeLargeView: some View {
        VStack(spacing: 12) {
            // Main stats row: Potty + Streak
            HStack(spacing: 0) {
                pottyTimerLarge
                    .frame(maxWidth: .infinity)

                streakDisplay
                    .frame(maxWidth: .infinity)
            }

            // Meal & Walk cards
            HStack(spacing: 12) {
                mealCard
                walkCard
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Potty Components

    private var pottyTimer: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(pottyIconBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: "drop.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(pottyIconColor)
            }

            Text(formatDuration(entry.minutesSinceLastPlas))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "since potty"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var pottyTimerLarge: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(pottyIconBackground)
                    .frame(width: 52, height: 52)

                Image(systemName: "drop.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(pottyIconColor)
            }

            Text(formatDuration(entry.minutesSinceLastPlas))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "since potty"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var streakDisplay: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(streakIconBackground)
                    .frame(width: 52, height: 52)

                Image(systemName: streakIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(streakIconColor)
            }

            Text("\(entry.data.currentStreak)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "streak"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Meal Components

    private var mealStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "fork.knife")
                .font(.system(size: 12))
                .foregroundStyle(mealStatusColor)

            if let mins = entry.minutesUntilNextMeal {
                Text(String(localized: "in \(formatDuration(mins))"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            } else if entry.isMealOverdue {
                Text(String(localized: "overdue"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            } else {
                Text("\(entry.data.mealsLoggedToday)/\(entry.data.mealsExpectedToday)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var compactMealStatus: some View {
        HStack(spacing: 4) {
            Image(systemName: "fork.knife")
                .font(.system(size: 10))
            Text("\(entry.data.mealsLoggedToday)/\(entry.data.mealsExpectedToday)")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(mealStatusColor)
    }

    private var mealCard: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 10))
                    .foregroundStyle(mealStatusColor)

                if let mins = entry.minutesUntilNextMeal {
                    Text(String(localized: "in \(formatDuration(mins))"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                } else if entry.isMealOverdue {
                    Text(String(localized: "Overdue"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text(String(localized: "Done"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.green)
                }
            }

            Text("\(entry.data.mealsLoggedToday)/\(entry.data.mealsExpectedToday) \(String(localized: "meals"))")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Walk Components

    private var walkStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.walk")
                .font(.system(size: 12))
                .foregroundStyle(walkStatusColor)

            if let mins = entry.minutesUntilNextWalk {
                Text(String(localized: "in \(formatDuration(mins))"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            } else if entry.isWalkOverdue {
                Text(String(localized: "overdue"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            } else {
                Text(formatDuration(entry.minutesSinceLastWalk) + " " + String(localized: "ago"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var compactWalkStatus: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
                .font(.system(size: 10))
            if entry.minutesSinceLastWalk > 0 {
                Text(formatDuration(entry.minutesSinceLastWalk))
                    .font(.system(size: 10, weight: .medium))
            } else {
                Text("--")
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .foregroundStyle(walkStatusColor)
    }

    private var walkCard: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 10))
                    .foregroundStyle(walkStatusColor)

                if let mins = entry.minutesUntilNextWalk {
                    Text(String(localized: "in \(formatDuration(mins))"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                } else if entry.isWalkOverdue {
                    Text(String(localized: "Overdue"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text(formatDuration(entry.minutesSinceLastWalk) + " " + String(localized: "ago"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }

            Text(String(localized: "last walk"))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func formatDuration(_ minutes: Int) -> String {
        DurationFormatter.format(minutes, style: .compact, showZeroAsEmpty: true)
    }

    // MARK: - Colors

    private var backgroundGradient: LinearGradient {
        let isDark = colorScheme == .dark

        if entry.data.isCurrentlySleeping {
            // Sleeping - soft indigo/purple
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.15, green: 0.15, blue: 0.28), Color(red: 0.18, green: 0.16, blue: 0.32)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.94, green: 0.94, blue: 0.98), Color(red: 0.90, green: 0.90, blue: 0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        // Awake - use potty urgency colors
        let minutes = entry.minutesSinceLastPlas
        if minutes > 120 {
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.35, green: 0.15, blue: 0.15), Color(red: 0.40, green: 0.18, blue: 0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.98, green: 0.92, blue: 0.90), Color(red: 0.95, green: 0.85, blue: 0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else if minutes > 90 {
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.35, green: 0.28, blue: 0.12), Color(red: 0.38, green: 0.30, blue: 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 1.0, green: 0.96, blue: 0.88), Color(red: 1.0, green: 0.92, blue: 0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.12, green: 0.22, blue: 0.18), Color(red: 0.14, green: 0.25, blue: 0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.92, green: 0.97, blue: 0.94), Color(red: 0.85, green: 0.94, blue: 0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var sleepIconBackground: Color {
        let isDark = colorScheme == .dark
        return isDark
            ? Color(red: 0.35, green: 0.30, blue: 0.55).opacity(0.7)
            : Color(red: 0.80, green: 0.78, blue: 0.92).opacity(0.6)
    }

    private var sleepIconColor: Color {
        let isDark = colorScheme == .dark
        return isDark
            ? Color(red: 0.70, green: 0.65, blue: 0.95)
            : Color(red: 0.45, green: 0.40, blue: 0.70)
    }

    private var pottyIconBackground: Color {
        let minutes = entry.minutesSinceLastPlas
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark
                ? Color(red: 0.55, green: 0.25, blue: 0.22).opacity(0.7)
                : Color(red: 0.95, green: 0.75, blue: 0.70).opacity(0.6)
        } else if minutes > 90 {
            return isDark
                ? Color(red: 0.55, green: 0.45, blue: 0.20).opacity(0.7)
                : Color(red: 1.0, green: 0.88, blue: 0.65).opacity(0.6)
        } else {
            return isDark
                ? Color(red: 0.20, green: 0.45, blue: 0.35).opacity(0.7)
                : Color(red: 0.70, green: 0.88, blue: 0.78).opacity(0.6)
        }
    }

    private var pottyIconColor: Color {
        let minutes = entry.minutesSinceLastPlas
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark
                ? Color(red: 1.0, green: 0.55, blue: 0.50)
                : Color(red: 0.85, green: 0.30, blue: 0.25)
        } else if minutes > 90 {
            return isDark
                ? Color(red: 1.0, green: 0.75, blue: 0.30)
                : Color(red: 0.90, green: 0.60, blue: 0.10)
        } else {
            return isDark
                ? Color(red: 0.45, green: 0.85, blue: 0.65)
                : Color(red: 0.25, green: 0.65, blue: 0.45)
        }
    }

    private var pottyUrgencyColor: Color {
        let minutes = entry.minutesSinceLastPlas
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark ? Color(red: 1.0, green: 0.55, blue: 0.50) : .red
        } else {
            return isDark ? Color(red: 1.0, green: 0.75, blue: 0.30) : .orange
        }
    }

    private var streakIcon: String {
        let streak = entry.data.currentStreak
        if streak == 0 { return "xmark.circle.fill" }
        else if streak < 3 { return "star.fill" }
        else if streak < 10 { return "flame.fill" }
        else { return "trophy.fill" }
    }

    private var streakIconColor: Color {
        let streak = entry.data.currentStreak
        let isDark = colorScheme == .dark

        if streak == 0 {
            return isDark ? Color(red: 0.90, green: 0.55, blue: 0.55) : Color(red: 0.70, green: 0.35, blue: 0.35)
        } else if streak < 3 {
            return isDark ? Color(red: 0.50, green: 0.85, blue: 0.65) : Color(red: 0.30, green: 0.60, blue: 0.45)
        } else if streak < 10 {
            return isDark ? Color(red: 1.0, green: 0.70, blue: 0.30) : Color(red: 0.90, green: 0.55, blue: 0.15)
        } else {
            return isDark ? Color(red: 1.0, green: 0.80, blue: 0.25) : Color(red: 0.85, green: 0.65, blue: 0.10)
        }
    }

    private var streakIconBackground: Color {
        let streak = entry.data.currentStreak
        let isDark = colorScheme == .dark

        if streak == 0 {
            return isDark
                ? Color(red: 0.45, green: 0.25, blue: 0.25).opacity(0.7)
                : Color(red: 0.90, green: 0.80, blue: 0.80).opacity(0.6)
        } else if streak < 3 {
            return isDark
                ? Color(red: 0.20, green: 0.40, blue: 0.30).opacity(0.7)
                : Color(red: 0.75, green: 0.90, blue: 0.82).opacity(0.6)
        } else if streak < 10 {
            return isDark
                ? Color(red: 0.50, green: 0.40, blue: 0.18).opacity(0.7)
                : Color(red: 1.0, green: 0.88, blue: 0.70).opacity(0.6)
        } else {
            return isDark
                ? Color(red: 0.50, green: 0.45, blue: 0.15).opacity(0.7)
                : Color(red: 1.0, green: 0.92, blue: 0.60).opacity(0.6)
        }
    }

    private var mealStatusColor: Color {
        if entry.isMealOverdue {
            return .orange
        }
        return .secondary
    }

    private var walkStatusColor: Color {
        if entry.isWalkOverdue {
            return .orange
        }
        return .secondary
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
        lastMealTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledMealTime: Date().addingTimeInterval(30 * 60),
        mealsLoggedToday: 2,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-1 * 60 * 60),
        nextScheduledWalkTime: Date().addingTimeInterval(-10 * 60), // overdue
        puppyName: "Ollie",
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
        lastMealTime: Date().addingTimeInterval(-3 * 60 * 60),
        nextScheduledMealTime: nil,
        mealsLoggedToday: 3,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledWalkTime: nil,
        puppyName: "Ollie",
        lastUpdated: Date()
    ))
}
