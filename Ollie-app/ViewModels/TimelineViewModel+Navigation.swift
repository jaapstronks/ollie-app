//
//  TimelineViewModel+Navigation.swift
//  Ollie-app
//
//  Navigation-related functionality for TimelineViewModel
//

import Foundation
import OllieShared

extension TimelineViewModel {
    // MARK: - Navigation

    var dateTitle: String {
        currentDate.relativeDayString
    }

    var canGoForward: Bool {
        !currentDate.isToday
    }

    func goToPreviousDay() {
        currentDate = currentDate.addingDays(-1)
        loadEvents()
    }

    func goToNextDay() {
        guard canGoForward else { return }
        currentDate = currentDate.addingDays(1)
        loadEvents()
    }

    func goToToday() {
        currentDate = Date()
        loadEvents()
    }

    func goToDate(_ date: Date) {
        currentDate = date
        loadEvents()
    }

    /// Whether current view is showing today
    var isShowingToday: Bool {
        currentDate.isToday
    }

    /// Whether user can log events (only for today)
    var canLogEvents: Bool {
        currentDate.isToday
    }
}
