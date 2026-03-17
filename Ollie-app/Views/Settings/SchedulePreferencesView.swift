//
//  SchedulePreferencesView.swift
//  Otis-app
//
//  Schedule and preferences settings: walks, meals, notifications

import SwiftUI
import TipKit
import OtisShared

/// Settings screen for schedules and preferences
struct SchedulePreferencesView: View {
    var profileStore: ProfileStore
    var notificationService: NotificationService
    let profileId: UUID

    @State private var showingMealEdit = false
    @State private var showingWalkScheduleEdit = false
    @State private var showingNotificationSettings = false

    private let mealRemindersTip = MealRemindersTip()

    /// The profile being edited (looked up by ID)
    private var targetProfile: PuppyProfile? {
        profileStore.profile(for: profileId)
    }

    var body: some View {
        Form {
            if let profile = targetProfile {
                // Walk schedule
                WalkSection(
                    profile: profile,
                    profileStore: profileStore,
                    profileId: profileId,
                    showingWalkScheduleEdit: $showingWalkScheduleEdit
                )

                // Meal schedule
                MealSection(
                    profile: profile,
                    profileStore: profileStore,
                    profileId: profileId,
                    showingMealEdit: $showingMealEdit
                )

                // Notifications
                notificationSection(profile)
            }
        }
        .navigationTitle(Strings.Settings.schedulePreferences)
        .sheet(isPresented: $showingMealEdit) {
            if let profile = targetProfile {
                MealScheduleEditorWrapper(
                    initialSchedule: profile.mealSchedule,
                    onSave: { updatedSchedule in
                        profileStore.updateMealSchedule(updatedSchedule, for: profileId)
                    }
                )
            }
        }
        .sheet(isPresented: $showingWalkScheduleEdit) {
            if let profile = targetProfile {
                WalkScheduleEditorWrapper(
                    initialSchedule: profile.walkSchedule,
                    ageInMonths: profile.ageInMonths,
                    onSave: { updatedSchedule in
                        profileStore.updateWalkSchedule(updatedSchedule, for: profileId)
                    }
                )
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(
                profileStore: profileStore,
                notificationService: notificationService,
                profileId: profileId
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
                            .foregroundStyle(Color.otisAccent)
                    }
                    Spacer()
                    Text(profile.notificationSettings.isEnabled ? Strings.Common.on : Strings.Common.off)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        SchedulePreferencesView(
            profileStore: ProfileStore(),
            notificationService: NotificationService(),
            profileId: UUID()
        )
    }
}
