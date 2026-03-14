//
//  NudgePreferencesView.swift
//  Ollie-app
//
//  Settings view for configuring which nudges and reminders the user sees.
//  Helpers see fewer administrative nudges (appointments, medications) by default.
//

import SwiftUI
import OtisShared

struct NudgePreferencesView: View {
    var userIdentityStore: UserIdentityStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            responsibilitySection
            nudgeCategoriesSection
            resetSection
        }
        .navigationTitle(Strings.Settings.nudgePreferences)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Responsibility Section

    private var responsibilitySection: some View {
        Section {
            ForEach(ResponsibilityLevel.allCases, id: \.self) { level in
                ResponsibilityOptionRow(
                    level: level,
                    isSelected: currentLevel == level,
                    onSelect: {
                        userIdentityStore.updateResponsibilityLevel(level)
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
        userIdentityStore.currentIdentity?.responsibilityLevel ?? .caregiver
    }

    private var currentNudges: Set<NudgeCategory> {
        userIdentityStore.currentIdentity?.enabledNudges ?? Set(NudgeCategory.allCases)
    }

    private func binding(for category: NudgeCategory) -> Binding<Bool> {
        Binding(
            get: { currentNudges.contains(category) },
            set: { enabled in
                userIdentityStore.toggleNudge(category, enabled: enabled)
                HapticFeedback.light()
            }
        )
    }

    private func resetToDefaults() {
        userIdentityStore.updateEnabledNudges(currentLevel.defaultEnabledNudges)
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
        NudgePreferencesView(userIdentityStore: .shared)
    }
}
