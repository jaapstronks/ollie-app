//
//  NotificationSettingsView.swift
//  Ollie-app
//
//  Settings view for smart notifications
//

import SwiftUI

/// View for configuring notification settings
struct NotificationSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var notificationService: NotificationService
    @Environment(\.dismiss) private var dismiss

    // Local state for editing
    @State private var settings: NotificationSettings = NotificationSettings.defaultSettings()
    @State private var walkSchedule: WalkSchedule = WalkSchedule.defaultSchedule()
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationStack {
            Form {
                permissionSection
                masterToggleSection

                if settings.isEnabled {
                    pottySection
                    mealSection
                    napSection
                    walkSection
                }
            }
            .navigationTitle(Strings.Notifications.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveSettings()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .alert(Strings.Notifications.disabledTitle, isPresented: $showingPermissionAlert) {
                Button(Strings.Notifications.settings) {
                    openSystemSettings()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            } message: {
                Text(Strings.Notifications.enableInSettings)
            }
        }
    }

    // MARK: - Permission Section

    @ViewBuilder
    private var permissionSection: some View {
        if !notificationService.isAuthorized {
            Section {
                HStack {
                    Image(systemName: "bell.slash.fill")
                        .foregroundColor(.ollieWarning)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.Notifications.disabledTitle)
                            .font(.headline)
                        Text(Strings.Notifications.enableToReceive)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(Strings.Common.allow) {
                        requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.ollieAccent)
                }
            }
        }
    }

    // MARK: - Master Toggle

    private var masterToggleSection: some View {
        Section {
            Toggle(isOn: $settings.isEnabled) {
                Label {
                    Text(Strings.Notifications.remindersLabel)
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.ollieAccent)
                }
            }
            .onChange(of: settings.isEnabled) { _, newValue in
                if newValue && !notificationService.isAuthorized {
                    settings.isEnabled = false
                    showingPermissionAlert = true
                }
            }
        } footer: {
            Text(Strings.Notifications.remindersDescription)
        }
    }

    // MARK: - Potty Section

    private var pottySection: some View {
        Section {
            Toggle(isOn: $settings.pottyReminders.isEnabled) {
                Label {
                    Text(Strings.Notifications.pottyReminders)
                } icon: {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.ollieInfo)
                }
            }

            if settings.pottyReminders.isEnabled {
                Picker(Strings.Notifications.whenToNotify, selection: $settings.pottyReminders.urgencyLevel) {
                    ForEach(PottyNotificationLevel.allCases) { level in
                        Text(level.label)
                            .tag(level)
                    }
                }
            }
        } header: {
            Text(Strings.Notifications.pottyAlarm)
        } footer: {
            if settings.pottyReminders.isEnabled {
                Text(settings.pottyReminders.urgencyLevel.description)
            }
        }
    }

    // MARK: - Meal Section

    private var mealSection: some View {
        Section {
            Toggle(isOn: $settings.mealReminders.isEnabled) {
                Label {
                    Text(Strings.Notifications.mealReminder)
                } icon: {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.ollieSuccess)
                }
            }

            if settings.mealReminders.isEnabled {
                Stepper(
                    Strings.Notifications.minutesBefore(settings.mealReminders.minutesBefore),
                    value: $settings.mealReminders.minutesBefore,
                    in: 5...30,
                    step: 5
                )
            }
        } header: {
            Text(Strings.Notifications.mealsSection)
        } footer: {
            if settings.mealReminders.isEnabled {
                Text(Strings.Notifications.mealReminderDescription)
            }
        }
    }

    // MARK: - Nap Section

    private var napSection: some View {
        Section {
            Toggle(isOn: $settings.napReminders.isEnabled) {
                Label {
                    Text(Strings.Notifications.napNeeded)
                } icon: {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.ollieMuted)
                }
            }

            if settings.napReminders.isEnabled {
                Stepper(
                    Strings.Notifications.awakeThreshold(settings.napReminders.awakeThresholdMinutes),
                    value: $settings.napReminders.awakeThresholdMinutes,
                    in: 30...90,
                    step: 15
                )
            }
        } header: {
            Text(Strings.Notifications.napsSection)
        } footer: {
            if settings.napReminders.isEnabled {
                Text(Strings.Notifications.napReminderDescription(name: puppyName))
            }
        }
    }

    // MARK: - Walk Section

    private var walkSection: some View {
        Section {
            Toggle(isOn: $settings.walkReminders.isEnabled) {
                Label {
                    Text(Strings.Notifications.walkReminders)
                } icon: {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.ollieAccent)
                }
            }

            if settings.walkReminders.isEnabled {
                Stepper(
                    Strings.Notifications.minutesBefore(settings.walkReminders.minutesBefore),
                    value: $settings.walkReminders.minutesBefore,
                    in: 5...30,
                    step: 5
                )

                // Walk schedule
                ForEach($walkSchedule.walks) { $walk in
                    HStack {
                        TextField(Strings.Notifications.label, text: $walk.label)
                            .textFieldStyle(.plain)
                        Spacer()
                        TimePickerField(timeString: $walk.targetTime)
                    }
                }

                Button {
                    addWalk()
                } label: {
                    Label(Strings.Notifications.addWalk, systemImage: "plus")
                }

                if walkSchedule.walks.count > 1 {
                    Button(role: .destructive) {
                        HapticFeedback.warning()
                        removeLastWalk()
                    } label: {
                        Label(Strings.Notifications.removeLast, systemImage: "minus")
                    }
                }
            }
        } header: {
            Text(Strings.Notifications.walksSection)
        } footer: {
            if settings.walkReminders.isEnabled {
                Text(Strings.Notifications.walkReminderDescription)
            }
        }
    }

    // MARK: - Helpers

    private var puppyName: String {
        profileStore.profile?.name ?? "Puppy"
    }

    private func loadCurrentSettings() {
        if let profile = profileStore.profile {
            settings = profile.notificationSettings
            walkSchedule = profile.walkSchedule
        }
    }

    private func saveSettings() {
        guard var profile = profileStore.profile else { return }
        profile.notificationSettings = settings
        profile.walkSchedule = walkSchedule
        profileStore.saveProfile(profile)
        dismiss()
    }

    private func requestPermission() {
        Task {
            let granted = await notificationService.requestAuthorization()
            if granted {
                settings.isEnabled = true
            } else {
                showingPermissionAlert = true
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func addWalk() {
        let newWalk = WalkSchedule.ScheduledWalk(
            label: Strings.Notifications.walkNumber(walkSchedule.walks.count + 1),
            targetTime: "12:00"
        )
        walkSchedule.walks.append(newWalk)
    }

    private func removeLastWalk() {
        guard walkSchedule.walks.count > 1 else { return }
        walkSchedule.walks.removeLast()
    }
}

// MARK: - Time Picker Field

/// A simple time picker that binds to a "HH:mm" string
struct TimePickerField: View {
    @Binding var timeString: String
    @State private var selectedTime: Date = Date()

    var body: some View {
        DatePicker(
            "",
            selection: $selectedTime,
            displayedComponents: .hourAndMinute
        )
        .labelsHidden()
        .onChange(of: selectedTime) { _, newValue in
            timeString = newValue.timeString
        }
        .onAppear {
            selectedTime = DateFormatters.timeOnly.date(from: timeString) ?? Date()
        }
    }
}

#Preview {
    NotificationSettingsView(
        profileStore: ProfileStore(),
        notificationService: NotificationService()
    )
}
