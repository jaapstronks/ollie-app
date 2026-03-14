//
//  OtisWatchApp.swift
//  OtisWatch
//
//  Apple Watch companion app for Otis puppy logbook
//
//  IMPORTANT: WCSession must be activated as early as possible in the app lifecycle.
//  Apple recommends activation in applicationDidFinishLaunching or equivalent.

import SwiftUI

@main
struct OtisWatchApp: App {
    /// WatchDataProvider manages WatchConnectivity session and data sync
    /// Using @State with shared instance ensures it persists for app lifetime
    @State private var dataProvider = WatchDataProvider.shared

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
                .environment(dataProvider)
                .onAppear {
                    // Ensure session is activated (backup in case init didn't run)
                    dataProvider.activateSession()
                    dataProvider.refresh()
                }
        }
    }
}
