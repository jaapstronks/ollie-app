//
//  AppSettingsView.swift
//  Otis-app
//
//  App settings: subscription, sharing, sync, appearance

import CloudKit
import CoreData
import StoreKit
import SwiftUI
import OtisShared

/// Settings screen for all app-related configuration
struct AppSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore
    @ObservedObject var cloudKit = CloudKitService.shared

    @State private var showingOtisPlusSheet = false
    @State private var showingSubscriptionSuccess = false
    @State private var showingImportConfirm = false
    @State private var overwriteExisting = false
    @State private var importError: String?
    @State private var showingError = false
    @State private var showingExportSheet = false
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage(UserPreferences.Key.temperatureUnit.rawValue) private var temperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnit = WeightUnit.kg.rawValue
    @AppStorage(UserPreferences.Key.preferredMapsApp.rawValue) private var preferredMapsApp = PreferredMapsApp.appleMaps.rawValue

    // Atmosphere settings
    @AppStorage(UserPreferences.Key.atmosphereTimeOfDay.rawValue) private var atmosphereTimeOfDay = true
    @AppStorage(UserPreferences.Key.atmosphereWeather.rawValue) private var atmosphereWeather = true
    @AppStorage(UserPreferences.Key.atmosphereState.rawValue) private var atmosphereState = true
    @AppStorage(UserPreferences.Key.atmosphereSeasonal.rawValue) private var atmosphereSeasonal = false

    // Training settings
    @AppStorage(UserPreferences.Key.showFloatingClicker.rawValue) private var showFloatingClicker = false

    var body: some View {
        Form {
            if let profile = profileStore.profile {
                // Otis+ subscription
                PremiumSection(
                    profile: profile,
                    showingOtisPlusSheet: $showingOtisPlusSheet,
                    showingSubscriptionSuccess: $showingSubscriptionSuccess
                )
            }

            // iCloud Sync
            SyncSection(eventStore: eventStore, cloudKit: cloudKit)

            // CloudKit sharing
            SharingSection(cloudKit: cloudKit)

            // Household members
            Section {
                NavigationLink {
                    HouseholdSettingsView(profileStore: profileStore)
                } label: {
                    HStack {
                        Label(Strings.Household.title, systemImage: "person.2.fill")
                        Spacer()
                        if let memberCount = profileStore.profile?.householdMembers.members.count, memberCount > 0 {
                            Text("\(memberCount)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text(Strings.Household.settingsFooter)
            }

            // Siri & Shortcuts
            SiriSection()

            // Integrations (Webhooks)
            integrationsSection

            // Appearance
            appearanceSection

            // Units
            unitsSection

            // Maps
            mapsSection

            // Atmosphere
            atmosphereSection

            // Training
            trainingSection

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

                // Data export
                Button {
                    showingExportSheet = true
                } label: {
                    Label(Strings.Export.exportData, systemImage: "arrow.up.circle")
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
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView(profileStore: profileStore)
        }
    }

    // MARK: - Integrations Section

    private var integrationsSection: some View {
        Section {
            NavigationLink {
                WebhookSettingsView(profileStore: profileStore)
            } label: {
                HStack {
                    Label(Strings.Webhook.title, systemImage: "arrow.up.forward.app")
                    Spacer()
                    if profileStore.profile?.webhookConfig.isEnabled == true {
                        Text(Strings.Common.on)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text(Strings.Settings.integrations)
        } footer: {
            Text(Strings.Webhook.description)
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

    // MARK: - Maps Section

    private var mapsSection: some View {
        Section {
            Picker(Strings.Settings.mapsApp, selection: $preferredMapsApp) {
                ForEach(PreferredMapsApp.allCases) { app in
                    Label(app.label, systemImage: app.icon)
                        .tag(app.rawValue)
                }
            }
        } footer: {
            Text(Strings.Settings.mapsAppDescription)
        }
    }

    // MARK: - Training Section

    private var trainingSection: some View {
        Section {
            Toggle(isOn: $showFloatingClicker) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.TrainingSettings.floatingClicker)
                    Text(Strings.TrainingSettings.floatingClickerDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(Strings.TrainingSettings.title)
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
