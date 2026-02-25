//
//  OllieWatchWidgetBundle.swift
//  OllieWatchWidgets
//
//  Widget bundle for watch complications

import WidgetKit
import SwiftUI

@main
struct OllieWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        PottyTimerComplication()
        SleepTimerComplication()
        // Future: Add more complications here
        // StreakComplication()
    }
}
