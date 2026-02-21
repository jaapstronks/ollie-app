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
        VStack(spacing: 8) {
            Image(systemName: streakIcon)
                .font(.system(size: 36))
                .foregroundStyle(streakColor)

            Text("\(entry.data.currentStreak)")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(streakColor)

            Text(streakLabel)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: streakGradient,
                startPoint: .top,
                endPoint: .bottom
            )
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
            return "heart.slash.fill"
        } else if streak < 3 {
            return "hand.thumbsup.fill"
        } else {
            return "flame.fill"
        }
    }

    private var streakColor: Color {
        let streak = entry.data.currentStreak
        if streak == 0 {
            return .red
        } else if streak < 3 {
            return .green
        } else if streak < 10 {
            return .orange
        } else {
            return .yellow
        }
    }

    private var streakGradient: [Color] {
        let streak = entry.data.currentStreak
        if streak == 0 {
            // Gray gradient - no streak
            return [Color(white: 0.9), Color(white: 0.8)]
        } else if streak < 5 {
            // Green gradient - building
            return [Color(red: 0.7, green: 0.9, blue: 0.7), Color(red: 0.5, green: 0.8, blue: 0.5)]
        } else if streak < 10 {
            // Orange gradient - on fire
            return [Color(red: 1.0, green: 0.85, blue: 0.5), Color(red: 1.0, green: 0.7, blue: 0.3)]
        } else {
            // Gold gradient - champion
            return [Color(red: 1.0, green: 0.9, blue: 0.5), Color(red: 1.0, green: 0.8, blue: 0.2)]
        }
    }

    private var streakLabel: String {
        let streak = entry.data.currentStreak
        if streak == 0 {
            return "Begin opnieuw!"
        } else if streak == 1 {
            return "buiten op rij"
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
