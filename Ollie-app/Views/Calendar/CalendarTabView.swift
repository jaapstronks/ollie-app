//
//  CalendarTabView.swift
//  Otis-app
//
//  Schedule tab showing age, appointments, milestones, and contacts

import SwiftUI
import OtisShared

/// Main Schedule tab view displaying age header, appointments, milestones, and contacts
struct CalendarTabView: View {
    @ObservedObject var milestoneStore: MilestoneStore
    @ObservedObject var appointmentStore: AppointmentStore
    @ObservedObject var socializationStore: SocializationStore
    @ObservedObject var contactStore: ContactStore
    let onSettingsTap: () -> Void
    let onNavigateToSocialization: () -> Void

    @EnvironmentObject var profileStore: ProfileStore
    @StateObject private var achievementService = AchievementService.shared

    // View mode state with persistence - using new key to avoid migration issues
    @AppStorage("scheduleViewMode") private var viewMode: CalendarViewMode = .calendar

    // First-visit tip tracking
    @AppStorage("hasSeenCalendarTip") private var hasSeenCalendarTip = false

    @State private var showAppointmentsView = false
    @State private var showAddAppointment = false
    @State private var showAddContact = false
    @State private var showImportContact = false
    @State private var showDevelopmentJourney = false
    @State private var showSocializationWindow = false
    @State private var selectedMilestone: Milestone?
    @State private var selectedAppointment: DogAppointment?
    @State private var showCelebration = false
    @State private var celebrationStyle: CelebrationPreset = .milestone
    @State private var showWeekDetail = false
    @State private var selectedWeek: WeeklyProgress?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                VStack(spacing: 0) {
                    // View mode toggle
                    CalendarViewModeToggle(mode: $viewMode)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGroupedBackground))

                    // Content based on view mode
                    switch viewMode {
                    case .calendar:
                        CalendarGridView(
                            appointmentStore: appointmentStore,
                            milestoneStore: milestoneStore,
                            socializationStore: socializationStore,
                            profile: profileStore.profile,
                            onAppointmentTap: { appointment in
                                selectedAppointment = appointment
                            },
                            onMilestoneTap: { milestone in
                                selectedMilestone = milestone
                            },
                            onSocializationTap: onNavigateToSocialization,
                            onDevelopmentTap: {
                                showDevelopmentJourney = true
                            },
                            onSocializationWindowTap: {
                                showSocializationWindow = true
                            }
                        )
                        .adaptiveContainer(maxWidth: iPadLayout.maxWideContentWidth)
                    case .contacts:
                        ContactsView(
                            contactStore: contactStore,
                            appointmentStore: appointmentStore
                        )
                        .adaptiveContainer()
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(Strings.Tabs.schedule)
                .navigationBarTitleDisplayMode(.inline)
                .profileToolbar(profile: profileStore.profile, action: onSettingsTap)
            .navigationDestination(isPresented: $showAppointmentsView) {
                AppointmentsView(appointmentStore: appointmentStore)
            }
            .sheet(isPresented: $showDevelopmentJourney) {
                DevelopmentJourneySheet(
                    onNavigateToSocialization: {
                        showDevelopmentJourney = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showSocializationWindow = true
                        }
                    },
                    onNavigateToMedical: nil
                )
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )
            }
            .sheet(isPresented: $showSocializationWindow) {
                SocializationWindowSheet(
                    onNavigateToDevelopment: {
                        showSocializationWindow = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showDevelopmentJourney = true
                        }
                    },
                    onLogExposure: {
                        showSocializationWindow = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onNavigateToSocialization()
                        }
                    }
                )
                .environmentObject(socializationStore)
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )
            }
            .sheet(item: $selectedAppointment) { appointment in
                NavigationStack {
                    AppointmentDetailView(
                        appointment: appointment,
                        appointmentStore: appointmentStore
                    )
                    .environmentObject(contactStore)
                }
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )
            }
            .sheet(isPresented: $showAddAppointment) {
                AddEditAppointmentSheet(appointmentStore: appointmentStore)
                    .environmentObject(contactStore)
                    .adaptivePresentationDetents(
                        compact: [.large],
                        regular: [.medium, .large]
                    )
            }
            .sheet(item: $selectedMilestone) { milestone in
                MilestoneCompletionSheet(
                    milestone: milestone,
                    onDismiss: { selectedMilestone = nil },
                    onComplete: { notes, photoID, vetClinic, completionDate in
                        milestoneStore.completeMilestone(
                            milestone,
                            notes: notes,
                            photoID: photoID,
                            vetClinicName: vetClinic,
                            completionDate: completionDate
                        )

                        // Check for achievement
                        if let achievement = achievementService.checkMilestoneCompletion(milestone: milestone) {
                            selectedMilestone = nil
                            // Delay celebration to allow sheet dismissal
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                triggerCelebration(for: achievement)
                            }
                        } else {
                            selectedMilestone = nil
                        }
                    }
                )
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )
            }
            // Week detail sheet for socialization timeline
            .sheet(isPresented: $showWeekDetail) {
                if let week = selectedWeek, let profile = profileStore.profile {
                    let rawProgress = socializationStore.categoryProgressForWeek(week, profile: profile)
                    let categoryProgress = rawProgress.map { item in
                        CategoryWeekProgress(
                            id: item.category.id,
                            category: item.category,
                            count: item.count,
                            total: item.total
                        )
                    }

                    WeekDetailSheet(
                        weekProgress: week,
                        categoryProgress: categoryProgress,
                        focusSuggestions: socializationStore.focusSuggestions(for: week, profile: profile),
                        onLogExposure: {
                            // Navigate to socialization after dismissing
                            showWeekDetail = false
                            onNavigateToSocialization()
                        }
                    )
                    .adaptivePresentationDetents(
                        compact: [.large],
                        regular: [.medium, .large]
                    )
                }
            }
            }

            // Floating Action Button
            scheduleFAB
        }
        .sheet(isPresented: $showAddContact) {
            AddEditContactSheet(contactStore: contactStore)
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )
        }
        .sheet(isPresented: $showImportContact) {
            ContactImportSheet(contactStore: contactStore)
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )
        }
        .overlay {
            CelebrationView(style: celebrationStyle, isActive: $showCelebration)
                .ignoresSafeArea()
                .zIndex(10_000)
        }
    }

    // MARK: - Floating Action Button

    @ViewBuilder
    private var scheduleFAB: some View {
        if viewMode == .contacts {
            // Menu FAB for contacts - shows add and import options
            SimpleFAB(accessibilityLabel: Strings.Contacts.addContact) {
                Menu {
                    Button {
                        showAddContact = true
                    } label: {
                        Label(Strings.Contacts.addContact, systemImage: "plus")
                    }

                    Button {
                        showImportContact = true
                    } label: {
                        Label(Strings.Contacts.importFromContacts, systemImage: "person.crop.circle.badge.plus")
                    }
                } label: {
                    FABLabel()
                }
            }
        } else {
            // Simple FAB for appointments
            SimpleFAB(accessibilityLabel: Strings.Calendar.addAppointment) {
                showAddAppointment = true
            }
        }
    }

    // MARK: - Celebration Handling

    private func triggerCelebration(for achievement: Achievement) {
        guard let effectiveTier = achievementService.determineEffectiveTier(for: achievement) else {
            // Celebrations disabled
            return
        }

        switch effectiveTier {
        case .major:
            celebrationStyle = .milestone
            showCelebration = true
        case .notable:
            celebrationStyle = .training
            showCelebration = true
        case .subtle:
            celebrationStyle = .quickLog
            showCelebration = true
        }
    }

}

// MARK: - Preview

#Preview {
    let milestoneStore = MilestoneStore()
    let appointmentStore = AppointmentStore()
    let socializationStore = SocializationStore()
    let contactStore = ContactStore()
    let profileStore = ProfileStore()

    CalendarTabView(
        milestoneStore: milestoneStore,
        appointmentStore: appointmentStore,
        socializationStore: socializationStore,
        contactStore: contactStore,
        onSettingsTap: { print("Settings tapped") },
        onNavigateToSocialization: { print("Navigate to socialization") }
    )
    .environmentObject(profileStore)
}
