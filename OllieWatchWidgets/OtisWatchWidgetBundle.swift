//
//  OtisWatchWidgetBundle.swift
//  OtisWatchWidgets
//
//  Widget bundle for watch complications

import WidgetKit
import SwiftUI

@main
struct OtisWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        PottyTimerComplication()
        SleepTimerComplication()
        // Future: Add more complications here
        // StreakComplication()
    }
}
