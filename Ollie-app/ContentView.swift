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
                        dataImporter: dataImporter
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

    @StateObject private var viewModel: TimelineViewModel

    init(
        selectedTab: Binding<Int>,
        eventStore: EventStore,
        profileStore: ProfileStore,
        dataImporter: DataImporter
    ) {
        self._selectedTab = selectedTab
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.dataImporter = dataImporter
        // StateObject init with autoclosure ensures single creation
        self._viewModel = StateObject(wrappedValue: TimelineViewModel(
            eventStore: eventStore,
            profileStore: profileStore
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Timeline tab
            TimelineView(viewModel: viewModel)
                .tabItem {
                    Label("Dagboek", systemImage: "list.bullet")
                }
                .tag(0)

            // Stats tab
            StatsView(viewModel: viewModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(1)

            // Settings tab
            SettingsView(
                profileStore: profileStore,
                dataImporter: dataImporter,
                eventStore: eventStore
            )
            .tabItem {
                Label("Instellingen", systemImage: "gear")
            }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProfileStore())
        .environmentObject(EventStore())
        .environmentObject(DataImporter())
}
