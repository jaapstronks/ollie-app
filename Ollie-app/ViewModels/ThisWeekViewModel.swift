//
//  ThisWeekViewModel.swift
//  Ollie-app
//
//  ViewModel for ThisWeekCard with visibility logic

import Foundation
import SwiftUI
import OllieShared
import Combine

/// ViewModel for the "This Week" card on Today view
@MainActor
class ThisWeekViewModel: ObservableObject {

    // MARK: - Published State

    @Published var upcomingMilestones: [Milestone] = []
    @Published var currentWeekProgress: WeeklyProgress?
    @Published var focusCategories: [SocializationCategory] = []

    // MARK: - Dependencies

    private let profileStore: ProfileStore
    private let milestoneStore: MilestoneStore
    private let socializationStore: SocializationStore
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    /// Whether to show the ThisWeekCard at all
    var shouldShowCard: Bool {
        guard let profile = profile else { return false }
        let ageWeeks = profile.ageInWeeks

        // Always show during socialization window (8-16 weeks)
        if ageWeeks >= 8 && ageWeeks <= 16 {
            return true
        }

        // Show if there are milestones within 14 days (< 6 months)
        if ageWeeks < 26 && !upcomingMilestones.isEmpty {
            return true
        }

        // Show if there are milestones within 30 days (6+ months)
        if ageWeeks >= 26 && !upcomingMilestones.isEmpty {
            return true
        }

        return false
    }

    /// Whether to show socialization content
    var showSocialization: Bool {
        guard let profile = profile else { return false }
        let ageWeeks = profile.ageInWeeks
        return ageWeeks >= 8 && ageWeeks <= 24  // Show through juvenile stage
    }

    /// Whether in the critical socialization window
    var inSocializationWindow: Bool {
        guard let profile = profile else { return false }
        return SocializationWindow.isInWindow(ageWeeks: profile.ageInWeeks)
    }

    /// Whether socialization window has closed
    var socializationWindowClosed: Bool {
        guard let profile = profile else { return false }
        return SocializationWindow.windowClosed(ageWeeks: profile.ageInWeeks)
    }

    /// Weeks remaining in socialization window
    var weeksRemaining: Int? {
        guard let profile = profile, inSocializationWindow else { return nil }
        return SocializationWindow.weeksRemaining(ageWeeks: profile.ageInWeeks)
    }

    /// Current puppy age in weeks
    var ageInWeeks: Int {
        profile?.ageInWeeks ?? 0
    }

    /// Birth date for milestone calculations
    var birthDate: Date {
        profile?.birthDate ?? Date()
    }

    // MARK: - Init

    init(
        profileStore: ProfileStore,
        milestoneStore: MilestoneStore,
        socializationStore: SocializationStore
    ) {
        self.profileStore = profileStore
        self.milestoneStore = milestoneStore
        self.socializationStore = socializationStore

        setupObservers()
        refresh()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Watch for profile changes
        profileStore.$profile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        // Watch for milestone changes
        milestoneStore.$milestones
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshMilestones()
            }
            .store(in: &cancellables)
    }

    // MARK: - Refresh

    func refresh() {
        refreshMilestones()
        refreshSocialization()
    }

    private func refreshMilestones() {
        guard let profile = profile else {
            upcomingMilestones = []
            return
        }

        // Get milestones based on age
        let withinDays = ageInWeeks >= 26 ? 30 : 14
        upcomingMilestones = milestoneStore.upcomingMilestones(
            birthDate: profile.birthDate,
            withinDays: withinDays
        )
    }

    private func refreshSocialization() {
        guard let profile = profile else {
            currentWeekProgress = nil
            focusCategories = []
            return
        }

        currentWeekProgress = socializationStore.currentWeekProgress(profile: profile)
        focusCategories = socializationStore.suggestedFocusCategories(limit: 2)
    }
}
