//
//  SettingsView.swift
//  Ollie-app
//

import StoreKit
import SwiftUI
import TipKit

/// Settings screen with profile editing and data import
struct SettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var cloudKit = CloudKitService.shared

    @State private var showingImportConfirm = false
    @State private var importError: String?
    @State private var showingError = false
    @State private var overwriteExisting = false
    @State private var showingMealEdit = false
    @State private var showingNotificationSettings = false
    @State private var showingExerciseEdit = false
    @State private var showingUpgradePrompt = false
    @State private var showingPurchaseSuccess = false
    @ObservedObject var storeKit = StoreKitManager.shared
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profileStore.profile {
                    profileSection(profile)
                    statsSection(profile)
                    exerciseSection(profile)
                    mealSection(profile)
                    notificationSection(profile)
                    premiumSection(profile)
                }

                // CloudKit sharing section
                ShareSettingsSection(cloudKit: cloudKit)

                appearanceSection
                syncSection
                dataSection
                dangerSection
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

    // MARK: - Sections

    @ViewBuilder
    private func profileSection(_ profile: PuppyProfile) -> some View {
        Section(Strings.Settings.profile) {
            HStack {
                Text(Strings.Settings.name)
                Spacer()
                Text(profile.name)
                    .foregroundColor(.secondary)
            }

            if let breed = profile.breed {
                HStack {
                    Text(Strings.Settings.breed)
                    Spacer()
                    Text(breed)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text(Strings.Settings.size)
                Spacer()
                Text(profile.sizeCategory.label)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func statsSection(_ profile: PuppyProfile) -> some View {
        Section(Strings.Settings.stats) {
            HStack {
                Text(Strings.Settings.age)
                Spacer()
                Text("\(profile.ageInWeeks) \(Strings.Common.weeks)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(Strings.Settings.daysHome)
                Spacer()
                Text("\(profile.daysHome) \(Strings.Common.days)")
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func exerciseSection(_ profile: PuppyProfile) -> some View {
        Section(Strings.Settings.exercise) {
            HStack {
                Text(Strings.Settings.maxExercise)
                Spacer()
                Text("\(profile.maxExerciseMinutes) \(Strings.Settings.minPerWalk)")
                    .foregroundColor(.secondary)
            }

            Button {
                showingExerciseEdit = true
            } label: {
                Label(Strings.Settings.editExerciseLimit, systemImage: "pencil")
            }
        }
        .sheet(isPresented: $showingExerciseEdit) {
            ExerciseEditView(profileStore: profileStore)
        }
    }

    @ViewBuilder
    private func mealSection(_ profile: PuppyProfile) -> some View {
        Section(Strings.Settings.mealsPerDay(profile.mealSchedule.mealsPerDay)) {
            ForEach(profile.mealSchedule.portions) { portion in
                HStack {
                    Text(portion.label)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(portion.amount)
                            .foregroundColor(.secondary)
                        if let time = portion.targetTime {
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Button {
                showingMealEdit = true
            } label: {
                Label(Strings.Settings.editMeals, systemImage: "pencil")
            }
        }
        .sheet(isPresented: $showingMealEdit) {
            MealEditView(profileStore: profileStore)
        }
    }

    private let mealRemindersTip = MealRemindersTip()

    @ViewBuilder
    private func notificationSection(_ profile: PuppyProfile) -> some View {
        Section(Strings.Settings.reminders) {
            // Tip for meal reminders
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

    @ViewBuilder
    private func premiumSection(_ profile: PuppyProfile) -> some View {
        Section(Strings.Premium.title) {
            // Status row
            HStack {
                Text(Strings.Premium.status)
                Spacer()
                Text(premiumStatusText(for: profile))
                    .foregroundColor(premiumStatusColor(for: profile))
            }

            // Purchase button (if not premium)
            if !profile.isPremiumUnlocked {
                Button {
                    showingUpgradePrompt = true
                } label: {
                    HStack {
                        if storeKit.isPurchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(purchaseButtonText)
                    }
                }
                .disabled(storeKit.isPurchasing)

                // Restore purchases
                Button {
                    Task {
                        await storeKit.restorePurchases()
                    }
                } label: {
                    Text(Strings.Premium.restorePurchases)
                }
                .disabled(storeKit.isPurchasing)
            }
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            UpgradePromptView(
                puppyName: profile.name,
                onPurchase: {
                    Task {
                        await handlePurchase(for: profile)
                    }
                },
                onRestore: {
                    Task {
                        await storeKit.restorePurchases()
                    }
                },
                onDismiss: {
                    showingUpgradePrompt = false
                }
            )
        }
        .sheet(isPresented: $showingPurchaseSuccess) {
            PurchaseSuccessView(
                puppyName: profile.name,
                onDismiss: {
                    showingPurchaseSuccess = false
                }
            )
        }
        .task {
            await storeKit.loadProducts()
        }
    }

    private func premiumStatusText(for profile: PuppyProfile) -> String {
        if profile.isPremiumUnlocked {
            return Strings.Premium.premium
        } else if profile.isFreePeriodExpired {
            return Strings.Premium.expired
        } else {
            return Strings.Premium.freeDaysLeft(profile.freeDaysRemaining)
        }
    }

    private func premiumStatusColor(for profile: PuppyProfile) -> Color {
        if profile.isPremiumUnlocked {
            return .ollieSuccess
        } else if profile.isFreePeriodExpired {
            return .ollieWarning
        } else {
            return .secondary
        }
    }

    private var purchaseButtonText: String {
        if let product = storeKit.premiumProduct {
            return Strings.Premium.continueWithOlliePrice(product.displayPrice)
        }
        return Strings.Premium.continueWithOlliePrice(Strings.Premium.price)
    }

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

    private var syncSection: some View {
        Section {
            // Sync status
            HStack {
                if eventStore.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(Strings.Settings.syncing)
                        .foregroundStyle(.secondary)
                } else if cloudKit.isCloudAvailable {
                    Image(systemName: "checkmark.icloud")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Settings.iCloudActive)
                        if let lastSync = cloudKit.lastSyncDate {
                            Text(Strings.Settings.lastSync(date: lastSync.formatted(.relative(presentation: .named))))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "xmark.icloud")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Settings.iCloudUnavailable)
                        if let error = cloudKit.syncError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }

            // Manual sync button
            if cloudKit.isCloudAvailable && !eventStore.isSyncing {
                Button {
                    Task {
                        await eventStore.forceSync()
                    }
                } label: {
                    Label(Strings.Settings.syncNow, systemImage: "arrow.triangle.2.circlepath")
                }
            }
        } header: {
            Text(Strings.Settings.sync)
        } footer: {
            Text(Strings.Settings.syncFooter)
        }
    }

    private var dataSection: some View {
        Section(Strings.Settings.data) {
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
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                HapticFeedback.warning()
                profileStore.resetProfile()
            } label: {
                Label(Strings.Settings.resetProfile, systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func startImport() {
        Task {
            do {
                _ = try await dataImporter.importFromGitHub(overwriteExisting: overwriteExisting)
                // Refresh events after import
                eventStore.loadEvents(for: Date())
            } catch {
                importError = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    SettingsView(
        profileStore: ProfileStore(),
        dataImporter: DataImporter(),
        eventStore: EventStore(),
        notificationService: NotificationService()
    )
}
