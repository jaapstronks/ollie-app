//
//  MomentStatusEntry.swift
//  OllieWidget
//
//  Timeline entry for the MomentStatusWidget
//

import WidgetKit
import OtisShared
import UIKit

// MARK: - Timeline Entry

struct MomentStatusEntry: TimelineEntry {
    let date: Date
    let data: WidgetData

    var minutesSinceLastEvent: Int {
        guard let lastEventTime = data.lastEventTime else { return 0 }
        return Int(date.timeIntervalSince(lastEventTime) / 60)
    }

    var minutesSinceSleepStart: Int {
        guard let sleepStart = data.sleepStartTime else { return 0 }
        return Int(date.timeIntervalSince(sleepStart) / 60)
    }

    var minutesSinceWake: Int {
        guard let wakeTime = data.lastWakeTime else { return 0 }
        return Int(date.timeIntervalSince(wakeTime) / 60)
    }

    var minutesUntilExpectedWake: Int? {
        guard let expectedWake = data.expectedWakeTime else { return nil }
        let minutes = Int(expectedWake.timeIntervalSince(date) / 60)
        return minutes > 0 ? minutes : nil
    }

    var expectedWakeTimeFormatted: String? {
        guard let expectedWake = data.expectedWakeTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: expectedWake)
    }

    var suggestedNapTime: Date? {
        // Suggest nap if awake for more than 45 minutes
        guard !data.isCurrentlySleeping,
              let wakeTime = data.lastWakeTime,
              minutesSinceWake >= 45 else { return nil }

        // Suggest nap time based on max awake duration (60 min default)
        let maxAwakeMinutes = 60
        return wakeTime.addingTimeInterval(Double(maxAwakeMinutes) * 60)
    }

    var isNapSuggestionOverdue: Bool {
        guard let napTime = suggestedNapTime else { return false }
        return date > napTime
    }

    /// Load thumbnail image from shared container
    var thumbnailImage: UIImage? {
        guard let thumbnailName = data.lastEventThumbnailName else { return nil }

        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier) else {
            return nil
        }

        let thumbnailURL = containerURL
            .appendingPathComponent("WidgetThumbnails", isDirectory: true)
            .appendingPathComponent(thumbnailName)

        guard let imageData = try? Data(contentsOf: thumbnailURL) else {
            return nil
        }

        return UIImage(data: imageData)
    }
}
