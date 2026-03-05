//
//  AppNavigationState.swift
//  Otis-app
//
//  Shared navigation state for top-level app navigation.
//  This keeps tab routing centralized and prepares for future iPad split-view routing.
//

import SwiftUI

enum MainTab: Int, CaseIterable, Codable {
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
}

@MainActor
final class AppNavigationState: ObservableObject {
    @Published var selectedTab: MainTab

    init(selectedTab: MainTab = .today) {
        self.selectedTab = selectedTab
    }

    func select(_ tab: MainTab) {
        selectedTab = tab
    }
}
