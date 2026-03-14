//
//  ContentView.swift
//  Otis-app
//

import StoreKit
import SwiftUI
import OtisShared

/// Root view with tab navigation or onboarding
struct ContentView: View {
    @Environment(ProfileStore.self) var profileStore
    @Environment(EventStore.self) var eventStore
    @EnvironmentObject var dataImporter: DataImporter
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(SpotStore.self) var spotStore
    @Environment(MedicationStore.self) var medicationStore
    @Environment(SocializationStore.self) var socializationStore
    @Environment(MilestoneStore.self) var milestoneStore
    @Environment(DocumentStore.self) var documentStore
    @Environment(ContactStore.self) var contactStore
    @Environment(AppointmentStore.self) var appointmentStore
    @Environment(RoutineStore.self) var routineStore
    @EnvironmentObject var trainingMasteryStore: TrainingMasteryStore
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var foodRecallService: FoodRecallService

    @State private var showOnboarding = false
    @State private var showAddProfileOnboarding = false
    @State private var sharedProfileWelcomeName: String?
    @State private var showSharedProfileWelcome = false
    @State private var showExpiredTrialSheet = false
    @State private var showOtisPlusSheet = false
    @State private var showPhaseTransitionSheet = false
    @State private var showUserProfileSetupSheet = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @AppStorage(UserPreferences.Key.lastSelectedTab.rawValue) private var selectedTabRawValue = MainTab.today.rawValue
    @AppStorage(UserPreferences.Key.needsFirstSessionHandoff.rawValue) private var needsFirstSessionHandoff = false
    @AppStorage(UserPreferences.Key.hasCompletedOnboarding.rawValue) private var hasCompletedOnboarding = false
    @StateObject private var navigationState = AppNavigationState()
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue
    @State private var showLaunchScreen = true
    @Environment(\.scenePhase) private var scenePhase

    private var colorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    /// Determine if we should show onboarding
    /// - Skip if running in UI testing mode
    /// - Skip if user is a participant (accepted a share invitation)
    /// - Skip if user already has a profile
    private var shouldShowOnboarding: Bool {
        // Never show onboarding while loading
        guard !profileStore.isLoading else { return false }

        // Skip onboarding in UI testing mode (for automated screenshots)
        if SeedData.isUITesting {
            return false
        }

        // Don't show onboarding if user is a participant with shared data
        if cloudKit.isParticipant {
            return false
        }

        // Show onboarding only if no profile exists (and not forced)
        return !profileStore.hasProfile || showOnboarding
    }

    var body: some View {
        ZStack {
            Group {
                if profileStore.isLoading {
                    // Loading state
                    LaunchScreen()
                } else if shouldShowOnboarding {
                    // Onboarding for new users (not for participants)
                    OnboardingView(profileStore: profileStore) {
                        hasCompletedOnboarding = true
                        needsFirstSessionHandoff = true
                        showOnboarding = false
                        // Start first-week experience tracking
                        FirstWeekExperienceService.shared.markOnboardingCompleted()
                    }
                } else {
                    // Main app with tabs
                    MainTabView(
                        selectedTab: $navigationState.selectedTab,
                        eventStore: eventStore,
                        profileStore: profileStore,
                        dataImporter: dataImporter,
                        weatherService: weatherService,
                        notificationService: notificationService,
                        spotStore: spotStore,
                        medicationStore: medicationStore,
                        socializationStore: socializationStore,
                        milestoneStore: milestoneStore,
                        documentStore: documentStore,
                        contactStore: contactStore,
                        appointmentStore: appointmentStore,
                        routineStore: routineStore,
                        trainingMasteryStore: trainingMasteryStore,
                        onAddDog: {
                            showAddProfileOnboarding = true
                        }
                    )
                    .task {
                        // Proactively request notification permissions if not determined
                        // This handles cases where onboarding was skipped (e.g., reinstall with seed data)
                        if notificationService.authorizationStatus == .notDetermined {
                            _ = await notificationService.requestAuthorization()
                        }
                    }
                }
            }

            // Launch screen overlay
            if showLaunchScreen {
                LaunchScreen()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Restore last selected tab from persisted raw value.
            navigationState.selectedTab = MainTab(rawValue: selectedTabRawValue) ?? .today

            // Dismiss launch screen after brief delay
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                withAnimation(.easeOut(duration: 0.3)) {
                    showLaunchScreen = false
                }
            }
        }
        .onChange(of: navigationState.selectedTab) { _, newTab in
            selectedTabRawValue = newTab.rawValue
        }
        // Refresh data when app returns to foreground to catch CloudKit syncs
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                eventStore.refreshOnForeground()
            }
        }
        // Listen for share acceptance to skip onboarding and reload profile
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareAccepted)) { _ in
            // Force dismiss onboarding if it was showing
            showOnboarding = false

            // Check if user profile needs setup after a short delay
            // (to let the share acceptance alert dismiss first)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                if UserIdentityStore.shared.needsProfileSetup {
                    showUserProfileSetupSheet = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sharedProfileAutoActivated)) { notification in
            if let name = notification.userInfo?["profileName"] as? String, !name.isEmpty {
                sharedProfileWelcomeName = name
                showSharedProfileWelcome = true
            }
        }
        .alert(Strings.CloudSharing.sharedDogReadyTitle, isPresented: $showSharedProfileWelcome) {
            Button(Strings.Common.ok, role: .cancel) {}
        } message: {
            Text(Strings.CloudSharing.sharedDogReadyMessage(name: sharedProfileWelcomeName ?? Strings.CloudSharing.sharedData))
        }
        // Sheet for adding a new profile (multi-puppy)
        .fullScreenCover(isPresented: $showAddProfileOnboarding) {
            OnboardingView(profileStore: profileStore, isAddingProfile: true) {
                showAddProfileOnboarding = false
            }
        }
        // Expired trial sheet
        .fullScreenCover(isPresented: $showExpiredTrialSheet) {
            ExpiredTrialSheet(
                puppyName: profileStore.profile?.name ?? "",
                eventCount: eventStore.events.count,
                trainingSessionCount: eventStore.events.filter { $0.type == .training }.count,
                daysTracking: calculateDaysTracking(),
                monthlyPrice: subscriptionManager.monthlyProduct?.displayPrice,
                onSubscribe: {
                    showExpiredTrialSheet = false
                    // Show paywall sheet after a brief delay for sheet transition
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.3))
                        showOtisPlusSheet = true
                    }
                    Analytics.track(.trialExpiredSubscribeTapped)
                },
                onDismiss: {
                    showExpiredTrialSheet = false
                    Analytics.track(.trialExpiredDismissed)
                }
            )
        }
        // Otis+ paywall sheet (opened from expired trial or other upsells)
        .sheet(isPresented: $showOtisPlusSheet) {
            OtisPlusSheet(
                onDismiss: {
                    showOtisPlusSheet = false
                },
                onSubscribed: {
                    showOtisPlusSheet = false
                }
            )
        }
        // Phase transition celebration sheet
        .fullScreenCover(isPresented: $showPhaseTransitionSheet) {
            if let profile = profileStore.profile {
                PhaseTransitionSheet(profile: profile) { applyDefaults in
                    acknowledgePhaseTransition(applyNotificationDefaults: applyDefaults)
                }
            }
        }
        // User profile setup sheet (shown after share acceptance if needed)
        .sheet(isPresented: $showUserProfileSetupSheet) {
            NavigationStack {
                UserProfileSetupSheet(
                    userIdentityStore: UserIdentityStore.shared,
                    onComplete: {
                        showUserProfileSetupSheet = false
                    },
                    onSkip: {
                        showUserProfileSetupSheet = false
                    }
                )
                .navigationTitle(Strings.UserProfile.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Strings.Common.cancel) {
                            showUserProfileSetupSheet = false
                        }
                    }
                }
            }
        }
        .task {
            // Check for expired local trial on app launch
            if subscriptionManager.isLocalTrialExpired && hasCompletedOnboarding {
                showExpiredTrialSheet = true
            }
            // Check for migration trial for existing users
            if !hasCompletedOnboarding {
                // Will be handled after onboarding
            } else if TrialManager.shared.hasNeverStartedTrial && !TrialManager.shared.hasDeclinedTrial {
                TrialManager.shared.grantMigrationTrialIfEligible(eventCount: eventStore.events.count)
            }

            // Check for lifecycle phase transition
            checkForPhaseTransition()
        }
        .onChange(of: profileStore.profile?.lifecyclePhase) { _, _ in
            // Also check when profile changes (e.g., after sync)
            checkForPhaseTransition()
        }
        .preferredColorScheme(colorScheme)
    }

    /// Calculate how many unique days the user has been tracking events
    private func calculateDaysTracking() -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(eventStore.events.map { calendar.startOfDay(for: $0.time) })
        return uniqueDays.count
    }

    // MARK: - Phase Transition

    /// Check if dog has entered a new lifecycle phase that hasn't been acknowledged
    private func checkForPhaseTransition() {
        guard hasCompletedOnboarding,
              let profile = profileStore.profile,
              !profile.isDeceased else {
            return
        }

        let currentPhase = profile.lifecyclePhase
        let acknowledgedPhase = profile.lastAcknowledgedPhase

        // Don't show sheet for puppy phase (initial state)
        guard currentPhase != .puppy else { return }

        // Show sheet if current phase differs from last acknowledged phase
        if acknowledgedPhase != currentPhase {
            showPhaseTransitionSheet = true
        }
    }

    /// Acknowledge the phase transition and optionally apply notification defaults
    private func acknowledgePhaseTransition(applyNotificationDefaults: Bool) {
        guard var profile = profileStore.profile else { return }

        // Update the acknowledged phase
        profile.lastAcknowledgedPhase = profile.lifecyclePhase

        // Optionally apply phase-specific notification defaults
        if applyNotificationDefaults {
            applyPhaseNotificationDefaults(for: &profile)
        }

        // Save the updated profile
        profileStore.saveProfile(profile)

        // Dismiss the sheet
        showPhaseTransitionSheet = false

        // Track the event
        Analytics.track(.phaseTransitionAcknowledged, properties: [
            "phase": profile.lifecyclePhase.rawValue,
            "applied_defaults": applyNotificationDefaults
        ])
    }

    /// Apply recommended notification settings for the current lifecycle phase
    private func applyPhaseNotificationDefaults(for profile: inout PuppyProfile) {
        var settings = profile.notificationSettings

        switch profile.lifecyclePhase {
        case .puppy:
            // Intensive care settings (shouldn't reach here, but for completeness)
            settings.pottyReminders.isEnabled = true
            settings.napReminders.isEnabled = true
            settings.walkReminders.isEnabled = true
            settings.mealReminders.isEnabled = true

        case .teenage:
            // Less potty focus, more walk/training
            settings.pottyReminders.isEnabled = false
            settings.napReminders.isEnabled = false
            settings.walkReminders.isEnabled = true
            settings.mealReminders.isEnabled = true

        case .adult:
            // Maintenance mode - scheduled reminders only
            settings.pottyReminders.isEnabled = false
            settings.napReminders.isEnabled = false
            settings.walkReminders.isEnabled = true
            settings.mealReminders.isEnabled = true

        case .senior:
            // Health-focused - medication and wellness
            settings.pottyReminders.isEnabled = false
            settings.napReminders.isEnabled = false
            settings.walkReminders.isEnabled = true
            settings.mealReminders.isEnabled = true
            settings.appointmentReminders.isEnabled = true
        }

        profile.notificationSettings = settings
    }
}

#Preview {
    ContentView()
        .environment(ProfileStore())
        .environment(EventStore())
        .environmentObject(DataImporter())
        .environmentObject(WeatherService())
        .environmentObject(NotificationService())
        .environment(SpotStore())
        .environmentObject(LocationManager())
        .environment(MedicationStore())
        .environment(SocializationStore())
        .environment(MilestoneStore())
        .environment(DocumentStore())
        .environment(ContactStore())
        .environment(AppointmentStore())
        .environment(RoutineStore())
        .environmentObject(CloudKitService.shared)
}
