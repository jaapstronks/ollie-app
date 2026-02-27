//
//  CelebrationSettingsView.swift
//  Ollie-app
//
//  Settings for celebration style preferences

import SwiftUI
import OllieShared

/// Settings view for controlling celebration behavior
struct CelebrationSettingsView: View {
    @AppStorage(UserPreferences.Key.celebrationStyle.rawValue)
    private var celebrationStyleRaw: String = CelebrationStyle.full.rawValue

    @State private var showingPreview = false
    @State private var previewTier: CelebrationTier = .notable

    @Environment(\.colorScheme) private var colorScheme

    private var celebrationStyle: CelebrationStyle {
        get { CelebrationStyle(rawValue: celebrationStyleRaw) ?? .full }
        nonmutating set { celebrationStyleRaw = newValue.rawValue }
    }

    var body: some View {
        Form {
            // Style picker
            styleSection

            // Preview section
            previewSection

            // Info section
            infoSection
        }
        .navigationTitle(Strings.Celebrations.celebrationStyle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Style Section

    @ViewBuilder
    private var styleSection: some View {
        Section {
            ForEach(CelebrationStyle.allCases) { style in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        celebrationStyleRaw = style.rawValue
                    }
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(iconColor(for: style).opacity(0.15))
                                .frame(width: 40, height: 40)

                            Image(systemName: iconName(for: style))
                                .font(.system(size: 18))
                                .foregroundStyle(iconColor(for: style))
                        }

                        // Text
                        VStack(alignment: .leading, spacing: 2) {
                            Text(style.displayName)
                                .font(.body)
                                .foregroundStyle(.primary)

                            Text(style.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Selection indicator
                        if celebrationStyle == style {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.ollieAccent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text(Strings.Celebrations.celebrationStyle)
        } footer: {
            Text(Strings.Celebrations.celebrationStyleDescription)
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        Section {
            VStack(spacing: 12) {
                // Mini preview cards
                HStack(spacing: 12) {
                    previewCard(tier: .subtle, label: "Tier 1")
                    previewCard(tier: .notable, label: "Tier 2")
                    previewCard(tier: .major, label: "Tier 3")
                }

                // Preview button
                Button {
                    showingPreview = true
                    previewTier = .notable
                } label: {
                    Label("Preview Tier 2", systemImage: "play.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.glassPill(tint: .accent))
            }
            .padding(.vertical, 8)
        } header: {
            Text("Preview")
        }
        .sheet(isPresented: $showingPreview) {
            Tier2CelebrationCard(
                achievement: Achievement(
                    id: "preview.health",
                    category: .health,
                    tier: .notable,
                    labelKey: "achievement.health.firstVaccination"
                ),
                puppyName: "Preview",
                onAddPhoto: { showingPreview = false },
                onShare: { showingPreview = false },
                onDismiss: { showingPreview = false }
            )
            .presentationBackground(.clear)
        }
    }

    @ViewBuilder
    private func previewCard(tier: CelebrationTier, label: String) -> some View {
        let effectiveTier = celebrationStyle.transform(tier)

        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(effectiveTier != nil ? Color.ollieAccent.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(height: 60)

                if let effective = effectiveTier {
                    Image(systemName: iconForTier(effective))
                        .font(.title2)
                        .foregroundStyle(effective == tier ? Color.ollieAccent : Color.secondary)
                } else {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Info Section

    @ViewBuilder
    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                infoRow(
                    icon: "sparkles",
                    title: "Tier 1: Subtle",
                    description: "Inline shimmer effect, no interruption"
                )

                infoRow(
                    icon: "party.popper",
                    title: "Tier 2: Notable",
                    description: "Card with gentle confetti"
                )

                infoRow(
                    icon: "star.fill",
                    title: "Tier 3: Major",
                    description: "Full-screen celebration"
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("How celebrations work")
        } footer: {
            Text("Achievements are still tracked even with celebrations turned off. You can view them in your memories.")
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.ollieAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func iconName(for style: CelebrationStyle) -> String {
        switch style {
        case .full: return "sparkles"
        case .subtle: return "wand.and.stars"
        case .minimal: return "sparkle"
        case .off: return "bell.slash"
        }
    }

    private func iconColor(for style: CelebrationStyle) -> Color {
        switch style {
        case .full: return .ollieAccent
        case .subtle: return .olliePurple
        case .minimal: return .ollieInfo
        case .off: return .secondary
        }
    }

    private func iconForTier(_ tier: CelebrationTier) -> String {
        switch tier {
        case .subtle: return "sparkle"
        case .notable: return "party.popper"
        case .major: return "star.fill"
        }
    }
}

#Preview {
    NavigationStack {
        CelebrationSettingsView()
    }
}
