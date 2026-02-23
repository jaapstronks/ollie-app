//
//  OllieWidgetBundle.swift
//  OllieWidget
//
//  Widget bundle registering all Ollie widgets

import WidgetKit
import OllieShared
import SwiftUI

@main
struct OllieWidgetBundle: WidgetBundle {
    var body: some Widget {
        OllieWidget()           // Potty timer
        StreakWidget()          // Streak counter
        CombinedWidget()        // Combined overview
        StatusDashboardWidget() // Smart dashboard with sleep/meal/walk status
    }
}
