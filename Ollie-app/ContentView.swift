//
//  ContentView.swift
//  Ollie-app
//

import SwiftUI
import OllieShared

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

    @State private var showOnboarding = false
    @AppStorage(UserPreferences.Key.lastSelectedTab.rawValue) private var selectedTab = 0
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue
    @State private var showLaunchScreen = true

    private var colorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    /// Determine if we should show onboarding
    /// - Skip if user is a participant (accepted a share invitation)
    /// - Skip if user already has a profile
    private var shouldShowOnboarding: Bool {
        // Never show onboarding while loading
        guard !profileStore.isLoading else { return false }

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

    @StateObject private var viewModel: TimelineViewModel
    @StateObject private var momentsViewModel: MomentsViewModel
    @StateObject private var mediaCaptureViewModel = MediaCaptureViewModel(mediaStore: MediaStore())
    @StateObject private var thisWeekViewModel: ThisWeekViewModel
    @State private var showingSettings = false
    @State private var selectedPhotoEvent: PuppyEvent?
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
        self._thisWeekViewModel = StateObject(wrappedValue: ThisWeekViewModel(
            profileStore: profileStore,
            milestoneStore: milestoneStore,
            socializationStore: socializationStore
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
                    thisWeekViewModel: thisWeekViewModel,
                    appointmentStore: appointmentStore,
                    weatherService: weatherService,
                    onSettingsTap: { showingSettings = true },
                    onNavigateToInsights: { selectedTab = 4 },
                    onNavigateToAppointments: { selectedTab = 3 }
                )
                .tabItem {
                    Label(Strings.Tabs.today, systemImage: "calendar")
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

                // Tab 2: Places (spots + moments combined)
                PlacesTabView(
                    spotStore: spotStore,
                    contactStore: contactStore,
                    momentsViewModel: momentsViewModel,
                    viewModel: viewModel,
                    locationManager: locationManager,
                    onSettingsTap: { showingSettings = true }
                )
                .tabItem {
                    Label(Strings.Tabs.places, systemImage: "map.fill")
                }
                .tag(2)

                // Tab 3: Schedule (appointments, contacts, calendar)
                CalendarTabView(
                    milestoneStore: milestoneStore,
                    appointmentStore: appointmentStore,
                    socializationStore: socializationStore,
                    contactStore: contactStore,
                    onSettingsTap: { showingSettings = true }
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

            // Floating Action Button (hidden on Places tab)
            if selectedTab != 2 {
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
                    contactStore: contactStore
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
