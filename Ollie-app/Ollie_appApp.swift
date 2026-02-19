//
//  Ollie_appApp.swift
//  Ollie-app
//

import SwiftUI

@main
struct OllieApp: App {
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var eventStore = EventStore()
    @StateObject private var dataImporter = DataImporter()

    init() {
        UserPreferences.registerDefaults()

        // Install bundled seed data on first launch
        SeedData.installSeedDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileStore)
                .environmentObject(eventStore)
                .environmentObject(dataImporter)
        }
    }
}
