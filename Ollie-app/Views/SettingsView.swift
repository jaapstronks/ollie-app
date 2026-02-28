//
//  SettingsView.swift
//  Ollie-app
//
//  Settings hub with navigation to 4 sections

import SwiftUI
import OllieShared

/// Settings hub screen with four main navigation options
struct SettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var documentStore: DocumentStore
    @ObservedObject var contactStore: ContactStore

    var body: some View {
        List {
            // 1. Dog Profile Section
            Section {
                NavigationLink {
                    DogProfileSettingsView(profileStore: profileStore)
                } label: {
                    SettingsHubRow(
                        icon: "pawprint.fill",
                        iconColor: .ollieAccent,
                        title: profileStore.profile?.name ?? Strings.Settings.dogProfile,
                        subtitle: Strings.Settings.dogProfileSubtitle
                    )
                }
            }

            // 2. Schedule & Preferences Section
            Section {
                NavigationLink {
                    SchedulePreferencesView(
                        profileStore: profileStore,
                        notificationService: notificationService
                    )
                } label: {
                    SettingsHubRow(
                        icon: "calendar.badge.clock",
                        iconColor: .blue,
                        title: Strings.Settings.schedulePreferences,
                        subtitle: Strings.Settings.schedulePreferencesSubtitle
                    )
                }
            }

            // 3. Health & Documents Section
            Section {
                NavigationLink {
                    HealthDocumentsView(
                        profileStore: profileStore,
                        documentStore: documentStore
                    )
                } label: {
                    SettingsHubRow(
                        icon: "heart.text.square.fill",
                        iconColor: .red,
                        title: Strings.Settings.healthDocuments,
                        subtitle: Strings.Settings.healthDocumentsSubtitle
                    )
                }
            }

            // 4. App Settings Section
            Section {
                NavigationLink {
                    AppSettingsView(
                        profileStore: profileStore,
                        dataImporter: dataImporter,
                        eventStore: eventStore
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
    NavigationStack {
        SettingsView(
            profileStore: ProfileStore(),
            dataImporter: DataImporter(),
            eventStore: EventStore(),
            notificationService: NotificationService(),
            documentStore: DocumentStore(),
            contactStore: ContactStore()
        )
    }
}
