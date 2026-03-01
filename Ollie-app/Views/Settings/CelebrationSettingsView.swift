//
//  CelebrationSettingsView.swift
//  Otis-app
//
//  Settings for celebration style preferences

import SwiftUI
import OtisShared

/// Settings view for controlling celebration behavior
struct CelebrationSettingsView: View {
    @AppStorage(UserPreferences.Key.celebrationStyle.rawValue)
    private var celebrationStyleRaw: String = CelebrationStyle.full.rawValue

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
                                .foregroundStyle(Color.otisAccent)
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
                CelebrationTier1PreviewButton()

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
                            .foregroundStyle(Color.otisPurple)
                    }
                    .padding()
                    .background(Color.otisPurple.opacity(0.08))
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
                            .foregroundStyle(Color.otisRose)
                    }
                    .padding()
                    .background(Color.otisRose.opacity(0.08))
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
        // Tier 2 full screen (using fullScreenCover for better presentation)
        .fullScreenCover(isPresented: $showingTier2Preview) {
            CelebrationTier2PreviewWrapper(isPresented: $showingTier2Preview)
        }
        // Tier 3 full screen
        .fullScreenCover(isPresented: $showingTier3Preview) {
            CelebrationTier3PreviewWrapper(isPresented: $showingTier3Preview)
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
                .foregroundStyle(Color.otisAccent)
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
        case .full: return .otisAccent
        case .subtle: return .otisPurple
        case .minimal: return .otisInfo
        case .off: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CelebrationSettingsView()
    }
}
