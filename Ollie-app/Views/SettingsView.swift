//
//  SettingsView.swift
//  Ollie-app
//
//  Refactored to use extracted section components from Views/Settings/

import CloudKit
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
    @State private var showingMealEdit = false
    @State private var showingExerciseEdit = false
    @State private var shareToPresent: IdentifiableShare?
    @State private var shareError: String?
    @State private var showStopSharingConfirm = false
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
                    ExerciseSection(profile: profile, profileStore: profileStore, showingExerciseEdit: $showingExerciseEdit)

                    // Meals (extracted to MealSection.swift)
                    MealSection(profile: profile, profileStore: profileStore, showingMealEdit: $showingMealEdit)

                    // Medications
                    medicationsSection

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
                sharingSectionContent

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
        .sheet(isPresented: $showingMealEdit) {
            MealEditView(profileStore: profileStore)
        }
        .sheet(isPresented: $showingExerciseEdit) {
            ExerciseEditView(profileStore: profileStore)
        }
        .sheet(item: $shareToPresent) { identifiableShare in
            CloudSharingView(
                share: identifiableShare.share,
                container: CKContainer(identifier: "iCloud.nl.jaapstronks.Ollie")
            )
        }
        .alert(Strings.CloudSharing.stopSharing, isPresented: $showStopSharingConfirm) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.CloudSharing.stopSharing, role: .destructive) {
                Task { await stopSharing() }
            }
        } message: {
            Text(Strings.CloudSharing.stopSharingConfirm)
        }
    }

    // MARK: - Inline Sections (kept for simplicity or local state needs)

    @ViewBuilder
    private var medicationsSection: some View {
        Section(Strings.Medications.title) {
            NavigationLink {
                MedicationSettingsView(profileStore: profileStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Medications.title)
                    } icon: {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    let count = profileStore.profile?.medicationSchedule.medications.count ?? 0
                    if count > 0 {
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

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

    // MARK: - Sharing Section

    @ViewBuilder
    private var sharingSectionContent: some View {
        Section {
            if !cloudKit.isCloudAvailable {
                // iCloud not available
                HStack {
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.CloudSharing.iCloudUnavailable)
                            .font(.subheadline)
                        if let error = cloudKit.syncError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if cloudKit.isParticipant {
                // User is viewing shared data (not the owner)
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.CloudSharing.sharedData)
                            .font(.subheadline)
                        Text(Strings.CloudSharing.viewingOthersData)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if cloudKit.isShared {
                // Already shared - show participants
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(Strings.CloudSharing.shared)
                            .font(.subheadline.weight(.medium))
                    }

                    if cloudKit.shareParticipants.isEmpty {
                        Text(Strings.CloudSharing.noParticipants)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(cloudKit.shareParticipants) { participant in
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(participant.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(participant.status.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button {
                    Task { await showExistingShare() }
                } label: {
                    Label(Strings.CloudSharing.manageSharing, systemImage: "person.badge.plus")
                }

                Button(role: .destructive) {
                    HapticFeedback.warning()
                    showStopSharingConfirm = true
                } label: {
                    Label(Strings.CloudSharing.stopSharing, systemImage: "xmark.circle")
                }
            } else {
                // Not shared yet - show invite button
                Button {
                    Task { await createAndShowShare() }
                } label: {
                    Label(Strings.CloudSharing.shareWithPartner, systemImage: "person.badge.plus")
                }
            }

            if let error = shareError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text(Strings.CloudSharing.sharing)
        } footer: {
            if cloudKit.isCloudAvailable && !cloudKit.isParticipant {
                Text(Strings.CloudSharing.sharingDescription)
            }
        }
    }

    // MARK: - Sharing Actions

    private func createAndShowShare() async {
        shareError = nil
        do {
            let share = try await cloudKit.createShare()
            shareToPresent = IdentifiableShare(share: share)
        } catch {
            shareError = "Could not create share: \(error.localizedDescription)"
        }
    }

    private func showExistingShare() async {
        shareError = nil
        do {
            if let share = try await cloudKit.fetchExistingShare() {
                shareToPresent = IdentifiableShare(share: share)
            } else {
                shareError = Strings.CloudSharing.couldNotLoadShare
            }
        } catch {
            shareError = Strings.CloudSharing.couldNotLoadShare
        }
    }

    private func stopSharing() async {
        shareError = nil
        do {
            try await cloudKit.stopSharing()
        } catch {
            shareError = "Could not stop sharing: \(error.localizedDescription)"
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

// MARK: - Helper Types

/// Wrapper to make CKShare work with .sheet(item:)
struct IdentifiableShare: Identifiable {
    let id = UUID()
    let share: CKShare
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
