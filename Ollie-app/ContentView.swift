//
//  ContentView.swift
//  Otis-app
//

import SwiftUI
import OtisShared

/// Root view with tab navigation or onboarding
struct ContentView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var dataImporter: DataImporter
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var spotStore: SpotStore
    @EnvironmentObject var medicationStore: MedicationStore
    @EnvironmentObject var socializationStore: SocializationStore
    @EnvironmentObject var milestoneStore: MilestoneStore
    @EnvironmentObject var documentStore: DocumentStore
    @EnvironmentObject var contactStore: ContactStore
    @EnvironmentObject var appointmentStore: AppointmentStore
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var foodRecallService: FoodRecallService

    @State private var showOnboarding = false
    @AppStorage(UserPreferences.Key.lastSelectedTab.rawValue) private var selectedTab = 0
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue
    @State private var showLaunchScreen = true

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
                        showOnboarding = false
                    }
                } else {
                    // Main app with tabs
                    MainTabView(
                        selectedTab: $selectedTab,
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
                        appointmentStore: appointmentStore
                    )
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
            // Dismiss launch screen after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showLaunchScreen = false
                }
            }
        }
        // Listen for share acceptance to skip onboarding and reload profile
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareAccepted)) { _ in
            // Force dismiss onboarding if it was showing
            showOnboarding = false
        }
        .preferredColorScheme(colorScheme)
    }
}

/// Wrapper view that owns the TimelineViewModel as a @StateObject
/// New structure: 5 tabs (Today, Train, Places, Schedule, Health) + FAB for logging
struct MainTabView: View {
    @Binding var selectedTab: Int
    let eventStore: EventStore
    let profileStore: ProfileStore
    let dataImporter: DataImporter
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var medicationStore: MedicationStore
    @ObservedObject var socializationStore: SocializationStore
    @ObservedObject var milestoneStore: MilestoneStore
    @ObservedObject var documentStore: DocumentStore
    @ObservedObject var contactStore: ContactStore
    @ObservedObject var appointmentStore: AppointmentStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var foodRecallService: FoodRecallService

    @StateObject private var viewModel: TimelineViewModel
    @StateObject private var momentsViewModel: MomentsViewModel
    @StateObject private var mediaCaptureViewModel = MediaCaptureViewModel(mediaStore: MediaStore())
    @StateObject private var memoriesViewModel: MemoriesViewModel
    @State private var showingSettings = false
    @State private var selectedPhotoEvent: PuppyEvent?
    @State private var showingArrivalPhotoPrompt = false
    @AppStorage("hasShownArrivalPhotoPrompt") private var hasShownArrivalPhotoPrompt = false
    @AppStorage(UserPreferences.Key.showFloatingClicker.rawValue) private var showFloatingClicker = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        selectedTab: Binding<Int>,
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
        appointmentStore: AppointmentStore
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
        // StateObject init with autoclosure ensures single creation
        self._viewModel = StateObject(wrappedValue: TimelineViewModel(
            eventStore: eventStore,
            profileStore: profileStore,
            notificationService: notificationService,
            medicationStore: medicationStore,
            appointmentStore: appointmentStore
        ))
        self._momentsViewModel = StateObject(wrappedValue: MomentsViewModel(
            eventStore: eventStore
        ))
        self._memoriesViewModel = StateObject(wrappedValue: MemoriesViewModel(
            eventStore: eventStore
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Activity banner (visible across all tabs when activity in progress)
            if let activity = viewModel.currentActivity {
                CompactActivityBanner(
                    activity: activity,
                    onTap: {
                        selectedTab = 0  // Switch to Today tab
                        viewModel.sheetCoordinator.presentSheet(.endActivity)
                    }
                )
            }

            ZStack(alignment: .bottom) {
                // Main tab content
                TabView(selection: $selectedTab) {
                // Tab 0: Today
                TodayView(
                    viewModel: viewModel,
                    memoriesViewModel: memoriesViewModel,
                    appointmentStore: appointmentStore,
                    weatherService: weatherService,
                    onSettingsTap: { showingSettings = true },
                    onNavigateToAppointments: { selectedTab = 3 },
                    onNavigateToTrain: { selectedTab = 1 }
                )
                .tabItem {
                    Label(Strings.Tabs.today, systemImage: "pawprint.fill")
                }
                .tag(0)

                // Tab 1: Train (expanded with Potty + Socialization + Skills)
                TrainTabView(
                    viewModel: viewModel,
                    onSettingsTap: { showingSettings = true }
                )
                .tabItem {
                    Label(Strings.Tabs.train, systemImage: "graduationcap.fill")
                }
                .tag(1)

                // Tab 2: Explore (spots + photo moments on map)
                PlacesTabView(
                    spotStore: spotStore,
                    contactStore: contactStore,
                    momentsViewModel: momentsViewModel,
                    locationManager: locationManager,
                    onSettingsTap: { showingSettings = true },
                    onAddMoment: {
                        viewModel.sheetCoordinator.presentSheet(.momentSourcePicker)
                    }
                )
                .tabItem {
                    Label(Strings.Tabs.explore, systemImage: "map.fill")
                }
                .tag(2)

                // Tab 3: Schedule (appointments, contacts, calendar)
                CalendarTabView(
                    milestoneStore: milestoneStore,
                    appointmentStore: appointmentStore,
                    socializationStore: socializationStore,
                    contactStore: contactStore,
                    onSettingsTap: { showingSettings = true },
                    onNavigateToSocialization: { selectedTab = 1 }
                )
                .tabItem {
                    Label(Strings.Tabs.schedule, systemImage: "calendar.badge.clock")
                }
                .tag(3)

                // Tab 4: Health (stats, weight, patterns, walks)
                HealthTabView(
                    viewModel: viewModel,
                    momentsViewModel: momentsViewModel,
                    onSettingsTap: { showingSettings = true }
                )
                .tabItem {
                    Label(Strings.Tabs.health, systemImage: "heart.text.square.fill")
                }
                .tag(4)
            }

            // Floating Action Button (hidden on Places and Schedule tabs)
            if selectedTab != 2 && selectedTab != 3 {
                HStack {
                    Spacer()

                    FABButton(
                        sleepState: viewModel.currentSleepState,
                        currentActivity: viewModel.currentActivity,
                        onTap: {
                            // Open full log sheet
                            viewModel.showAllEvents()
                        },
                        onQuickAction: { eventType, location in
                            // Quick log with default values
                            if let location = location {
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
                    .padding(.bottom, 60) // Above tab bar
                }
            }

            // Floating Clicker Button (enabled via settings)
            if showFloatingClicker {
                VStack {
                    Spacer()
                    HStack {
                        FloatingClickerButton()
                            .padding(.leading, 16)
                            .padding(.bottom, 100) // Above tab bar
                        Spacer()
                    }
                }
            }
        }  // Close ZStack
        }  // Close VStack
        // Settings sheet (accessed via gear icon in Today view)
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(
                    profileStore: profileStore,
                    dataImporter: dataImporter,
                    eventStore: eventStore,
                    notificationService: notificationService,
                    documentStore: documentStore,
                    contactStore: contactStore,
                    foodRecallService: foodRecallService
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
        // All sheets from shared modifier - at MainTabView level for global access
        .timelineSheetHandling(
            viewModel: viewModel,
            mediaCaptureViewModel: mediaCaptureViewModel,
            selectedPhotoEvent: $selectedPhotoEvent,
            reduceMotion: reduceMotion,
            spotStore: spotStore,
            locationManager: locationManager
        )
        // Arrival photo prompt - shown when expected puppy arrives without a photo
        .sheet(isPresented: $showingArrivalPhotoPrompt) {
            if let profile = profileStore.profile {
                ArrivalPhotoPromptSheet(
                    puppyName: profile.name,
                    onTakePhoto: {
                        showingArrivalPhotoPrompt = false
                        hasShownArrivalPhotoPrompt = true
                        // Navigate to settings to add a photo
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
        .onAppear {
            checkForArrivalPhotoPrompt()
        }
    }

    /// Check if we should show the arrival photo prompt
    /// Conditions: no profile photo, home date has passed, hasn't been shown before
    private func checkForArrivalPhotoPrompt() {
        // Skip in UI testing mode (for screenshots)
        guard !SeedData.isUITesting else { return }

        guard !hasShownArrivalPhotoPrompt,
              let profile = profileStore.profile,
              profile.profilePhotoFilename == nil else {
            return
        }

        // Check if home date has arrived (today or earlier)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let homeDate = calendar.startOfDay(for: profile.homeDate)

        if homeDate <= today {
            // Slight delay to let the UI settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showingArrivalPhotoPrompt = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProfileStore())
        .environmentObject(EventStore())
        .environmentObject(DataImporter())
        .environmentObject(WeatherService())
        .environmentObject(NotificationService())
        .environmentObject(SpotStore())
        .environmentObject(LocationManager())
        .environmentObject(MedicationStore())
        .environmentObject(SocializationStore())
        .environmentObject(MilestoneStore())
        .environmentObject(DocumentStore())
        .environmentObject(ContactStore())
        .environmentObject(AppointmentStore())
        .environmentObject(CloudKitService.shared)
}
