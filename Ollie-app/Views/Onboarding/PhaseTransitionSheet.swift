//
//  PhaseTransitionSheet.swift
//  Otis-app
//
//  Celebration sheet shown when a dog enters a new lifecycle phase

import SwiftUI
import OtisShared

/// Sheet shown when a dog transitions to a new lifecycle phase
/// Celebrates the milestone and offers notification preference adjustment
struct PhaseTransitionSheet: View {
    let profile: PuppyProfile
    let onDismiss: (Bool) -> Void  // Bool = whether to apply suggested notification defaults

    @State private var applyNotificationDefaults = true
    @Environment(\.colorScheme) private var colorScheme

    private var currentPhase: LifecyclePhase {
        profile.lifecyclePhase
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration header
                    celebrationHeader
                        .padding(.top, 40)

                    // What's changing
                    changesSection
                        .padding(.horizontal, 24)

                    // Notification preference picker
                    notificationPreferencePicker
                        .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 20)
                }
            }

            // Bottom CTA
            VStack(spacing: 12) {
                Button {
                    HapticFeedback.success()
                    onDismiss(applyNotificationDefaults)
                } label: {
                    Text(Strings.LifecycleTransition.letsGo)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.otisAccent)
                        )
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .padding(.top, 8)
            .background(
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            )
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .interactiveDismissDisabled(true)
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            // Phase-specific icon with celebration styling
            ZStack {
                Circle()
                    .fill(phaseColor.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: phaseIcon)
                    .font(.system(size: 44))
                    .foregroundStyle(phaseColor)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text(titleText)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Changes Section

    private var changesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(changes, id: \.self) { change in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(phaseColor)
                        .font(.title3)

                    Text(change)
                        .font(.body)

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
        )
    }

    // MARK: - Notification Preference Picker

    private var notificationPreferencePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.LifecycleTransition.Notifications.title)
                .font(.headline)

            VStack(spacing: 8) {
                // Keep current settings option
                NotificationOptionRow(
                    title: Strings.LifecycleTransition.Notifications.keepCurrent,
                    description: nil,
                    isSelected: !applyNotificationDefaults,
                    action: { applyNotificationDefaults = false }
                )

                // Use recommended settings option
                NotificationOptionRow(
                    title: Strings.LifecycleTransition.Notifications.useDefaults,
                    description: Strings.LifecycleTransition.Notifications.defaultsDescription(phase: currentPhase.label),
                    isSelected: applyNotificationDefaults,
                    action: { applyNotificationDefaults = true }
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var titleText: String {
        switch currentPhase {
        case .teenage:
            return Strings.LifecycleTransition.Teenage.title(name: profile.name)
        case .adult:
            return Strings.LifecycleTransition.Adult.title(name: profile.name)
        case .senior:
            return Strings.LifecycleTransition.Senior.title(name: profile.name)
        case .puppy:
            return profile.name // Should not happen
        }
    }

    private var subtitleText: String {
        switch currentPhase {
        case .teenage:
            return Strings.LifecycleTransition.Teenage.subtitle(name: profile.name)
        case .adult:
            return Strings.LifecycleTransition.Adult.subtitle(name: profile.name)
        case .senior:
            return Strings.LifecycleTransition.Senior.subtitle(name: profile.name)
        case .puppy:
            return "" // Should not happen
        }
    }

    private var changes: [String] {
        switch currentPhase {
        case .teenage:
            return [
                Strings.LifecycleTransition.Teenage.behaviorTracking,
                Strings.LifecycleTransition.Teenage.maintenanceMode,
                Strings.LifecycleTransition.Teenage.adventureFocus
            ]
        case .adult:
            return [
                Strings.LifecycleTransition.Adult.routineFocus,
                Strings.LifecycleTransition.Adult.healthMonitoring,
                Strings.LifecycleTransition.Adult.memoriesCapture
            ]
        case .senior:
            return [
                Strings.LifecycleTransition.Senior.wellnessCheckins,
                Strings.LifecycleTransition.Senior.medicationReminders,
                Strings.LifecycleTransition.Senior.comfortTips
            ]
        case .puppy:
            return [] // No transition TO puppy
        }
    }

    private var phaseIcon: String {
        switch currentPhase {
        case .puppy:
            return "pawprint.fill"
        case .teenage:
            return "figure.run"
        case .adult:
            return "house.fill"
        case .senior:
            return "heart.fill"
        }
    }

    private var phaseColor: Color {
        switch currentPhase {
        case .puppy:
            return .otisAccent
        case .teenage:
            return .orange
        case .adult:
            return .blue
        case .senior:
            return .purple
        }
    }
}

// MARK: - Notification Option Row

private struct NotificationOptionRow: View {
    let title: String
    let description: String?
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.otisAccent : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(isSelected ? .primary : .secondary)

                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? (colorScheme == .dark ? Color.otisAccent.opacity(0.2) : Color.otisAccent.opacity(0.1))
                          : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.otisAccent.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Teenage Transition") {
    let calendar = Calendar.current
    let birthDate = calendar.date(byAdding: .month, value: -10, to: Date()) ?? Date()

    let profile = PuppyProfile.defaultProfile(
        name: "Luna",
        birthDate: birthDate,
        homeDate: calendar.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
        size: .medium
    )

    return PhaseTransitionSheet(profile: profile) { _ in }
}

#Preview("Adult Transition") {
    let calendar = Calendar.current
    let birthDate = calendar.date(byAdding: .month, value: -20, to: Date()) ?? Date()

    let profile = PuppyProfile.defaultProfile(
        name: "Max",
        birthDate: birthDate,
        homeDate: calendar.date(byAdding: .month, value: -18, to: Date()) ?? Date(),
        size: .large
    )

    return PhaseTransitionSheet(profile: profile) { _ in }
}

#Preview("Senior Transition") {
    let calendar = Calendar.current
    let birthDate = calendar.date(byAdding: .year, value: -8, to: Date()) ?? Date()

    let profile = PuppyProfile.defaultProfile(
        name: "Buddy",
        birthDate: birthDate,
        homeDate: calendar.date(byAdding: .year, value: -7, to: Date()) ?? Date(),
        size: .medium
    )

    return PhaseTransitionSheet(profile: profile) { _ in }
}
