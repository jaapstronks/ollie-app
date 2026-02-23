//
//  SkillCard.swift
//  Ollie-app
//
//  Expandable card displaying a training skill and its progress
//

import SwiftUI
import OllieShared

/// Expandable card showing a training skill with details
struct SkillCard: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let isLocked: Bool
    let missingRequirements: [Skill]
    let recentSessions: [PuppyEvent]
    let onLogSession: () -> Void
    let onToggleMastered: () -> Void

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header - always visible
            collapsedHeader

            // Expanded content
            if isExpanded && !isLocked {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .glassStatusCard(tintColor: cardTintColor)
        .opacity(isLocked ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isLocked else { return }
            HapticFeedback.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }

    // MARK: - Collapsed Header

    @ViewBuilder
    private var collapsedHeader: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: skill.icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.ollieAccent)
                .frame(width: 36)

            // Name and status
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(isLocked ? .secondary : .primary)

                // Status or locked indicator
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text(Strings.Training.locked)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 6) {
                        // Status badge
                        statusBadge

                        // Session count
                        if sessionCount > 0 {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(Strings.Training.sessionCount(sessionCount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Expand/collapse indicator or lock
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
            }
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(status.color)
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.vertical, 8)

            // Description
            Text(skill.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // How to train
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Training.howTo)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(skill.howTo.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .frame(width: 20, alignment: .leading)
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Done when
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Training.doneWhen)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ollieSuccess)
                    Text(skill.doneWhen)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Tips
            if !skill.tips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Strings.Training.tips)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    ForEach(skill.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.ollieWarning)
                            Text(tip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Recent sessions
            if !recentSessions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Strings.Training.recentSessions)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    ForEach(recentSessions.prefix(3)) { session in
                        HStack(spacing: 8) {
                            Text(session.time.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let duration = session.durationMin {
                                Text("•")
                                    .foregroundStyle(.tertiary)
                                Text("\(duration) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let result = session.result, !result.isEmpty {
                                Text("•")
                                    .foregroundStyle(.tertiary)
                                Text(result)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                // Log session button
                TrainingActionButton(
                    icon: "plus.circle.fill",
                    title: Strings.Training.logSession,
                    style: .primary
                ) {
                    HapticFeedback.selection()
                    onLogSession()
                }

                // Mark mastered button
                TrainingActionButton(
                    icon: status == .mastered ? "checkmark.circle.fill" : "checkmark.circle",
                    title: status == .mastered ? Strings.Training.unmarkMastered : Strings.Training.markMastered,
                    style: status == .mastered ? .success : .successOutline
                ) {
                    HapticFeedback.medium()
                    onToggleMastered()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var cardTintColor: Color? {
        if isLocked {
            return nil
        }
        switch status {
        case .notStarted: return nil
        case .started: return Color.ollieInfo
        case .practicing: return Color.ollieWarning
        case .mastered: return Color.ollieSuccess
        }
    }
}

// MARK: - Training Action Button

/// A responsive button with immediate press feedback for training actions
private struct TrainingActionButton: View {
    let icon: String
    let title: String
    let style: Style
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    enum Style {
        case primary
        case success
        case successOutline
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(borderOverlay)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.ollieAccent
        case .success:
            return Color.ollieSuccess
        case .successOutline:
            return Color.ollieSuccess.opacity(colorScheme == .dark ? 0.15 : 0.1)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .success:
            return .white
        case .successOutline:
            return .ollieSuccess
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if style == .successOutline {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.ollieSuccess, lineWidth: 1)
        }
    }
}

// MARK: - Locked Skill Card

/// Simpler card for locked skills showing requirements
struct LockedSkillCard: View {
    let skill: Skill
    let missingRequirements: [Skill]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text(Strings.Training.locked)
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }

            // Requirements
            if !missingRequirements.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Training.requires)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    HStack(spacing: 8) {
                        ForEach(missingRequirements) { req in
                            HStack(spacing: 4) {
                                Image(systemName: req.icon)
                                    .font(.caption)
                                Text(req.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .glassStatusCard()
        .opacity(0.6)
    }
}

// MARK: - Scale Button Style

/// A button style that provides scale feedback without blocking scroll gestures
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

private let previewSkill = Skill(
    id: "sit",
    icon: "arrow.down.to.line",
    category: .basicCommands,
    week: 2,
    priority: 1,
    requires: ["luring"]
)

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SkillCard(
                skill: previewSkill,
                status: .practicing,
                sessionCount: 6,
                isLocked: false,
                missingRequirements: [],
                recentSessions: [],
                onLogSession: {},
                onToggleMastered: {}
            )

            SkillCard(
                skill: previewSkill,
                status: .notStarted,
                sessionCount: 0,
                isLocked: true,
                missingRequirements: [],
                recentSessions: [],
                onLogSession: {},
                onToggleMastered: {}
            )
        }
        .padding()
    }
}
