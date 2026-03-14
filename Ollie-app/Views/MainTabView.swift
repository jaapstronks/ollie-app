//
//  MainTabView.swift
//  Otis-app
//
//  Main tab navigation view with 5 tabs and floating action button
//

import OtisShared
import SwiftUI

/// Main tab navigation with Today, Train, Explore, Schedule, Health tabs
struct MainTabView: View {
    @Binding var selectedTab: MainTab
    let eventStore: EventStore
    let profileStore: ProfileStore
    let dataImporter: DataImporter
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var notificationService: NotificationService
    var spotStore: SpotStore
    var medicationStore: MedicationStore
    var socializationStore: SocializationStore
    var milestoneStore: MilestoneStore
    var documentStore: DocumentStore
    var contactStore: ContactStore
    var appointmentStore: AppointmentStore
    var routineStore: RoutineStore
    @ObservedObject var trainingMasteryStore: TrainingMasteryStore
    var onAddDog: (() -> Void)?

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var foodRecallService: FoodRecallService

    @State private var viewModel: TimelineViewModel
    @State private var momentsViewModel: MomentsViewModel
    @StateObject private var mediaCaptureViewModel = MediaCaptureViewModel(mediaStore: MediaStore())
    @State private var memoriesViewModel: MemoriesViewModel
    @State private var todayStatusViewModel: TodayStatusViewModel

    @State private var showingSettings = false
    @State private var showingFirstSessionHandoff = false
    @State private var showGuidedTour = false
    @State private var selectedPhotoEvent: PuppyEvent?
    @State private var showingArrivalPhotoPrompt = false
    @State private var spotlightTargetFrames: [SpotlightTargetID: CGRect] = [:]

    @AppStorage("hasShownArrivalPhotoPrompt") private var hasShownArrivalPhotoPrompt = false
    @AppStorage(UserPreferences.Key.showFloatingClicker.rawValue) private var showFloatingClicker = false
    @AppStorage(UserPreferences.Key.needsFirstSessionHandoff.rawValue) private var needsFirstSessionHandoff = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initialization

    init(
        selectedTab: Binding<MainTab>,
        eventStore: EventStore,
        profileStore: ProfileStore,
        dataImporter: DataImporter,
        weatherService: WeatherService,
        notificationService: NotificationService,
        spotStore: SpotStore,
        medicationStore: MedicationStore,
        socializationStore: SocializationStore,
        milestoneStore: MilestoneStore,
        documentStore: DocumentStore,
        contactStore: ContactStore,
        appointmentStore: AppointmentStore,
        routineStore: RoutineStore,
        trainingMasteryStore: TrainingMasteryStore,
        onAddDog: (() -> Void)? = nil
    ) {
        self._selectedTab = selectedTab
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.dataImporter = dataImporter
        self.weatherService = weatherService
        self.notificationService = notificationService
        self.spotStore = spotStore
        self.medicationStore = medicationStore
        self.socializationStore = socializationStore
        self.milestoneStore = milestoneStore
        self.documentStore = documentStore
        self.contactStore = contactStore
        self.appointmentStore = appointmentStore
        self.routineStore = routineStore
        self.trainingMasteryStore = trainingMasteryStore
        self.onAddDog = onAddDog

        let viewModel = TimelineViewModel(
            eventStore: eventStore,
            profileStore: profileStore,
            notificationService: notificationService,
            medicationStore: medicationStore,
            appointmentStore: appointmentStore
        )
        self._viewModel = State(initialValue: viewModel)
        self._momentsViewModel = State(initialValue: MomentsViewModel(
            eventStore: eventStore
        ))
        self._memoriesViewModel = State(initialValue: MemoriesViewModel(
            eventStore: eventStore
        ))
        self._todayStatusViewModel = State(initialValue: TodayStatusViewModel(
            timelineViewModel: viewModel,
            eventStore: eventStore,
            routineStore: routineStore,
            milestoneStore: milestoneStore,
            appointmentStore: appointmentStore,
            trainingMasteryStore: trainingMasteryStore
        ))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            activityBanner

            GeometryReader { proxy in
                let safeAreaBottom = proxy.safeAreaInsets.bottom

                ZStack(alignment: .bottom) {
                    tabContent
                    floatingButtons(safeAreaBottom: safeAreaBottom)
                    celebrationOverlay

                    // Guided tour overlay
                    if showGuidedTour {
                        SpotlightTourOverlay(
                            selectedTab: $selectedTab,
                            isActive: $showGuidedTour,
                            targetFrames: spotlightTargetFrames
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onPreferenceChange(SpotlightTargetPreferenceKey.self) { frames in
                    spotlightTargetFrames = frames
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
        .sheet(isPresented: $showingFirstSessionHandoff) {
            firstSessionHandoffSheet
        }
        .timelineSheetHandling(
            viewModel: viewModel,
            mediaCaptureViewModel: mediaCaptureViewModel,
            selectedPhotoEvent: $selectedPhotoEvent,
            reduceMotion: reduceMotion,
            spotStore: spotStore,
            locationManager: locationManager
        )
        .sheet(isPresented: $showingArrivalPhotoPrompt) {
            arrivalPhotoPromptSheet
        }
        .onAppear {
            checkForArrivalPhotoPrompt()
            if needsFirstSessionHandoff {
                showingFirstSessionHandoff = true
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            Analytics.track(.tabSelected, properties: [
                "tab_index": newTab.rawValue,
                "tab_name": newTab.analyticsName
            ])
        }
        .onChange(of: viewModel.sheetCoordinator.activeSheet) { _, newSheet in
            if newSheet == nil {
                viewModel.flushPendingCelebrationIfNeeded()
            }
        }
        .onChange(of: showingSettings) { _, isShowing in
            if isShowing {
                Analytics.track(.settingsOpened)
            }
        }
    }
}

// MARK: - View Components

private extension MainTabView {

    @ViewBuilder
    var activityBanner: some View {
        if let activity = viewModel.currentActivity {
            CompactActivityBanner(
                activity: activity,
                onTap: {
                    selectedTab = .today
                    viewModel.sheetCoordinator.presentSheet(.endActivity)
                }
            )
        }
    }

    var tabContent: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                viewModel: viewModel,
                memoriesViewModel: memoriesViewModel,
                appointmentStore: appointmentStore,
                statusViewModel: todayStatusViewModel,
                weatherService: weatherService,
                onSettingsTap: { showingSettings = true },
                onNavigateToAppointments: { selectedTab = .schedule },
                onNavigateToTrain: { selectedTab = .train },
                onAddDog: onAddDog
            )
            .tabItem {
                Label(Strings.Tabs.today, systemImage: "pawprint.fill")
            }
            .tag(MainTab.today)

            TrainTabView(
                viewModel: viewModel,
                onSettingsTap: { showingSettings = true }
            )
            .tabItem {
                Label(Strings.Tabs.train, systemImage: "graduationcap.fill")
            }
            .tag(MainTab.train)

            PlacesTabView(
                spotStore: spotStore,
                contactStore: contactStore,
                momentsViewModel: momentsViewModel,
                locationManager: locationManager,
                appointmentStore: appointmentStore,
                onSettingsTap: { showingSettings = true },
                onAddMoment: {
                    viewModel.sheetCoordinator.presentSheet(.momentSourcePicker)
                }
            )
            .tabItem {
                Label(Strings.Tabs.explore, systemImage: "map.fill")
            }
            .tag(MainTab.explore)

            CalendarTabView(
                milestoneStore: milestoneStore,
                appointmentStore: appointmentStore,
                socializationStore: socializationStore,
                contactStore: contactStore,
                onSettingsTap: { showingSettings = true },
                onNavigateToSocialization: { selectedTab = .train }
            )
            .tabItem {
                Label(Strings.Tabs.schedule, systemImage: "calendar.badge.clock")
            }
            .tag(MainTab.schedule)

            HealthTabView(
                viewModel: viewModel,
                momentsViewModel: momentsViewModel,
                onSettingsTap: { showingSettings = true }
            )
            .tabItem {
                Label(Strings.Tabs.health, systemImage: "heart.text.square.fill")
            }
            .tag(MainTab.health)
        }
        .overlay(alignment: .bottom) {
            // Invisible spotlight targets for tab bar items
            TabBarSpotlightTargets()
        }
    }

    @ViewBuilder
    func floatingButtons(safeAreaBottom: CGFloat) -> some View {
        // FAB (only on Today tab)
        if selectedTab == .today {
            HStack {
                Spacer()
                FABButton(
                    sleepState: viewModel.currentSleepState,
                    currentActivity: viewModel.currentActivity,
                    onTap: { viewModel.showAllEvents() },
                    onQuickAction: { eventType, location in
                        if let location {
                            viewModel.quickLogWithLocation(type: eventType, location: location)
                        } else {
                            viewModel.quickLog(type: eventType)
                        }
                    },
                    onEndActivity: {
                        viewModel.sheetCoordinator.presentSheet(.endActivity)
                    }
                )
                .padding(.trailing, 16)
                .padding(.bottom, 60 + safeAreaBottom)
            }
        }

        // Floating Clicker Button (enabled via settings)
        if showFloatingClicker {
            VStack {
                Spacer()
                HStack {
                    FloatingClickerButton()
                        .padding(.leading, 16)
                        .padding(.bottom, 100 + safeAreaBottom)
                    Spacer()
                }
            }
        }
    }

    var celebrationOverlay: some View {
        CelebrationView(
            style: viewModel.celebrationStyle,
            streakCount: viewModel.celebrationStreakCount,
            isActive: $viewModel.showCelebration
        )
        .ignoresSafeArea()
        .zIndex(10_000)
    }

    var settingsSheet: some View {
        NavigationStack {
            SettingsView(
                profileStore: profileStore,
                dataImporter: dataImporter,
                eventStore: eventStore,
                notificationService: notificationService,
                medicationStore: medicationStore,
                documentStore: documentStore,
                contactStore: contactStore,
                foodRecallService: foodRecallService,
                onAddDog: {
                    showingSettings = false
                    onAddDog?()
                },
                onTriggerTour: {
                    showGuidedTour = true
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        showingSettings = false
                    }
                }
            }
        }
    }

    var firstSessionHandoffSheet: some View {
        FirstSessionHandoffSheet(
            onLogFirstEvent: {
                showingFirstSessionHandoff = false
                needsFirstSessionHandoff = false
                selectedTab = .today
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.2))
                    viewModel.showAllEvents()
                }
            },
            onViewTimeline: {
                showingFirstSessionHandoff = false
                needsFirstSessionHandoff = false
                selectedTab = .today
            },
            onDismiss: {
                showingFirstSessionHandoff = false
                needsFirstSessionHandoff = false
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    var arrivalPhotoPromptSheet: some View {
        if let profile = profileStore.profile {
            ArrivalPhotoPromptSheet(
                puppyName: profile.name,
                onTakePhoto: {
                    showingArrivalPhotoPrompt = false
                    hasShownArrivalPhotoPrompt = true
                    showingSettings = true
                },
                onDismiss: {
                    showingArrivalPhotoPrompt = false
                    hasShownArrivalPhotoPrompt = true
                }
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Private Helpers

private extension MainTabView {

    func checkForArrivalPhotoPrompt() {
        guard !SeedData.isUITesting else { return }

        guard !hasShownArrivalPhotoPrompt,
              let profile = profileStore.profile,
              profile.profilePhotoFilename == nil else {
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let homeDate = calendar.startOfDay(for: profile.homeDate)

        if homeDate <= today {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.0))
                showingArrivalPhotoPrompt = true
            }
        }
    }
}
