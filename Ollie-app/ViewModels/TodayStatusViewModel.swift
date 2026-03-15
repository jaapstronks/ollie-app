//
//  TodayStatusViewModel.swift
//  Otis-app
//
//  ViewModel for TodayView status calculations and nudge dismissal state.
//  Extracts business logic from the view layer for better separation of concerns.
//

import Combine
import Foundation
import OtisShared
import SwiftUI

/// ViewModel managing TodayView status calculations and nudge state
@Observable
@MainActor
final class TodayStatusViewModel {

    // MARK: - State (Dismissals)

    private(set) var dismissedCrateNudgeDate: Date?
    private(set) var dismissedGroomingNudgeDate: Date?

    // MARK: - Recent Moment Card Dismissal

    /// Stores the ID of the dismissed moment - card stays hidden until a newer moment appears
    @ObservationIgnored @AppStorage("dismissedRecentMomentID") private var dismissedRecentMomentIDString: String = ""

    private var dismissedRecentMomentID: UUID? {
        dismissedRecentMomentIDString.isEmpty ? nil : UUID(uuidString: dismissedRecentMomentIDString)
    }

    // MARK: - Persisted Dismissals (7-day cooldown)

    /// Persisted dismissal for walk target nudge (7-day cooldown, survives app restart)
    /// Note: We use a separate tracked property to trigger UI updates since @AppStorage
    /// doesn't participate in @Observable tracking.
    @ObservationIgnored @AppStorage("walkTargetNudgeDismissedDate") private var walkTargetNudgeDismissedTimestamp: Double = 0

    /// Tracked property to trigger UI re-render when dismissal changes
    private var walkTargetNudgeDismissedVersion: Int = 0

    private var dismissedWalkTargetNudgeDate: Date? {
        // Reference tracked version to participate in observation
        _ = walkTargetNudgeDismissedVersion
        return walkTargetNudgeDismissedTimestamp > 0 ? Date(timeIntervalSince1970: walkTargetNudgeDismissedTimestamp) : nil
    }

    // MARK: - Sheet State

    var showMonthRecapSheet = false
    var showYearRecapSheet = false
    var showVetTipsSheet = false
    var showVisitSummary = false
    var milestoneToComplete: Milestone?

    // MARK: - Appointment Nudge Dismissals (Persisted)

    /// Persisted dismissals for appointment nudges (7-day cooldown per milestone)
    /// Note: We use a separate tracked property to trigger UI updates since @AppStorage
    /// doesn't participate in @Observable tracking.
    @ObservationIgnored @AppStorage("appointmentNudgeDismissals") private var appointmentNudgeDismissalsData: Data = Data()

    /// Tracked property to trigger UI re-render when dismissal changes
    private var appointmentNudgeDismissedVersion: Int = 0

    // MARK: - Dependencies

    @ObservationIgnored private let timelineViewModel: TimelineViewModel
    @ObservationIgnored private let eventStore: EventStore
    @ObservationIgnored private let routineStore: RoutineStore
    @ObservationIgnored private let milestoneStore: MilestoneStore
    @ObservationIgnored private let appointmentStore: AppointmentStore
    @ObservationIgnored private let trainingMasteryStore: TrainingMasteryStore

    @ObservationIgnored private let tipGenerator = VetVisitTipGenerator()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        timelineViewModel: TimelineViewModel,
        eventStore: EventStore,
        routineStore: RoutineStore,
        milestoneStore: MilestoneStore,
        appointmentStore: AppointmentStore,
        trainingMasteryStore: TrainingMasteryStore
    ) {
        self.timelineViewModel = timelineViewModel
        self.eventStore = eventStore
        self.routineStore = routineStore
        self.milestoneStore = milestoneStore
        self.appointmentStore = appointmentStore
        self.trainingMasteryStore = trainingMasteryStore
    }

    // MARK: - Crate Nudge

    /// Whether to show the crate nudge card
    var shouldShowCrateNudge: Bool {
        // Check if dismissed today
        if let dismissedDate = dismissedCrateNudgeDate,
           Calendar.current.isDateInToday(dismissedDate) {
            return false
        }

        return NudgeCalculations.shouldShowCrateNudge(
            sleepState: timelineViewModel.currentSleepState,
            todayEvents: timelineViewModel.events,
            allEvents: eventStore.events
        )
    }

    func dismissCrateNudge() {
        dismissedCrateNudgeDate = Date()
    }

    // MARK: - Walk Target Nudge

    /// Whether to show the walk target nudge card
    var shouldShowWalkTargetNudge: Bool {
        NudgeCalculations.shouldShowWalkTargetNudge(
            walkStats: timelineViewModel.walkStats,
            dismissedDate: dismissedWalkTargetNudgeDate
        )
    }

    func dismissWalkTargetNudge() {
        walkTargetNudgeDismissedTimestamp = Date().timeIntervalSince1970
        walkTargetNudgeDismissedVersion += 1
    }

    // MARK: - Grooming Nudge

    /// Overdue grooming activities to show in nudge card
    /// Returns empty if dismissed today
    var overdueGroomingActivities: [GroomingActivity] {
        // Check if dismissed today
        if let dismissedDate = dismissedGroomingNudgeDate,
           Calendar.current.isDateInToday(dismissedDate) {
            return []
        }
        return routineStore.overdueGroomingActivities
    }

    func dismissGroomingNudge() {
        dismissedGroomingNudgeDate = Date()
    }

    func markGroomingComplete(_ activity: GroomingActivity) {
        routineStore.markGroomingCompleted(activity)
    }

    // MARK: - Potty Status Card

    /// Whether to show the potty status card based on crate training mastery and urgency
    /// - First week: Only show after 3+ potty events (progressive disclosure)
    /// - If crate training is mastered, don't show (puppy can hold it)
    /// - If not mastered, only show when < 30 minutes remaining or already urgent/overdue
    var shouldShowPottyStatusCard: Bool {
        // First week progressive disclosure: need 3+ potty events
        guard FirstWeekExperienceService.shared.shouldShowPottyPredictions else {
            return false
        }

        // Don't show if crate training is mastered
        if trainingMasteryStore.crateTrainingMastered {
            return false
        }

        // Check minutes remaining based on urgency level
        switch timelineViewModel.pottyPrediction.urgency {
        case .soon, .overdue, .postAccident:
            // Always show when urgent
            return true
        case .attention(let minutesRemaining):
            // Attention is 10-20 min, always < 30
            return minutesRemaining < 30
        case .normal(let minutesRemaining):
            // Only show if < 30 minutes remaining
            return minutesRemaining < 30
        case .justWent, .unknown, .coverageGap:
            // Don't show for these states
            return false
        }
    }

    // MARK: - Vet Visit Tips

    /// Upcoming vet appointment within 3 days
    var upcomingVetAppointment: DogAppointment? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let threeDaysFromNow = calendar.date(byAdding: .day, value: 3, to: today) else { return nil }

        let vetTypes: [AppointmentType] = [.vetCheckup, .vetVaccination, .vetEmergency, .vetSurgery]
        return appointmentStore.appointments
            .filter { vetTypes.contains($0.appointmentType) }
            .filter { appointment in
                let appointmentDay = calendar.startOfDay(for: appointment.startDate)
                return appointmentDay >= today && appointmentDay <= threeDaysFromNow
            }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    /// Generated tips for the upcoming vet visit
    var vetVisitTips: [VetVisitTip] {
        guard let appointment = upcomingVetAppointment,
              let profile = timelineViewModel.profileStore.profile else {
            return []
        }

        let recentSymptoms = HealthSymptomStore.shared.recentSymptoms()
        return tipGenerator.generateTips(
            for: profile,
            appointment: appointment,
            recentSymptoms: recentSymptoms,
            conditions: profile.healthConditions
        )
    }

    // MARK: - Appointment Nudge

    /// Decoded dismissals dictionary from AppStorage
    private var appointmentNudgeDismissals: [String: Date] {
        // Reference tracked version to participate in observation
        _ = appointmentNudgeDismissedVersion
        guard !appointmentNudgeDismissalsData.isEmpty else { return [:] }
        return (try? JSONDecoder().decode([String: Date].self, from: appointmentNudgeDismissalsData)) ?? [:]
    }

    /// Top appointment nudge candidate (if any)
    var appointmentNudgeCandidate: AppointmentNudgeCandidate? {
        guard let birthDate = timelineViewModel.profileStore.profile?.birthDate else { return nil }

        return AppointmentNudgeCalculations.topNudgeCandidate(
            milestones: milestoneStore.milestones,
            appointments: appointmentStore.appointments,
            birthDate: birthDate,
            dismissals: appointmentNudgeDismissals
        )
    }

    /// Whether to show the nap context message for the appointment nudge
    var shouldShowAppointmentNudgeNapContext: Bool {
        PuppyContextUtility.shouldShowNapContextMessage(
            sleepState: timelineViewModel.currentSleepState,
            events: timelineViewModel.events
        )
    }

    /// Dismiss the appointment nudge for a milestone
    func dismissAppointmentNudge(for labelKey: String) {
        var dismissals = appointmentNudgeDismissals
        dismissals[labelKey] = Date()
        if let encoded = try? JSONEncoder().encode(dismissals) {
            appointmentNudgeDismissalsData = encoded
        }
        appointmentNudgeDismissedVersion += 1
    }

    /// Create appointment prefill from nudge candidate
    func createAppointmentPrefill(for candidate: AppointmentNudgeCandidate) -> AppointmentPrefill? {
        guard let birthDate = timelineViewModel.profileStore.profile?.birthDate else { return nil }

        return AppointmentPrefill(
            appointmentType: candidate.appointmentType,
            title: candidate.milestone.localizedLabel,
            notes: nil,
            linkedMilestoneID: candidate.milestone.id,
            suggestedDate: AppointmentNudgeCalculations.suggestedAppointmentDate(for: candidate, birthDate: birthDate)
        )
    }

    // MARK: - Milestone Completion

    func completeMilestone(
        _ milestone: Milestone,
        notes: String?,
        photoID: UUID?,
        linkedContactID: UUID?,
        completionDate: Date
    ) {
        milestoneStore.completeMilestone(
            milestone,
            notes: notes,
            photoID: photoID,
            linkedContactID: linkedContactID,
            completionDate: completionDate
        )
        milestoneToComplete = nil
    }

    // MARK: - Convenience Accessors

    var crateTrainingMastered: Bool {
        trainingMasteryStore.crateTrainingMastered
    }

    // MARK: - Recent Moment Card

    /// The most recent moment event with a photo
    var mostRecentMoment: PuppyEvent? {
        eventStore.events
            .filter { $0.type == .moment && $0.photo != nil }
            .sorted { $0.time > $1.time }
            .first
    }

    /// Whether to show the recent moment card
    /// - Shows if there's a moment with a photo
    /// - Hidden if the user dismissed this specific moment (reappears when a newer moment is posted)
    var shouldShowRecentMomentCard: Bool {
        guard let moment = mostRecentMoment else { return false }

        // If user dismissed a moment, don't show if it's the same moment
        if let dismissedID = dismissedRecentMomentID {
            return moment.id != dismissedID
        }

        return true
    }

    /// Dismiss the recent moment card until a newer moment is posted
    func dismissRecentMomentCard() {
        guard let moment = mostRecentMoment else { return }
        dismissedRecentMomentIDString = moment.id.uuidString
    }
}
