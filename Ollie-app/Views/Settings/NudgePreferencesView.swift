//
//  NudgePreferencesView.swift
//  Ollie-app
//
//  Settings view for configuring which nudges and reminders the user sees
//  for the active dog profile. Settings are per-dog - each user can have
//  different roles for different dogs (e.g., caregiver for their own dog,
//  helper for a shared dog).
//

import SwiftUI
import OtisShared

struct NudgePreferencesView: View {
    var userIdentityStore: UserIdentityStore
    var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    /// The profile we're editing settings for
    private var activeProfile: PuppyProfile? {
        profileStore.activeProfile
    }

    var body: some View {
        Form {
            if let profile = activeProfile {
                profileHeaderSection(profile)
            }
            responsibilitySection
            nudgeCategoriesSection
            resetSection
        }
        .navigationTitle(Strings.Settings.nudgePreferences)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Profile Header

    private func profileHeaderSection(_ profile: PuppyProfile) -> some View {
        Section {
            HStack(spacing: 12) {
                // Dog avatar
                if let photoFilename = profile.profilePhotoFilename,
                   let image = ProfilePhotoStore.shared.load(filename: photoFilename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.otisAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Settings.settingsForDog(name: profile.name))
                        .font(.headline)
                    if profile.ownership == .shared {
                        Text(Strings.Settings.sharedWithYou)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Responsibility Section

    private var responsibilitySection: some View {
        Section {
            ForEach(ResponsibilityLevel.allCases, id: \.self) { level in
                ResponsibilityOptionRow(
                    level: level,
                    isSelected: currentLevel == level,
                    onSelect: {
                        if let profileId = activeProfile?.id {
                            userIdentityStore.updateResponsibilityLevel(level, for: profileId)
                        }
                        HapticFeedback.light()
                    }
                )
            }
        } header: {
            Text(Strings.Settings.yourRole)
        } footer: {
            Text(Strings.Settings.roleDescription)
        }
    }

    // MARK: - Nudge Categories Section

    private var nudgeCategoriesSection: some View {
        Section {
            ForEach(NudgeCategory.allCases, id: \.self) { category in
                Toggle(isOn: binding(for: category)) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.label)
                            Text(category.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: category.icon)
                            .foregroundStyle(Color.otisAccent)
                    }
                }
            }
        } header: {
            Text(Strings.Settings.whatToSee)
        } footer: {
            Text(Strings.Settings.nudgesFooter)
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        Section {
            Button {
                resetToDefaults()
            } label: {
                Label(Strings.Settings.resetToDefaults, systemImage: "arrow.counterclockwise")
            }
        } footer: {
            Text(Strings.Settings.resetNudgesFooter(currentLevel.label))
        }
    }

    // MARK: - Helpers

    private var currentLevel: ResponsibilityLevel {
        guard let profile = activeProfile else { return .caregiver }
        return userIdentityStore.responsibilityLevel(for: profile.id, ownership: profile.ownership)
    }

    private var currentNudges: Set<NudgeCategory> {
        guard let profile = activeProfile else { return Set(NudgeCategory.allCases) }
        return userIdentityStore.enabledNudges(for: profile.id, ownership: profile.ownership)
    }

    private func binding(for category: NudgeCategory) -> Binding<Bool> {
        Binding(
            get: { currentNudges.contains(category) },
            set: { enabled in
                if let profile = activeProfile {
                    userIdentityStore.toggleNudge(category, enabled: enabled, for: profile.id, ownership: profile.ownership)
                }
                HapticFeedback.light()
            }
        )
    }

    private func resetToDefaults() {
        if let profileId = activeProfile?.id {
            userIdentityStore.updateEnabledNudges(currentLevel.defaultEnabledNudges, for: profileId)
        }
        HapticFeedback.success()
    }
}

// MARK: - Responsibility Option Row

private struct ResponsibilityOptionRow: View {
    let level: ResponsibilityLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: level.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.otisAccent : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.label)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(level.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.otisAccent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NudgePreferencesView(
            userIdentityStore: .shared,
            profileStore: ProfileStoreProvider.shared.store
        )
    }
}
