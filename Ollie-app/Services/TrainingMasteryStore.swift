//
//  TrainingMasteryStore.swift
//  Ollie-app
//
//  Observable object for training mastery state (potty, crate).
//  Use as @EnvironmentObject instead of repeating @AppStorage patterns.
//

import SwiftUI
import Combine

/// Centralized training mastery state accessible via environment object.
/// Replaces repeated @AppStorage patterns for training mastery flags.
@MainActor
final class TrainingMasteryStore: ObservableObject {

    // MARK: - Shared Instance

    static let shared = TrainingMasteryStore()

    // MARK: - Potty Training

    @Published var pottyTrainingMastered: Bool {
        didSet {
            UserDefaults.standard.set(pottyTrainingMastered, forKey: UserPreferences.Key.pottyTrainingMastered.rawValue)
        }
    }

    @Published var pottyMasteredDate: Date? {
        didSet {
            if let date = pottyMasteredDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: UserPreferences.Key.pottyTrainingMasteredDate.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserPreferences.Key.pottyTrainingMasteredDate.rawValue)
            }
        }
    }

    // MARK: - Crate Training

    @Published var crateTrainingMastered: Bool {
        didSet {
            UserDefaults.standard.set(crateTrainingMastered, forKey: UserPreferences.Key.crateTrainingMastered.rawValue)
        }
    }

    @Published var crateMasteredDate: Date? {
        didSet {
            if let date = crateMasteredDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: UserPreferences.Key.crateTrainingMasteredDate.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserPreferences.Key.crateTrainingMasteredDate.rawValue)
            }
        }
    }

    // MARK: - Potty Mastery Prompt Tracking

    @Published var pottyMasteryPromptDismissedDate: Date? {
        didSet {
            if let date = pottyMasteryPromptDismissedDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: UserPreferences.Key.pottyMasteryPromptDismissedDate.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserPreferences.Key.pottyMasteryPromptDismissedDate.rawValue)
            }
        }
    }

    @Published var pottyMasteryPromptDismissCount: Int {
        didSet {
            UserDefaults.standard.set(pottyMasteryPromptDismissCount, forKey: UserPreferences.Key.pottyMasteryPromptDismissCount.rawValue)
        }
    }

    // MARK: - Potty Incident Tracking

    @Published var pottyReactivationPromptDismissedDate: Date? {
        didSet {
            if let date = pottyReactivationPromptDismissedDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: UserPreferences.Key.pottyReactivationPromptDismissedDate.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserPreferences.Key.pottyReactivationPromptDismissedDate.rawValue)
            }
        }
    }

    @Published var pottyLastIncidentAcknowledgedDate: Date? {
        didSet {
            if let date = pottyLastIncidentAcknowledgedDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: UserPreferences.Key.pottyLastIncidentAcknowledgedDate.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserPreferences.Key.pottyLastIncidentAcknowledgedDate.rawValue)
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Potty training
        self.pottyTrainingMastered = UserDefaults.standard.bool(forKey: UserPreferences.Key.pottyTrainingMastered.rawValue)
        let pottyTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.pottyTrainingMasteredDate.rawValue)
        self.pottyMasteredDate = pottyTimestamp > 0 ? Date(timeIntervalSince1970: pottyTimestamp) : nil

        // Crate training
        self.crateTrainingMastered = UserDefaults.standard.bool(forKey: UserPreferences.Key.crateTrainingMastered.rawValue)
        let crateTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.crateTrainingMasteredDate.rawValue)
        self.crateMasteredDate = crateTimestamp > 0 ? Date(timeIntervalSince1970: crateTimestamp) : nil

        // Prompt tracking
        let dismissedTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.pottyMasteryPromptDismissedDate.rawValue)
        self.pottyMasteryPromptDismissedDate = dismissedTimestamp > 0 ? Date(timeIntervalSince1970: dismissedTimestamp) : nil
        self.pottyMasteryPromptDismissCount = UserDefaults.standard.integer(forKey: UserPreferences.Key.pottyMasteryPromptDismissCount.rawValue)

        // Incident tracking
        let reactivationTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.pottyReactivationPromptDismissedDate.rawValue)
        self.pottyReactivationPromptDismissedDate = reactivationTimestamp > 0 ? Date(timeIntervalSince1970: reactivationTimestamp) : nil
        let incidentTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.pottyLastIncidentAcknowledgedDate.rawValue)
        self.pottyLastIncidentAcknowledgedDate = incidentTimestamp > 0 ? Date(timeIntervalSince1970: incidentTimestamp) : nil
    }

    // MARK: - Actions

    /// Mark potty training as mastered
    func markPottyMastered() {
        pottyTrainingMastered = true
        pottyMasteredDate = Date()
    }

    /// Unmark potty training mastery (reactivate training)
    func reactivatePottyTraining() {
        pottyTrainingMastered = false
        pottyMasteredDate = nil
    }

    /// Mark crate training as mastered
    func markCrateMastered() {
        crateTrainingMastered = true
        crateMasteredDate = Date()
    }

    /// Unmark crate training mastery (reactivate training)
    func reactivateCrateTraining() {
        crateTrainingMastered = false
        crateMasteredDate = nil
    }

    /// Dismiss the potty mastery prompt
    func dismissPottyMasteryPrompt() {
        pottyMasteryPromptDismissedDate = Date()
        pottyMasteryPromptDismissCount += 1
    }

    /// Dismiss the potty reactivation prompt
    func dismissPottyReactivationPrompt() {
        pottyReactivationPromptDismissedDate = Date()
    }

    /// Acknowledge the last potty incident
    func acknowledgeLastPottyIncident() {
        pottyLastIncidentAcknowledgedDate = Date()
    }

    // MARK: - Computed Properties

    /// Days since potty training was mastered
    var daysSincePottyMastered: Int? {
        guard let date = pottyMasteredDate else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }

    /// Days since crate training was mastered
    var daysSinceCrateMastered: Int? {
        guard let date = crateMasteredDate else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }
}
