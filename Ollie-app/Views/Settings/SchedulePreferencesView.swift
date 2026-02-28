//
//  SchedulePreferencesView.swift
//  Ollie-app
//
//  Schedule and preferences settings: walks, meals, notifications

import SwiftUI
import TipKit
import OllieShared

/// Settings screen for schedules and preferences
struct SchedulePreferencesView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var notificationService: NotificationService

    @State private var showingMealEdit = false
    @State private var showingWalkScheduleEdit = false
    @State private var showingNotificationSettings = false

    private let mealRemindersTip = MealRemindersTip()

    var body: some View {
        Form {
            if let profile = profileStore.profile {
                // Walk schedule
                WalkSection(
                    profile: profile,
                    profileStore: profileStore,
                    showingWalkScheduleEdit: $showingWalkScheduleEdit
                )

                // Meal schedule
                MealSection(
                    profile: profile,
                    profileStore: profileStore,
                    showingMealEdit: $showingMealEdit
                )

                // Notifications
                notificationSection(profile)
            }
        }
        .navigationTitle(Strings.Settings.schedulePreferences)
        .sheet(isPresented: $showingMealEdit) {
            if let profile = profileStore.profile {
                MealScheduleEditorWrapper(
                    initialSchedule: profile.mealSchedule,
                    onSave: { updatedSchedule in
                        profileStore.updateMealSchedule(updatedSchedule)
                    }
                )
            }
        }
        .sheet(isPresented: $showingWalkScheduleEdit) {
            if let profile = profileStore.profile {
                WalkScheduleEditorWrapper(
                    initialSchedule: profile.walkSchedule,
                    ageInMonths: profile.ageInMonths,
                    onSave: { updatedSchedule in
                        profileStore.updateWalkSchedule(updatedSchedule)
                    }
                )
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(
                profileStore: profileStore,
                notificationService: notificationService
            )
        }
    }

    // MARK: - Notification Section

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
    }
}

#Preview {
    NavigationStack {
        SchedulePreferencesView(
            profileStore: ProfileStore(),
            notificationService: NotificationService()
        )
    }
}
