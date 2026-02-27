//
//  OllieWatchApp.swift
//  OllieWatch
//
//  Apple Watch companion app for Ollie puppy logbook
//
//  IMPORTANT: WCSession must be activated as early as possible in the app lifecycle.
//  Apple recommends activation in applicationDidFinishLaunching or equivalent.

import SwiftUI

@main
struct OllieWatchApp: App {
    /// WatchDataProvider manages WatchConnectivity session and data sync
    /// Using @StateObject ensures it's created once and persists for app lifetime
    @StateObject private var dataProvider = WatchDataProvider.shared

    init() {
        // Activate WCSession as early as possible in app lifecycle
        // This is the earliest point in SwiftUI app lifecycle where we can do this
        Task { @MainActor in
            WatchDataProvider.shared.activateSession()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataProvider)
                .onAppear {
                    // Ensure session is activated (backup in case init didn't run)
                    dataProvider.activateSession()
                    dataProvider.refresh()
                }
        }
    }
}
