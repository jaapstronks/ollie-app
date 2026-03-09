//
//  OtisWidgetBundle.swift
//  OtisWidget
//
//  Widget bundle registering all Otis widgets

import WidgetKit
import OtisShared
import SwiftUI

@main
struct OtisWidgetBundle: WidgetBundle {
    var body: some Widget {
        OtisWidget()            // Potty timer
        StreakWidget()          // Streak counter
        CombinedWidget()        // Combined overview
        StatusDashboardWidget() // Smart dashboard with sleep/meal/walk status
        MomentStatusWidget()    // Latest moment + current status with predictions
    }
}
