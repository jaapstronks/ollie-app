//
//  OllieWidget.swift
//  OllieWidget
//
//  Potty timer widget showing time since last plas event

import WidgetKit
import SwiftUI

// MARK: - Shared Widget Data

/// Widget data shared between app and widgets via App Groups
struct WidgetData: Codable {
    let lastPlasTime: Date?
    let lastPlasLocation: String?
    let currentStreak: Int
    let bestStreak: Int
    let puppyName: String
    let todayPottyCount: Int
    let todayOutdoorCount: Int
    let lastUpdated: Date

    static var placeholder: WidgetData {
        WidgetData(
            lastPlasTime: Date().addingTimeInterval(-45 * 60),
            lastPlasLocation: "buiten",
            currentStreak: 3,
            bestStreak: 12,
            puppyName: "Puppy",
            todayPottyCount: 4,
            todayOutdoorCount: 3,
            lastUpdated: Date()
        )
    }
}

/// Reads widget data from shared App Group UserDefaults
struct WidgetDataReader {
    static let suiteName = "group.jaapstronks.ollie-app"
    static let dataKey = "widgetData"

    static func read() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName),
              let data = sharedDefaults.data(forKey: dataKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(WidgetData.self, from: data)
    }
}

// MARK: - Timeline Provider

struct PottyProvider: TimelineProvider {
    func placeholder(in context: Context) -> PottyEntry {
        PottyEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PottyEntry) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let entry = PottyEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PottyEntry>) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let currentDate = Date()
        var entries: [PottyEntry] = []

        // Create entries for next hour, updating every 5 minutes
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = PottyEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct PottyEntry: TimelineEntry {
    let date: Date
    let data: WidgetData

    var minutesSinceLastPlas: Int {
        guard let lastPlasTime = data.lastPlasTime else { return 0 }
        return Int(date.timeIntervalSince(lastPlasTime) / 60)
    }

    var wasOutdoor: Bool {
        data.lastPlasLocation == "buiten"
    }
}

// MARK: - Widget Views

struct PottyWidgetEntryView: View {
    var entry: PottyProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryCircular:
            circularWidget
        case .accessoryInline:
            inlineWidget
        case .accessoryRectangular:
            rectangularWidget
        default:
            smallWidget
        }
    }

    // MARK: - Home Screen Widgets

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
                colors: urgencyGradient,
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
                Text(entry.data.puppyName)
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
                colors: urgencyGradient,
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
                Image(systemName: "drop.fill")
                    .font(.system(size: 14))
                Text(compactTimeText)
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }

    private var inlineWidget: some View {
        HStack(spacing: 4) {
            Image(systemName: "drop.fill")
            Text("\(timeText) sinds plas")
        }
    }

    private var rectangularWidget: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                    Text(timeText)
                        .fontWeight(.bold)
                }
                Text("sinds plas")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.data.currentStreak > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Text("\(entry.data.currentStreak)")
                            .fontWeight(.bold)
                        Image(systemName: "flame.fill")
                    }
                    Text("streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
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

    private var compactTimeText: String {
        let minutes = entry.minutesSinceLastPlas
        if minutes == 0 {
            return "--"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)u"
            }
            return "\(hours):\(String(format: "%02d", mins))"
        }
    }

    private var urgencyGradient: [Color] {
        let minutes = entry.minutesSinceLastPlas
        if minutes > 120 {
            // Red gradient - urgent
            return [Color(red: 1.0, green: 0.6, blue: 0.5), Color(red: 0.9, green: 0.4, blue: 0.3)]
        } else if minutes > 90 {
            // Orange gradient - warning
            return [Color(red: 1.0, green: 0.76, blue: 0.4), Color(red: 1.0, green: 0.65, blue: 0.3)]
        } else {
            // Green gradient - good
            return [Color(red: 0.7, green: 0.9, blue: 0.7), Color(red: 0.5, green: 0.8, blue: 0.5)]
        }
    }
}

// MARK: - Widget Configuration

struct OllieWidget: Widget {
    let kind: String = "OllieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PottyProvider()) { entry in
            PottyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Plas Timer")
        .description("Zie hoelang geleden de laatste plas was.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    OllieWidget()
} timeline: {
    PottyEntry(date: .now, data: .placeholder)
    PottyEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-95 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 5,
        bestStreak: 12,
        puppyName: "Ollie",
        todayPottyCount: 6,
        todayOutdoorCount: 5,
        lastUpdated: Date()
    ))
}

#Preview(as: .systemMedium) {
    OllieWidget()
} timeline: {
    PottyEntry(date: .now, data: .placeholder)
}

#Preview(as: .accessoryCircular) {
    OllieWidget()
} timeline: {
    PottyEntry(date: .now, data: .placeholder)
}

#Preview(as: .accessoryRectangular) {
    OllieWidget()
} timeline: {
    PottyEntry(date: .now, data: .placeholder)
}
