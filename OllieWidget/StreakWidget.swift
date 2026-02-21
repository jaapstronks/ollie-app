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
            Text("\(entry.data.currentStreak) buiten op rij")
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
        if streak == 0 {
            return Color(red: 0.70, green: 0.35, blue: 0.35)
        } else if streak < 3 {
            return Color(red: 0.30, green: 0.60, blue: 0.45)
        } else if streak < 10 {
            return Color(red: 0.90, green: 0.55, blue: 0.15)
        } else {
            return Color(red: 0.85, green: 0.65, blue: 0.10)
        }
    }

    private var streakIconBackground: Color {
        let streak = entry.data.currentStreak
        if streak == 0 {
            return Color(red: 0.90, green: 0.80, blue: 0.80).opacity(0.6)
        } else if streak < 3 {
            return Color(red: 0.75, green: 0.90, blue: 0.82).opacity(0.6)
        } else if streak < 10 {
            return Color(red: 1.0, green: 0.88, blue: 0.70).opacity(0.6)
        } else {
            return Color(red: 1.0, green: 0.92, blue: 0.60).opacity(0.6)
        }
    }

    private var backgroundGradient: LinearGradient {
        let streak = entry.data.currentStreak
        if streak == 0 {
            // No streak - soft gray
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.95, blue: 0.95), Color(red: 0.90, green: 0.90, blue: 0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if streak < 5 {
            // Building - soft mint/green
            return LinearGradient(
                colors: [Color(red: 0.92, green: 0.97, blue: 0.94), Color(red: 0.85, green: 0.94, blue: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if streak < 10 {
            // On fire - soft amber
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.96, blue: 0.88), Color(red: 1.0, green: 0.92, blue: 0.80)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Champion - soft gold
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.97, blue: 0.85), Color(red: 1.0, green: 0.94, blue: 0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var streakLabel: String {
        let streak = entry.data.currentStreak
        if streak == 0 {
            return "Begin opnieuw!"
        } else {
            return "buiten op rij"
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
        .configurationDisplayName("Streak Teller")
        .description("Houd je outdoor potty streak bij.")
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
        puppyName: "Ollie",
        todayPottyCount: 5,
        todayOutdoorCount: 5,
        lastUpdated: Date()
    ))
    StreakEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-30 * 60),
        lastPlasLocation: "binnen",
        currentStreak: 0,
        bestStreak: 15,
        puppyName: "Ollie",
        todayPottyCount: 5,
        todayOutdoorCount: 4,
        lastUpdated: Date()
    ))
}

#Preview(as: .accessoryCircular) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, data: .placeholder)
}
