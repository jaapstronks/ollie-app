//
//  StreakWidget.swift
//  OllieWidget
//
//  Streak counter widget showing consecutive outdoor potty events

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let entry = StreakEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let currentDate = Date()

        // Streak doesn't change frequently, refresh every 15 minutes
        let entries = [StreakEntry(date: currentDate, data: data)]
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Widget Views

struct StreakWidgetEntryView: View {
    var entry: StreakProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .accessoryCircular:
            circularWidget
        case .accessoryInline:
            inlineWidget
        default:
            smallWidget
        }
    }

    // MARK: - Home Screen Widget

    private var smallWidget: some View {
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
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(streakLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Lock Screen Widgets

    private var circularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: streakIcon)
                    .font(.system(size: 14))
                Text("\(entry.data.currentStreak)")
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }

    private var inlineWidget: some View {
        HStack(spacing: 4) {
            Image(systemName: streakIcon)
            Text("\(entry.data.currentStreak) \(String(localized: "outdoor streak"))")
        }
    }

    // MARK: - Helpers

    private var streakIcon: String {
        let streak = entry.data.currentStreak
        if streak == 0 {
            return "xmark.circle.fill"
        } else if streak < 3 {
            return "star.fill"
        } else if streak < 10 {
            return "flame.fill"
        } else {
            return "trophy.fill"
        }
    }

    private var streakIconColor: Color {
        let streak = entry.data.currentStreak
        let isDark = colorScheme == .dark

        if streak == 0 {
            return isDark
                ? Color(red: 0.90, green: 0.55, blue: 0.55)
                : Color(red: 0.70, green: 0.35, blue: 0.35)
        } else if streak < 3 {
            return isDark
                ? Color(red: 0.50, green: 0.85, blue: 0.65)
                : Color(red: 0.30, green: 0.60, blue: 0.45)
        } else if streak < 10 {
            return isDark
                ? Color(red: 1.0, green: 0.70, blue: 0.30)
                : Color(red: 0.90, green: 0.55, blue: 0.15)
        } else {
            return isDark
                ? Color(red: 1.0, green: 0.80, blue: 0.25)
                : Color(red: 0.85, green: 0.65, blue: 0.10)
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

    private var backgroundGradient: LinearGradient {
        let streak = entry.data.currentStreak
        let isDark = colorScheme == .dark

        if streak == 0 {
            // No streak - gray
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.18, green: 0.18, blue: 0.18), Color(red: 0.22, green: 0.22, blue: 0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.95, green: 0.95, blue: 0.95), Color(red: 0.90, green: 0.90, blue: 0.90)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else if streak < 5 {
            // Building - mint/green
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
        } else if streak < 10 {
            // On fire - amber
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
            // Champion - gold
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.38, green: 0.32, blue: 0.10), Color(red: 0.42, green: 0.35, blue: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 1.0, green: 0.97, blue: 0.85), Color(red: 1.0, green: 0.94, blue: 0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var streakLabel: String {
        let streak = entry.data.currentStreak
        if streak == 0 {
            return String(localized: "Start fresh!")
        } else {
            return String(localized: "outdoor streak")
        }
    }
}

// MARK: - Widget Configuration

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Streak Counter"))
        .description(String(localized: "Track your outdoor potty streak."))
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, data: .placeholder)
    StreakEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-30 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 12,
        bestStreak: 15,
        todayPottyCount: 5,
        todayOutdoorCount: 5,
        isCurrentlySleeping: false,
        sleepStartTime: nil,
        lastMealTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledMealTime: Date().addingTimeInterval(1 * 60 * 60),
        mealsLoggedToday: 2,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-1 * 60 * 60),
        nextScheduledWalkTime: Date().addingTimeInterval(30 * 60),
        puppyName: "Ollie",
        lastUpdated: Date()
    ))
    StreakEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-30 * 60),
        lastPlasLocation: "binnen",
        currentStreak: 0,
        bestStreak: 15,
        todayPottyCount: 5,
        todayOutdoorCount: 4,
        isCurrentlySleeping: false,
        sleepStartTime: nil,
        lastMealTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledMealTime: Date().addingTimeInterval(1 * 60 * 60),
        mealsLoggedToday: 2,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-1 * 60 * 60),
        nextScheduledWalkTime: Date().addingTimeInterval(30 * 60),
        puppyName: "Ollie",
        lastUpdated: Date()
    ))
}

#Preview(as: .accessoryCircular) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, data: .placeholder)
}
