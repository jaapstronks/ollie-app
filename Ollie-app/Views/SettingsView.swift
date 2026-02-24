//
//  SettingsView.swift
//  Ollie-app
//
//  Refactored to use extracted section components from Views/Settings/

import CloudKit
import StoreKit
import SwiftUI
import OllieShared
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
    @State private var showingOlliePlusSheet = false
    @State private var showingSubscriptionSuccess = false
    @State private var showingMealEdit = false
    @State private var showingExerciseEdit = false
    @State private var activeShare: CKShare?
    @State private var isPreparingShare = false
    @State private var shareError: String?
    @State private var showStopSharingConfirm = false
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

                    // Siri & Shortcuts help
                    SiriSection()

                    // Ollie+ subscription (extracted to PremiumSection.swift)
                    PremiumSection(
                        profile: profile,
                        showingOlliePlusSheet: $showingOlliePlusSheet,
                        showingSubscriptionSuccess: $showingSubscriptionSuccess
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
        .sheet(isPresented: Binding(
            get: { activeShare != nil },
            set: { if !$0 { activeShare = nil } }
        )) {
            if let share = activeShare {
                CloudSharingView(
                    share: share,
                    container: CKContainer(identifier: "iCloud.nl.jaapstronks.Ollie"),
                    onDismiss: {
                        activeShare = nil
                        Task { await cloudKit.updateShareState() }
                    }
                )
            }
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
                    Task { await manageExistingShare() }
                } label: {
                    HStack {
                        Label(Strings.CloudSharing.manageSharing, systemImage: "person.2.fill")
                        if isPreparingShare {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isPreparingShare)

                // Add another person button
                Button {
                    Task { await prepareAndShowShare() }
                } label: {
                    HStack {
                        Label(Strings.CloudSharing.inviteAnother, systemImage: "person.badge.plus")
                        if isPreparingShare {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isPreparingShare)

                Button(role: .destructive) {
                    HapticFeedback.warning()
                    showStopSharingConfirm = true
                } label: {
                    Label(Strings.CloudSharing.stopSharing, systemImage: "xmark.circle")
                }
            } else {
                // Not shared yet - show invite button
                Button {
                    Task { await prepareAndShowShare() }
                } label: {
                    HStack {
                        Label(Strings.CloudSharing.shareWithPartner, systemImage: "person.badge.plus")
                        if isPreparingShare {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isPreparingShare)
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
        .task {
            // Refresh share state when entering settings
            await cloudKit.updateShareState()
        }
    }

    // MARK: - Sharing Actions

    /// Create or fetch share FIRST, then show sheet
    private func prepareAndShowShare() async {
        guard !isPreparingShare else { return }
        isPreparingShare = true
        shareError = nil

        do {
            // Create or fetch existing share BEFORE showing sheet
            let share = try await cloudKit.createShare()
            activeShare = share
        } catch {
            shareError = error.localizedDescription
        }

        isPreparingShare = false
    }

    private func manageExistingShare() async {
        guard !isPreparingShare else { return }
        isPreparingShare = true
        shareError = nil

        do {
            if let share = try await cloudKit.fetchExistingShare() {
                activeShare = share
            } else {
                shareError = Strings.CloudSharing.couldNotLoadShare
            }
        } catch {
            shareError = Strings.CloudSharing.couldNotLoadShare
        }

        isPreparingShare = false
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
