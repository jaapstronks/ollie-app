//
//  SettingsView.swift
//  Otis-app
//
//  Settings hub with app settings at top, dog cards below, and add dog button

import SwiftUI
import OtisShared

/// Settings hub screen with app settings and dog-specific settings cards
struct SettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var medicationStore: MedicationStore
    @ObservedObject var documentStore: DocumentStore
    @ObservedObject var contactStore: ContactStore
    @ObservedObject var foodRecallService: FoodRecallService

    var onAddDog: (() -> Void)?
    var onTriggerTour: (() -> Void)?

    /// Profiles sorted with active profile first
    private var sortedProfiles: [PuppyProfile] {
        profileStore.profiles.sorted { p1, p2 in
            // Active profile comes first
            if p1.id == profileStore.activeProfileId { return true }
            if p2.id == profileStore.activeProfileId { return false }
            // Otherwise maintain original order
            return false
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App Settings at the top
                appSettingsSection

                #if DEBUG
                // Developer Tools - only in debug builds
                devToolsSection
                #endif

                // Dog cards - one per profile, active dog first
                ForEach(sortedProfiles, id: \.id) { profile in
                    DogSettingsCard(
                        profile: profile,
                        isActive: profile.id == profileStore.activeProfileId,
                        onActivate: {
                            profileStore.switchToProfile(profile.id)
                        },
                        profileStore: profileStore,
                        medicationStore: medicationStore,
                        notificationService: notificationService,
                        documentStore: documentStore,
                        foodRecallService: foodRecallService,
                        cloudKit: CloudKitService.shared
                    )
                }

                // Add dog button
                AddDogButton(
                    canAdd: profileStore.canAddOwnedProfile(),
                    action: {
                        if profileStore.canAddOwnedProfile() {
                            onAddDog?()
                        }
                    }
                )
            }
            .padding()
            .adaptiveContainer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Strings.Settings.title)
    }

    // MARK: - App Settings Section

    private var appSettingsSection: some View {
        NavigationLink {
            AppSettingsView(
                profileStore: profileStore,
                dataImporter: dataImporter,
                eventStore: eventStore,
                onTriggerTour: onTriggerTour
            )
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 50, height: 50)

                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Settings.appSettings)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(Strings.Settings.appSettingsSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    #if DEBUG
    // MARK: - Developer Tools Section

    private var devToolsSection: some View {
        NavigationLink {
            DevToolsView()
                .environmentObject(profileStore)
                .environmentObject(eventStore)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: "hammer.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Developer Tools")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Debug, AI testing, data management")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    #endif
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
            medicationStore: MedicationStore(),
            documentStore: DocumentStore(),
            contactStore: ContactStore(),
            foodRecallService: FoodRecallService(),
            onAddDog: { print("Add dog") }
        )
    }
}
