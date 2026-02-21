//
//  CombinedWidget.swift
//  OllieWidget
//
//  Combined widget showing potty timer and streak together

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct CombinedProvider: TimelineProvider {
    func placeholder(in context: Context) -> CombinedEntry {
        CombinedEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CombinedEntry) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let entry = CombinedEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CombinedEntry>) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let currentDate = Date()
        var entries: [CombinedEntry] = []

        // Create entries for next hour, updating every 5 minutes
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = CombinedEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct CombinedEntry: TimelineEntry {
    let date: Date
    let data: WidgetData

    var minutesSinceLastPlas: Int {
        guard let lastPlasTime = data.lastPlasTime else { return 0 }
        return Int(date.timeIntervalSince(lastPlasTime) / 60)
    }
}

// MARK: - Widget Views

struct CombinedWidgetEntryView: View {
    var entry: CombinedProvider.Entry
    @Environment(\.widgetFamily) var family

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

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 0) {
            // Left side: Potty timer
            VStack(spacing: 4) {
                Text("🚽")
                    .font(.system(size: 32))

                Text(timeText)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("sinds plas")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 12)

            // Right side: Streak
            VStack(spacing: 4) {
                Image(systemName: streakIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(streakColor)

                Text("\(entry.data.currentStreak)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("streak")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: urgencyGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(spacing: 12) {
            // Header with puppy name
            HStack {
                Text(entry.data.puppyName)
                    .font(.headline)
                Spacer()
                Text("vandaag")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Main stats row
            HStack(spacing: 0) {
                // Potty timer
                VStack(spacing: 4) {
                    Text("🚽")
                        .font(.system(size: 40))

                    Text(timeText)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("sinds plas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Streak
                VStack(spacing: 4) {
                    Image(systemName: streakIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(streakColor)

                    Text("\(entry.data.currentStreak)")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("buiten op rij")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal)

            // Today's summary
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(entry.data.todayPottyCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("plasjes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 2) {
                    Text("\(entry.data.todayOutdoorCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("buiten")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 2) {
                    Text("\(entry.data.bestStreak)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("record")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 8)

            // Warning message if needed
            if entry.minutesSinceLastPlas > 90 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Tijd voor een plasje!")
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.bottom, 8)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: urgencyGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Helpers

    private var timeText: String {
        let minutes = entry.minutesSinceLastPlas
        if minutes == 0 {
            return "-- min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) uur"
            }
            return "\(hours)u \(mins)m"
        }
    }

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

    private var urgencyGradient: [Color] {
        let minutes = entry.minutesSinceLastPlas
        if minutes > 120 {
            return [Color(red: 1.0, green: 0.6, blue: 0.5), Color(red: 0.9, green: 0.4, blue: 0.3)]
        } else if minutes > 90 {
            return [Color(red: 1.0, green: 0.76, blue: 0.4), Color(red: 1.0, green: 0.65, blue: 0.3)]
        } else {
            return [Color(red: 0.7, green: 0.9, blue: 0.7), Color(red: 0.5, green: 0.8, blue: 0.5)]
        }
    }
}

// MARK: - Widget Configuration

struct CombinedWidget: Widget {
    let kind: String = "CombinedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CombinedProvider()) { entry in
            CombinedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ollie Overzicht")
        .description("Plas timer en streak in één widget.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    CombinedWidget()
} timeline: {
    CombinedEntry(date: .now, data: .placeholder)
    CombinedEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-95 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 7,
        bestStreak: 15,
        puppyName: "Ollie",
        todayPottyCount: 6,
        todayOutdoorCount: 5,
        lastUpdated: Date()
    ))
}

#Preview(as: .systemLarge) {
    CombinedWidget()
} timeline: {
    CombinedEntry(date: .now, data: .placeholder)
}
