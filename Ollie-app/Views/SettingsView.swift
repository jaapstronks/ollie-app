//
//  SettingsView.swift
//  Ollie-app
//
//  Refactored to use extracted section components from Views/Settings/

import StoreKit
import SwiftUI
import TipKit

/// Settings screen with profile editing and data import
struct SettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var cloudKit = CloudKitService.shared

    @State private var showingImportConfirm = false
    @State private var importError: String?
    @State private var showingError = false
    @State private var overwriteExisting = false
    @State private var showingNotificationSettings = false
    @State private var showingUpgradePrompt = false
    @State private var showingPurchaseSuccess = false
    @ObservedObject var storeKit = StoreKitManager.shared
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profileStore.profile {
                    // Profile & Stats (extracted to ProfileSection.swift)
                    ProfileSection(profile: profile)
                    StatsSection(profile: profile)

                    // Exercise (extracted to ExerciseSection.swift)
                    ExerciseSection(profile: profile, profileStore: profileStore)

                    // Meals (extracted to MealSection.swift)
                    MealSection(profile: profile, profileStore: profileStore)

                    // Walk spots & Health (kept inline - simple)
                    walkSpotsSection
                    healthSection

                    // Notifications (kept inline - has local state)
                    notificationSection(profile)

                    // Premium (extracted to PremiumSection.swift)
                    PremiumSection(
                        profile: profile,
                        storeKit: storeKit,
                        showingUpgradePrompt: $showingUpgradePrompt,
                        showingPurchaseSuccess: $showingPurchaseSuccess,
                        onPurchase: { await handlePurchase(for: profile) }
                    )
                }

                // CloudKit sharing section
                ShareSettingsSection(cloudKit: cloudKit)

                appearanceSection

                // Sync (extracted to SyncSection.swift)
                SyncSection(eventStore: eventStore, cloudKit: cloudKit)

                // Data import (extracted to DataSection.swift)
                DataSection(
                    dataImporter: dataImporter,
                    eventStore: eventStore,
                    showingImportConfirm: $showingImportConfirm,
                    overwriteExisting: $overwriteExisting
                )

                // Danger zone (extracted to DataSection.swift)
                DangerSection(profileStore: profileStore)
            }
            .navigationTitle(Strings.Settings.title)
        }
        .alert(Strings.Settings.importAction, isPresented: $showingImportConfirm) {
            Button(Strings.Settings.importAction) {
                startImport()
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Settings.importConfirmMessage)
        }
        .alert(Strings.Common.error, isPresented: $showingError) {
            Button(Strings.Common.ok) {}
        } message: {
            Text(importError ?? Strings.PottyStatus.unknown)
        }
    }

    // MARK: - Inline Sections (kept for simplicity or local state needs)

    @ViewBuilder
    private var walkSpotsSection: some View {
        Section(Strings.WalkLocations.walkLocation) {
            NavigationLink {
                FavoriteSpotsView(spotStore: spotStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.WalkLocations.favoriteSpots)
                    } icon: {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    Text("\(spotStore.spots.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var healthSection: some View {
        Section(Strings.Health.title) {
            NavigationLink {
                HealthView(viewModel: viewModel)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Health.milestones)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.ollieDanger)
                    }
                    Spacer()
                    Text(Strings.Insights.healthDescription)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    private let mealRemindersTip = MealRemindersTip()

    @ViewBuilder
    private func notificationSection(_ profile: PuppyProfile) -> some View {
        Section(Strings.Settings.reminders) {
            TipView(mealRemindersTip)

            Button {
                showingNotificationSettings = true
            } label: {
                HStack {
                    Label {
                        Text(Strings.Settings.notifications)
                    } icon: {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    Text(profile.notificationSettings.isEnabled ? Strings.Common.on : Strings.Common.off)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(
                profileStore: profileStore,
                notificationService: notificationService
            )
        }
    }

    private var appearanceSection: some View {
        Section(Strings.Settings.appearance) {
            Picker(Strings.Settings.theme, selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.icon)
                        .tag(mode.rawValue)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    // MARK: - Actions

    private func handlePurchase(for profile: PuppyProfile) async {
        do {
            try await storeKit.purchase(for: profile.id)
            profileStore.unlockPremium()
            showingUpgradePrompt = false
            showingPurchaseSuccess = true
            HapticFeedback.success()
        } catch StoreKitError.userCancelled {
            // User cancelled, do nothing
        } catch {
            HapticFeedback.error()
        }
    }

    private func startImport() {
        Task {
            do {
                _ = try await dataImporter.importFromGitHub(overwriteExisting: overwriteExisting)
                eventStore.loadEvents(for: Date())
            } catch {
                importError = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return SettingsView(
        profileStore: profileStore,
        dataImporter: DataImporter(),
        eventStore: eventStore,
        notificationService: NotificationService(),
        spotStore: SpotStore(),
        viewModel: viewModel
    )
}
