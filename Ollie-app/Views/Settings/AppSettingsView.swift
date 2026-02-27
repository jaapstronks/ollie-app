//
//  AppSettingsView.swift
//  Ollie-app
//
//  App settings: subscription, sharing, sync, appearance

import CloudKit
import CoreData
import StoreKit
import SwiftUI
import OllieShared

/// Settings screen for all app-related configuration
struct AppSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore
    @ObservedObject var cloudKit = CloudKitService.shared

    @State private var showingOlliePlusSheet = false
    @State private var showingSubscriptionSuccess = false
    @State private var showingImportConfirm = false
    @State private var overwriteExisting = false
    @State private var importError: String?
    @State private var showingError = false
    @State private var activeShare: CKShare?
    @State private var isPreparingShare = false
    @State private var shareError: String?
    @State private var showStopSharingConfirm = false
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage(UserPreferences.Key.temperatureUnit.rawValue) private var temperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnit = WeightUnit.kg.rawValue

    // Atmosphere settings
    @AppStorage(UserPreferences.Key.atmosphereTimeOfDay.rawValue) private var atmosphereTimeOfDay = true
    @AppStorage(UserPreferences.Key.atmosphereWeather.rawValue) private var atmosphereWeather = true
    @AppStorage(UserPreferences.Key.atmosphereState.rawValue) private var atmosphereState = true
    @AppStorage(UserPreferences.Key.atmosphereSeasonal.rawValue) private var atmosphereSeasonal = false

    var body: some View {
        Form {
            if let profile = profileStore.profile {
                // Ollie+ subscription
                PremiumSection(
                    profile: profile,
                    showingOlliePlusSheet: $showingOlliePlusSheet,
                    showingSubscriptionSuccess: $showingSubscriptionSuccess
                )
            }

            // iCloud Sync
            SyncSection(eventStore: eventStore, cloudKit: cloudKit)

            // CloudKit sharing
            sharingSectionContent

            // Siri & Shortcuts
            SiriSection()

            // Appearance
            appearanceSection

            // Units
            unitsSection

            // Atmosphere
            atmosphereSection

            // Celebrations
            celebrationsSection

            // Advanced section
            Section(Strings.Settings.advanced) {
                // Data import
                if dataImporter.isImporting {
                    HStack {
                        ProgressView()
                        Text(dataImporter.progress)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        showingImportConfirm = true
                    } label: {
                        Label(Strings.Settings.importFromGitHub, systemImage: "arrow.down.circle")
                    }

                    if let result = dataImporter.lastResult {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.Settings.lastImport(date: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(Strings.Settings.importStats(days: result.filesImported, events: result.eventsImported))
                                .font(.caption)
                            if result.skipped > 0 {
                                Text(Strings.Settings.skippedExisting(result.skipped))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Toggle(Strings.Settings.overwriteExisting, isOn: $overwriteExisting)
                }

                // Reset profile
                Button(role: .destructive) {
                    HapticFeedback.warning()
                    profileStore.resetProfile()
                } label: {
                    Label(Strings.Settings.resetProfile, systemImage: "trash")
                }
            }

            #if DEBUG
            DebugSection()
            #endif
        }
        .navigationTitle(Strings.Settings.appSettings)
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

    // MARK: - Appearance Section

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

            Toggle(isOn: Binding(
                get: { SoundFeedback.isEnabled },
                set: { SoundFeedback.isEnabled = $0 }
            )) {
                Label(Strings.Settings.soundFeedback, systemImage: "speaker.wave.2")
            }
        }
    }

    // MARK: - Units Section

    private var unitsSection: some View {
        Section(Strings.Settings.units) {
            Picker(Strings.Settings.temperature, selection: $temperatureUnit) {
                ForEach(TemperatureUnit.allCases) { unit in
                    Text(unit.label)
                        .tag(unit.rawValue)
                }
            }

            Picker(Strings.Settings.weight, selection: $weightUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.label)
                        .tag(unit.rawValue)
                }
            }
        }
    }

    // MARK: - Atmosphere Section

    private var atmosphereSection: some View {
        Section {
            Toggle(isOn: $atmosphereTimeOfDay) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Atmosphere.timeOfDay)
                    Text(Strings.Atmosphere.timeOfDayDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: $atmosphereWeather) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Atmosphere.weather)
                    Text(Strings.Atmosphere.weatherDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: $atmosphereState) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Atmosphere.puppyState)
                    Text(Strings.Atmosphere.puppyStateDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: $atmosphereSeasonal) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Atmosphere.seasonal)
                    Text(Strings.Atmosphere.seasonalDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(Strings.Atmosphere.title)
        } footer: {
            Text(Strings.Atmosphere.description)
        }
    }

    // MARK: - Celebrations Section

    private var celebrationsSection: some View {
        Section {
            NavigationLink {
                CelebrationSettingsView()
            } label: {
                HStack {
                    Label(Strings.Celebrations.celebrationStyle, systemImage: "sparkles")
                    Spacer()
                    Text(currentCelebrationStyle.displayName)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(Strings.Celebrations.celebrationStyle)
        }
    }

    private var currentCelebrationStyle: CelebrationStyle {
        let rawValue = UserDefaults.standard.string(forKey: UserPreferences.Key.celebrationStyle.rawValue)
        return CelebrationStyle(rawValue: rawValue ?? "") ?? .full
    }

    // MARK: - Sharing Section

    @ViewBuilder
    private var sharingSectionContent: some View {
        Section {
            if !cloudKit.isCloudAvailable {
                HStack {
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundStyle(Color.ollieWarning)
                    Text(Strings.CloudSharing.iCloudUnavailable)
                        .font(.subheadline)
                }
            } else if cloudKit.isParticipant {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.ollieInfo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.CloudSharing.sharedData)
                            .font(.subheadline)
                        Text(Strings.CloudSharing.viewingOthersData)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if cloudKit.isShared {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.ollieSuccess)
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
            let context = PersistenceController.shared.viewContext
            if let cdProfile = CDPuppyProfile.fetchProfile(in: context) {
                await cloudKit.refreshShareState(
                    for: cdProfile,
                    using: PersistenceController.shared.container
                )
            }
        }
    }

    // MARK: - Sharing Actions

    private func prepareAndShowShare() async {
        guard !isPreparingShare else { return }
        isPreparingShare = true
        shareError = nil

        do {
            let context = PersistenceController.shared.viewContext
            guard let cdProfile = CDPuppyProfile.fetchProfile(in: context) else {
                shareError = "No profile found. Please set up your puppy first."
                isPreparingShare = false
                return
            }

            let share = try await cloudKit.getOrCreateShare(
                for: cdProfile,
                using: PersistenceController.shared.container
            )

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

        let context = PersistenceController.shared.viewContext
        if let cdProfile = CDPuppyProfile.fetchProfile(in: context) {
            await cloudKit.refreshShareState(
                for: cdProfile,
                using: PersistenceController.shared.container
            )
        }

        if let share = cloudKit.currentShare {
            activeShare = share
        } else {
            shareError = Strings.CloudSharing.couldNotLoadShare
        }

        isPreparingShare = false
    }

    private func stopSharing() async {
        shareError = nil

        do {
            try await cloudKit.stopSharing()
            await cloudKit.updateShareState()
        } catch {
            shareError = error.localizedDescription
        }
    }

    // MARK: - Import Actions

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
    NavigationStack {
        AppSettingsView(
            profileStore: ProfileStore(),
            dataImporter: DataImporter(),
            eventStore: EventStore()
        )
    }
}
