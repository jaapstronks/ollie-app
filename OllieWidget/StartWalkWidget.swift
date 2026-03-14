//
//  StartWalkWidget.swift
//  OllieWidget
//
//  Lock Screen widget for quickly starting a walk with GPS tracking
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Start Walk Intent (Widget-specific)

/// Intent for starting a walk from the widget
/// This opens the app and triggers walk tracking
struct WidgetStartWalkIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Walk"
    static let description = IntentDescription("Start a walk with GPS tracking")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Store the pending walk start
        let defaults = UserDefaults(suiteName: "group.jaapstronks.Otis")
        defaults?.set(Date().timeIntervalSince1970, forKey: "pendingWalkStart")
        return .result()
    }
}

// MARK: - Timeline Provider

struct StartWalkProvider: TimelineProvider {
    func placeholder(in context: Context) -> StartWalkEntry {
        StartWalkEntry(date: Date(), isWalkInProgress: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (StartWalkEntry) -> Void) {
        let entry = StartWalkEntry(date: Date(), isWalkInProgress: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StartWalkEntry>) -> Void) {
        let entry = StartWalkEntry(date: Date(), isWalkInProgress: false)
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct StartWalkEntry: TimelineEntry {
    let date: Date
    let isWalkInProgress: Bool
}

// MARK: - Widget Views

struct StartWalkWidgetEntryView: View {
    var entry: StartWalkProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular (Lock Screen)

    private var circularView: some View {
        Button(intent: WidgetStartWalkIntent()) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "figure.walk")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rectangular (Lock Screen)

    private var rectangularView: some View {
        Button(intent: WidgetStartWalkIntent()) {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Walk")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Tap to begin")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Inline (Complications)

    private var inlineView: some View {
        Label("Start Walk", systemImage: "figure.walk")
    }
}

// MARK: - Widget Configuration

struct StartWalkWidget: Widget {
    let kind: String = "StartWalkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StartWalkProvider()) { entry in
            StartWalkWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(String(localized: "Start Walk"))
        .description(String(localized: "Quickly start a walk with GPS tracking."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    StartWalkWidget()
} timeline: {
    StartWalkEntry(date: .now, isWalkInProgress: false)
}

#Preview(as: .accessoryRectangular) {
    StartWalkWidget()
} timeline: {
    StartWalkEntry(date: .now, isWalkInProgress: false)
}
