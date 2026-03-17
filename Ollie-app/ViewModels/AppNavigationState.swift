//
//  AppNavigationState.swift
//  Otis-app
//
//  Shared navigation state for top-level app navigation.
//  This keeps tab routing centralized and prepares for future iPad split-view routing.
//

import SwiftUI
import Combine

enum MainTab: Int, CaseIterable, Codable, Hashable {
    case today = 0
    case train = 1
    case explore = 2
    case schedule = 3
    case health = 4

    var analyticsName: String {
        switch self {
        case .today: return "today"
        case .train: return "train"
        case .explore: return "explore"
        case .schedule: return "schedule"
        case .health: return "health"
        }
    }

    var icon: String {
        switch self {
        case .today: return "pawprint.fill"
        case .train: return "graduationcap.fill"
        case .explore: return "map.fill"
        case .schedule: return "calendar.badge.clock"
        case .health: return "heart.text.square.fill"
        }
    }

    var title: String {
        switch self {
        case .today: return Strings.Tabs.today
        case .train: return Strings.Tabs.train
        case .explore: return Strings.Tabs.explore
        case .schedule: return Strings.Tabs.schedule
        case .health: return Strings.Tabs.health
        }
    }
}

@Observable
@MainActor
final class AppNavigationState {
    var selectedTab: MainTab

    init(selectedTab: MainTab = .today) {
        self.selectedTab = selectedTab
    }

    func select(_ tab: MainTab) {
        selectedTab = tab
    }
}
