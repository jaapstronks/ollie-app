//
//  PottyTrainingGuideViewModel.swift
//  Otis-app
//
//  ViewModel for PottyTrainingGuideSheet - handles age phase calculation,
//  pattern analysis, mastery state, and phase-based tips.
//

import Combine
import Foundation
import OtisShared
import SwiftUI

/// Age phases for potty training guidance
enum PottyAgePhase {
    case early   // 8-12 weeks
    case middle  // 12-16 weeks
    case older   // 16+ weeks

    init(ageInWeeks: Int) {
        switch ageInWeeks {
        case ..<12: self = .early
        case 12..<16: self = .middle
        default: self = .older
        }
    }

    var title: String {
        switch self {
        case .early: return Strings.Training.Guides.earlyWeeks
        case .middle: return Strings.Training.Guides.middleWeeks
        case .older: return Strings.Training.Guides.olderPuppy
        }
    }

    var tips: [String] {
        switch self {
        case .early:
            return [
                Strings.Training.Guides.earlyTip1,
                Strings.Training.Guides.earlyTip2,
                Strings.Training.Guides.earlyTip3,
                Strings.Training.Guides.earlyTip4
            ]
        case .middle:
            return [
                Strings.Training.Guides.middleTip1,
                Strings.Training.Guides.middleTip2,
                Strings.Training.Guides.middleTip3,
                Strings.Training.Guides.middleTip4
            ]
        case .older:
            return [
                Strings.Training.Guides.olderTip1,
                Strings.Training.Guides.olderTip2,
                Strings.Training.Guides.olderTip3,
                Strings.Training.Guides.olderTip4
            ]
        }
    }
}

/// ViewModel managing potty training guide state and calculations
@Observable
@MainActor
final class PottyTrainingGuideViewModel {

    // MARK: - Input Data

    let streakInfo: StreakInfo
    let patternAnalysis: PatternAnalysis
    let outdoorPercentage: Int
    let ageInWeeks: Int

    // Injected from parent (TimelineViewModel)
    let shouldShowIncidentMessage: Bool
    let shouldShowReactivationPrompt: Bool
    let incidentCount: Int

    // MARK: - Dependencies

    @ObservationIgnored
    private let trainingMasteryStore: TrainingMasteryStore

    // MARK: - Observable State

    var showMasteryConfirmation = false

    // MARK: - Init

    init(
        streakInfo: StreakInfo,
        patternAnalysis: PatternAnalysis,
        outdoorPercentage: Int,
        ageInWeeks: Int,
        shouldShowIncidentMessage: Bool,
        shouldShowReactivationPrompt: Bool,
        incidentCount: Int,
        trainingMasteryStore: TrainingMasteryStore = .shared
    ) {
        self.streakInfo = streakInfo
        self.patternAnalysis = patternAnalysis
        self.outdoorPercentage = outdoorPercentage
        self.ageInWeeks = ageInWeeks
        self.shouldShowIncidentMessage = shouldShowIncidentMessage
        self.shouldShowReactivationPrompt = shouldShowReactivationPrompt
        self.incidentCount = incidentCount
        self.trainingMasteryStore = trainingMasteryStore
    }

    // MARK: - Mastery State

    var isMastered: Bool {
        trainingMasteryStore.pottyTrainingMastered
    }

    var masteredDateFormatted: String {
        guard let date = trainingMasteryStore.pottyMasteredDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Age Phase

    var agePhase: PottyAgePhase {
        PottyAgePhase(ageInWeeks: ageInWeeks)
    }

    var phaseTitle: String {
        agePhase.title
    }

    var phaseTips: [String] {
        agePhase.tips
    }

    // MARK: - Pattern Analysis

    /// Top pattern triggers for display (up to 3, sorted by success rate)
    var topTriggers: [PatternTrigger] {
        patternAnalysis.triggers
            .filter { $0.hasData }
            .sorted { $0.successRate > $1.successRate }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Progress State

    /// Whether user has meaningful data to display
    var hasData: Bool {
        outdoorPercentage > 0 || streakInfo.currentStreak > 0 || !topTriggers.isEmpty
    }

    /// Color for the outdoor percentage stat
    var percentageColor: Color {
        switch outdoorPercentage {
        case 90...: return .otisSuccess
        case 70...: return .otisAccent
        case 50...: return .otisWarning
        default: return .otisDanger
        }
    }

    // MARK: - Actions

    func markAsMastered() {
        trainingMasteryStore.markPottyMastered()
        HapticFeedback.success()
    }

    func reactivateTracking() {
        trainingMasteryStore.reactivatePottyTraining()
        // Clear dismissal states
        trainingMasteryStore.pottyReactivationPromptDismissedDate = nil
        trainingMasteryStore.pottyLastIncidentAcknowledgedDate = nil
        HapticFeedback.light()
    }

    func acknowledgeIncident() {
        trainingMasteryStore.acknowledgeLastPottyIncident()
        HapticFeedback.selection()
    }

    func dismissReactivationPrompt() {
        trainingMasteryStore.dismissPottyReactivationPrompt()
        HapticFeedback.selection()
    }
}
