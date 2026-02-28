//
//  SeedData.swift
//  Ollie-app
//

import Foundation
import CoreData
import OllieShared

enum SeedData {
    /// Check if running in UI testing mode
    static var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
    }

    // Sample events for development/testing
    static func installSeedDataIfNeeded() {
        // Install test profile for UI tests
        if isUITesting {
            installTestProfileIfNeeded()
        }

        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataDir = docs.appendingPathComponent("data", isDirectory: true)

        // Create data directory if needed
        try? fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)

        // Check if we already have data
        let todayFile = dataDir.appendingPathComponent("\(Date().dateString).jsonl")
        if fileManager.fileExists(atPath: todayFile.path) {
            return // Already have data for today
        }

        // Create sample data for today
        let calendar = Calendar.current
        let now = Date()

        var events: [String] = []

        // Morning events
        if let time1 = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) {
            events.append(makeEvent(time: time1, type: "ontwaken"))
        }
        if let time2 = calendar.date(bySettingHour: 7, minute: 5, second: 0, of: now) {
            events.append(makeEvent(time: time2, type: "plassen", location: "buiten"))
        }
        if let time3 = calendar.date(bySettingHour: 7, minute: 10, second: 0, of: now) {
            events.append(makeEvent(time: time3, type: "poepen", location: "buiten"))
        }
        if let time4 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: now) {
            events.append(makeEvent(time: time4, type: "eten"))
        }
        if let time5 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) {
            events.append(makeEvent(time: time5, type: "plassen", location: "buiten", note: "After breakfast"))
        }
        if let time6 = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now) {
            events.append(makeEvent(time: time6, type: "slapen", note: "Morning nap"))
        }
        if let time7 = calendar.date(bySettingHour: 10, minute: 15, second: 0, of: now) {
            events.append(makeEvent(time: time7, type: "ontwaken"))
        }
        if let time8 = calendar.date(bySettingHour: 10, minute: 20, second: 0, of: now) {
            events.append(makeEvent(time: time8, type: "plassen", location: "buiten"))
        }

        // Write to file
        let content = events.joined(separator: "\n") + "\n"
        try? content.write(to: todayFile, atomically: true, encoding: .utf8)
    }

    /// Install a test profile for UI testing
    private static func installTestProfileIfNeeded() {
        let context = PersistenceController.shared.viewContext

        // Check if profile already exists
        if CDPuppyProfile.fetchProfile(in: context) != nil {
            return
        }

        // Create test profile: "Test Puppy", 12 weeks old, medium size
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .weekOfYear, value: -12, to: Date()) ?? Date()
        let homeDate = calendar.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()

        let testProfile = PuppyProfile.defaultProfile(
            name: "Test Puppy",
            birthDate: birthDate,
            homeDate: homeDate,
            size: .medium
        )

        _ = CDPuppyProfile.create(from: testProfile, in: context)
        try? context.save()
    }

    private static func makeEvent(time: Date, type: String, location: String? = nil, note: String? = nil) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone.current
        let timeStr = formatter.string(from: time)

        var json = "{\"time\":\"\(timeStr)\",\"type\":\"\(type)\""
        if let loc = location {
            json += ",\"location\":\"\(loc)\""
        }
        if let n = note {
            json += ",\"note\":\"\(n)\""
        }
        json += "}"
        return json
    }
}
