//
//  TourStep.swift
//  Ollie-app
//
//  Model for guided tour steps

import SwiftUI

/// Steps in the guided app tour
enum TourStep: Int, CaseIterable {
    case welcome = 0
    case today = 1
    case train = 2
    case explore = 3
    case schedule = 4
    case health = 5
    case done = 6

    /// The title for this step
    var title: String {
        switch self {
        case .welcome: return Strings.GuidedTour.welcomeTitle
        case .today: return Strings.GuidedTour.todayTitle
        case .train: return Strings.GuidedTour.trainTitle
        case .explore: return Strings.GuidedTour.exploreTitle
        case .schedule: return Strings.GuidedTour.scheduleTitle
        case .health: return Strings.GuidedTour.healthTitle
        case .done: return Strings.GuidedTour.doneTitle
        }
    }

    /// The body text for this step
    var body: String {
        switch self {
        case .welcome: return Strings.GuidedTour.welcomeBody
        case .today: return Strings.GuidedTour.todayBody
        case .train: return Strings.GuidedTour.trainBody
        case .explore: return Strings.GuidedTour.exploreBody
        case .schedule: return Strings.GuidedTour.scheduleBody
        case .health: return Strings.GuidedTour.healthBody
        case .done: return Strings.GuidedTour.doneBody
        }
    }

    /// The SF Symbol icon for this step
    var icon: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .today: return "pawprint.fill"
        case .train: return "graduationcap.fill"
        case .explore: return "map.fill"
        case .schedule: return "calendar.badge.clock"
        case .health: return "heart.text.square.fill"
        case .done: return "checkmark.circle.fill"
        }
    }

    /// The tab to highlight for this step (nil for welcome/done)
    var associatedTab: MainTab? {
        switch self {
        case .welcome, .done: return nil
        case .today: return .today
        case .train: return .train
        case .explore: return .explore
        case .schedule: return .schedule
        case .health: return .health
        }
    }

    /// The button text for this step
    var buttonText: String {
        switch self {
        case .welcome: return Strings.GuidedTour.nextStep
        case .done: return Strings.GuidedTour.startExploring
        default: return Strings.GuidedTour.gotIt
        }
    }

    /// The next step (nil if this is the last step)
    var next: TourStep? {
        TourStep(rawValue: rawValue + 1)
    }

    /// Total number of steps
    static var totalSteps: Int {
        TourStep.allCases.count
    }
}
