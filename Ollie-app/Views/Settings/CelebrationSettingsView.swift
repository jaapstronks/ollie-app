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

    @State private var showingTier1Preview = false
    @State private var showingTier2Preview = false
    @State private var showingTier3Preview = false

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
            VStack(spacing: 16) {
                // Tier 1: Subtle - inline shimmer preview
                Button {
                    showingTier1Preview = true
                    HapticFeedback.light()
                    // Auto-dismiss after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showingTier1Preview = false
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tier 1: Subtle")
                                .font(.subheadline.weight(.medium))
                            Text("Inline shimmer effect")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.ollieAccent)
                    }
                    .padding()
                    .background(Color.ollieAccent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .overlay {
                    if showingTier1Preview {
                        CelebrationView(style: .quickLog, isActive: $showingTier1Preview)
                    }
                }

                // Tier 2: Notable - card preview
                Button {
                    showingTier2Preview = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tier 2: Notable")
                                .font(.subheadline.weight(.medium))
                            Text("Card with confetti")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.olliePurple)
                    }
                    .padding()
                    .background(Color.olliePurple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                // Tier 3: Major - full screen preview
                Button {
                    showingTier3Preview = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tier 3: Major")
                                .font(.subheadline.weight(.medium))
                            Text("Full-screen celebration")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.ollieRose)
                    }
                    .padding()
                    .background(Color.ollieRose.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Preview")
        } footer: {
            Text("Tap to preview each celebration tier")
        }
        // Tier 2 sheet
        .sheet(isPresented: $showingTier2Preview) {
            ZStack {
                Color.black.opacity(0.001) // Invisible background to capture taps
                    .ignoresSafeArea()

                Tier2CelebrationCard(
                    achievement: Achievement(
                        id: "preview.health",
                        category: .health,
                        tier: .notable,
                        labelKey: "achievement.health.firstVaccination"
                    ),
                    puppyName: "Ollie",
                    onAddPhoto: { showingTier2Preview = false },
                    onShare: { showingTier2Preview = false },
                    onDismiss: { showingTier2Preview = false }
                )
            }
            .presentationBackground(.clear)
        }
        // Tier 3 full screen
        .fullScreenCover(isPresented: $showingTier3Preview) {
            Tier3CelebrationView(
                achievement: Achievement(
                    id: "preview.potty.14",
                    category: .pottyStreak,
                    tier: .major,
                    labelKey: "achievement.pottyStreak.14",
                    value: 14
                ),
                puppyName: "Ollie",
                onTakePhoto: { showingTier3Preview = false },
                onAddFromLibrary: { showingTier3Preview = false },
                onSkip: { showingTier3Preview = false }
            )
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
}

#Preview {
    NavigationStack {
        CelebrationSettingsView()
    }
}
