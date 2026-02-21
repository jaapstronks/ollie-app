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
struct MainTabView: View {
    @Binding var selectedTab: Int
    let eventStore: EventStore
    let profileStore: ProfileStore
    let dataImporter: DataImporter
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var notificationService: NotificationService

    @StateObject private var viewModel: TimelineViewModel
    @StateObject private var momentsViewModel: MomentsViewModel

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
        TabView(selection: $selectedTab) {
            // Timeline tab
            TimelineView(viewModel: viewModel, weatherService: weatherService)
                .tabItem {
                    Label(Strings.Tabs.journal, systemImage: "list.bullet")
                }
                .tag(0)

            // Stats tab
            StatsView(viewModel: viewModel)
                .tabItem {
                    Label(Strings.Tabs.stats, systemImage: "chart.bar")
                }
                .tag(1)

            // Moments tab
            MomentsGalleryView(viewModel: momentsViewModel)
                .tabItem {
                    Label(Strings.Tabs.moments, systemImage: "photo.on.rectangle")
                }
                .tag(2)

            // Settings tab
            SettingsView(
                profileStore: profileStore,
                dataImporter: dataImporter,
                eventStore: eventStore,
                notificationService: notificationService
            )
            .tabItem {
                Label(Strings.Tabs.settings, systemImage: "gear")
            }
            .tag(3)
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
