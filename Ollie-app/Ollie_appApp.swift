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

        // Install seed data for development
        #if DEBUG
        SeedData.installSeedDataIfNeeded()
        #endif
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
