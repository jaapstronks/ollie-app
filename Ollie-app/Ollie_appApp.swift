//
//  Ollie_appApp.swift
//  Ollie-app
//

import SwiftUI

@main
struct OllieApp: App {
    init() {
        // Install seed data for development
        #if DEBUG
        SeedData.installSeedDataIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
