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
    @ObservedObject var userIdentityStore = UserIdentityStore.shared
    var onTriggerTour: (() -> Void)? = nil

    @State private var showingOtisPlusSheet = false
    @State private var showingSubscriptionSuccess = false
    @State private var showingImportSheet = false
    @State private var showingExportSheet = false
    @Environment(\.dismiss) private var dismiss

    // Guided tour
    @AppStorage(UserPreferences.Key.hasCompletedGuidedTour.rawValue) private var hasCompletedGuidedTour = false
    @AppStorage(UserPreferences.Key.guidedTourStep.rawValue) private var guidedTourStep = 0
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

            // User profile
            userProfileSection

            // iCloud Sync
            SyncSection(eventStore: eventStore, cloudKit: cloudKit)

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

            // Help section
            helpSection

            // Advanced section
            Section(Strings.Settings.advanced) {
                // Data import
                Button {
                    showingImportSheet = true
                } label: {
                    Label(Strings.Settings.importData, systemImage: "square.and.arrow.down")
                }

                if let result = dataImporter.lastResult {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.DataImport.lastImportResult)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(Strings.DataImport.importSummary(
                            components: result.componentsImported,
                            items: result.itemsImported
                        ))
                            .font(.caption)
                    }
                }

                // Data export
                Button {
                    showingExportSheet = true
                } label: {
                    Label(Strings.Export.exportData, systemImage: "square.and.arrow.up")
                }

                // Reset profile
                Button(role: .destructive) {
                    HapticFeedback.warning()
                    profileStore.resetProfile()
                } label: {
                    Label(Strings.Settings.resetProfile, systemImage: "trash")
                }
            }

            // Beta feedback section (visible in debug and TestFlight)
            if AppEnvironment.current.isBeta {
                BetaFeedbackSection()
                    .environmentObject(profileStore)
            }
        }
        .navigationTitle(Strings.Settings.appSettings)
        .toolbar {
            if AppEnvironment.current.isBeta {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text(Strings.Settings.appSettings)
                            .font(.headline)
                        Text(Strings.Beta.betaIndicator)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.otisAccent.opacity(0.2))
                            .foregroundStyle(Color.otisAccent)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportSheet(
                dataImporter: dataImporter,
                onDismiss: { showingImportSheet = false },
                onComplete: {
                    showingImportSheet = false
                    eventStore.loadEvents(for: Date())
                }
            )
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView(profileStore: profileStore)
        }
    }

    // MARK: - User Profile Section

    private var userProfileSection: some View {
        Section {
            NavigationLink {
                UserProfileSettingsView(userIdentityStore: userIdentityStore)
            } label: {
                HStack(spacing: 12) {
                    // Avatar
                    if let identity = userIdentityStore.currentIdentity {
                        if let avatarData = identity.avatarData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: identity.colorHex))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Text(identity.initial)
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                        }
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.secondary)
                            }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(userIdentityStore.currentIdentity?.name ?? Strings.UserProfile.me)
                            .font(.body)
                        Text(Strings.UserProfile.settingsDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text(Strings.UserProfile.title)
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
                    Text(Strings.Atmosphere.activityState)
                    Text(Strings.Atmosphere.activityStateDescription)
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

    // MARK: - Help Section

    private var helpSection: some View {
        Section(Strings.Settings.help) {
            Button {
                // Reset tour state and trigger replay
                hasCompletedGuidedTour = false
                guidedTourStep = 0
                dismiss()
                // Allow settings sheet to dismiss before starting tour
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onTriggerTour?()
                }
            } label: {
                Label(Strings.Settings.viewAppTour, systemImage: "questionmark.circle")
            }
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
