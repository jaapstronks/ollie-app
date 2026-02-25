//
//  SettingsView.swift
//  Ollie-app
//
//  Settings hub with navigation to Dog Profile and App Settings

import SwiftUI
import OllieShared

/// Settings hub screen with two main navigation options
struct SettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var viewModel: TimelineViewModel

    var body: some View {
        List {
            // Dog Profile Section
            Section {
                NavigationLink {
                    DogProfileSettingsView(
                        profileStore: profileStore,
                        spotStore: spotStore,
                        viewModel: viewModel
                    )
                } label: {
                    SettingsHubRow(
                        icon: "pawprint.fill",
                        iconColor: .ollieAccent,
                        title: profileStore.profile?.name ?? Strings.Settings.dogProfile,
                        subtitle: Strings.Settings.dogProfileSubtitle
                    )
                }
            }

            // App Settings Section
            Section {
                NavigationLink {
                    AppSettingsView(
                        profileStore: profileStore,
                        dataImporter: dataImporter,
                        eventStore: eventStore,
                        notificationService: notificationService
                    )
                } label: {
                    SettingsHubRow(
                        icon: "gearshape.fill",
                        iconColor: .secondary,
                        title: Strings.Settings.appSettings,
                        subtitle: Strings.Settings.appSettingsSubtitle
                    )
                }
            }
        }
        .navigationTitle(Strings.Settings.title)
    }
}

/// Reusable row component for the settings hub
private struct SettingsHubRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return NavigationStack {
        SettingsView(
            profileStore: profileStore,
            dataImporter: DataImporter(),
            eventStore: eventStore,
            notificationService: NotificationService(),
            spotStore: SpotStore(),
            viewModel: viewModel
        )
    }
}
