//
//  ContentView.swift
//  Ollie-app
//

import SwiftUI

/// Root view with tab navigation or onboarding
struct ContentView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var dataImporter: DataImporter
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var notificationService: NotificationService

    @State private var showOnboarding = false
    @AppStorage(UserPreferences.Key.lastSelectedTab.rawValue) private var selectedTab = 0
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue
    @State private var showLaunchScreen = true

    private var colorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    var body: some View {
        ZStack {
            Group {
                if profileStore.isLoading {
                    // Loading state
                    LaunchScreen()
                } else if !profileStore.hasProfile || showOnboarding {
                    // Onboarding for new users
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
                        notificationService: notificationService
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
        .preferredColorScheme(colorScheme)
    }
}

/// Wrapper view that owns the TimelineViewModel as a @StateObject
/// New structure: 2 tabs (Today, Insights) + FAB for logging
struct MainTabView: View {
    @Binding var selectedTab: Int
    let eventStore: EventStore
    let profileStore: ProfileStore
    let dataImporter: DataImporter
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var notificationService: NotificationService

    @StateObject private var viewModel: TimelineViewModel
    @StateObject private var momentsViewModel: MomentsViewModel
    @State private var showingSettings = false

    init(
        selectedTab: Binding<Int>,
        eventStore: EventStore,
        profileStore: ProfileStore,
        dataImporter: DataImporter,
        weatherService: WeatherService,
        notificationService: NotificationService
    ) {
        self._selectedTab = selectedTab
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.dataImporter = dataImporter
        self.weatherService = weatherService
        self.notificationService = notificationService
        // StateObject init with autoclosure ensures single creation
        self._viewModel = StateObject(wrappedValue: TimelineViewModel(
            eventStore: eventStore,
            profileStore: profileStore,
            notificationService: notificationService
        ))
        self._momentsViewModel = StateObject(wrappedValue: MomentsViewModel(
            eventStore: eventStore
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main tab content
            TabView(selection: $selectedTab) {
                // Tab 1: Today (Vandaag)
                TodayView(
                    viewModel: viewModel,
                    weatherService: weatherService,
                    onSettingsTap: { showingSettings = true }
                )
                .tabItem {
                    Label(Strings.Tabs.today, systemImage: "calendar")
                }
                .tag(0)

                // Tab 2: Insights (Inzichten)
                InsightsView(
                    viewModel: viewModel,
                    momentsViewModel: momentsViewModel
                )
                .tabItem {
                    Label(Strings.Tabs.insights, systemImage: "chart.bar")
                }
                .tag(1)
            }

            // Floating Action Button
            HStack {
                Spacer()

                FABButton(
                    sleepState: viewModel.currentSleepState,
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
                    }
                )
                .padding(.trailing, 16)
                .padding(.bottom, 60) // Above tab bar
            }
        }
        // Settings sheet (accessed via gear icon in Today view)
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(
                    profileStore: profileStore,
                    dataImporter: dataImporter,
                    eventStore: eventStore,
                    notificationService: notificationService
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
    }
}

#Preview {
    ContentView()
        .environmentObject(ProfileStore())
        .environmentObject(EventStore())
        .environmentObject(DataImporter())
        .environmentObject(WeatherService())
        .environmentObject(NotificationService())
}
