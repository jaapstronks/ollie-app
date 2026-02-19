//
//  OllieWidget.swift
//  OllieWidget
//
//  Created by Jaap Stronks on 2/19/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PottyEntry {
        PottyEntry(date: Date(), minutesSinceLastPlas: 45, puppyName: "Puppy")
    }

    func getSnapshot(in context: Context, completion: @escaping (PottyEntry) -> Void) {
        let entry = PottyEntry(date: Date(), minutesSinceLastPlas: 45, puppyName: "Puppy")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PottyEntry>) -> Void) {
        // Read from shared UserDefaults (App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.jaapstronks.ollie-app")
        let lastPlasTimestamp = sharedDefaults?.double(forKey: "lastPlasTimestamp") ?? 0
        let puppyName = sharedDefaults?.string(forKey: "puppyName") ?? "Puppy"

        let currentDate = Date()
        var entries: [PottyEntry] = []

        // Calculate minutes since last plas
        let minutesSince: Int
        if lastPlasTimestamp > 0 {
            let lastPlasDate = Date(timeIntervalSince1970: lastPlasTimestamp)
            minutesSince = Int(currentDate.timeIntervalSince(lastPlasDate) / 60)
        } else {
            minutesSince = 0
        }

        // Create entries for next hour, updating every 5 minutes
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = PottyEntry(
                date: entryDate,
                minutesSinceLastPlas: minutesSince + minuteOffset,
                puppyName: puppyName
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct PottyEntry: TimelineEntry {
    let date: Date
    let minutesSinceLastPlas: Int
    let puppyName: String
}

// MARK: - Widget View

struct OllieWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(spacing: 8) {
            Text("🚽")
                .font(.system(size: 36))

            Text(timeText)
                .font(.title2)
                .fontWeight(.bold)

            Text("sinds plas")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.76, blue: 0.4), Color(red: 1.0, green: 0.65, blue: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("🚽")
                    .font(.system(size: 44))
                Text(entry.puppyName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(timeText)
                    .font(.title)
                    .fontWeight(.bold)

                Text("sinds laatste plas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if entry.minutesSinceLastPlas > 90 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Tijd voor een plasje!")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.76, blue: 0.4), Color(red: 1.0, green: 0.65, blue: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

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
}

// MARK: - Widget Configuration

struct OllieWidget: Widget {
    let kind: String = "OllieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OllieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Plas Timer")
        .description("Zie hoelang geleden de laatste plas was.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    OllieWidget()
} timeline: {
    PottyEntry(date: .now, minutesSinceLastPlas: 45, puppyName: "Ollie")
    PottyEntry(date: .now, minutesSinceLastPlas: 95, puppyName: "Ollie")
}

#Preview(as: .systemMedium) {
    OllieWidget()
} timeline: {
    PottyEntry(date: .now, minutesSinceLastPlas: 45, puppyName: "Ollie")
    PottyEntry(date: .now, minutesSinceLastPlas: 95, puppyName: "Ollie")
}
