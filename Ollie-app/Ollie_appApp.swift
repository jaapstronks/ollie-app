//
//  Ollie_appApp.swift
//  Ollie-app
//
//  Created by Jaap Stronks on 2/19/26.
//

import SwiftUI

@main
struct OllieApp: App {
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var eventStore = EventStore()
    @StateObject private var dataImporter = DataImporter()

    init() {
        UserPreferences.registerDefaults()
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
