//
//  RegressionAlertView.swift
//  Ollie-app
//
//  Friendly, non-alarming UI for skill regressions.
//  Based on training briefing: "Regression is normal, not failure"
//  Uses supportive messaging like "Time for a refresher!" rather than
//  implying the dog or owner failed.
//

import SwiftUI
import OtisShared

// MARK: - Regression Alert Banner

/// A friendly banner shown when skills need refresher attention
struct RegressionAlertBanner: View {
    let skillsNeedingWork: [SkillProgressInfo]
    let onTapSkill: (SkillProgressInfo) -> Void
    let onDismiss: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private var skillCount: Int { skillsNeedingWork.count }

    private var headerMessage: String {
        if skillCount == 1 {
            return Strings.Training.refresherNeededSingle(skillName: skillsNeedingWork.first?.skill.name ?? "")
        } else {
            return Strings.Training.refresherNeededMultiple(count: skillCount)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            supportiveMessageSection
            skillChipsSection
        }
        .padding()
        .background(backgroundShape)
        .overlay(borderShape)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.trianglehead.2.counterclockwise")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Training.refresherTime)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(headerMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            dismissButton
        }
    }

    @ViewBuilder
    private var dismissButton: some View {
        if let onDismiss {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
    }

    private var supportiveMessageSection: some View {
        Text(Strings.Training.regressionNormalMessage)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var skillChipsSection: some View {
        FlowLayout(spacing: 8) {
            ForEach(skillsNeedingWork) { skillInfo in
                skillChipButton(for: skillInfo)
            }
        }
    }

    private func skillChipButton(for skillInfo: SkillProgressInfo) -> some View {
        Button {
            onTapSkill(skillInfo)
        } label: {
            skillChipLabel(for: skillInfo)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.orange)
    }

    private func skillChipLabel(for skillInfo: SkillProgressInfo) -> some View {
        HStack(spacing: 6) {
            Image(systemName: skillInfo.skill.icon)
                .font(.caption)
            Text(skillInfo.skill.name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipBackground)
        .overlay(chipBorder)
    }

    private var chipBackground: some View {
        Capsule()
            .fill(Color.orange.badgeOpacity(colorScheme: colorScheme))
    }

    private var chipBorder: some View {
        Capsule()
            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.orange.subtleBackgroundOpacity(colorScheme: colorScheme))
    }

    private var borderShape: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
    }
}

// MARK: - Regression Recovery Card

/// Shown when a skill has been recovered from regression
struct RegressionRecoveryCard: View {
    let skillName: String
    let sessionsToRecover: Int?
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            // Celebration icon
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .nonRepeating)

            VStack(spacing: 4) {
                Text(Strings.Training.backOnTrack)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(Strings.Training.skillRecovered(skillName: skillName))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let sessions = sessionsToRecover, sessions > 0 {
                Text(Strings.Training.recoveredInSessions(count: sessions))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Button {
                onDismiss()
            } label: {
                Text(Strings.Common.great)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.green.opacity(0.08) : Color.green.opacity(0.05))
        )
    }
}

// MARK: - Inline Regression Badge

/// Small badge shown on skill cards for skills needing work
struct RegressionBadge: View {
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.trianglehead.2.counterclockwise")
                .font(.system(size: isCompact ? 9 : 11))

            if !isCompact {
                Text(Strings.Training.needsRefresher)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
}

// MARK: - Adolescence Info Card

/// Shown to normalize regression during adolescence period (6-18 months)
struct AdolescenceInfoCard: View {
    let puppyAgeMonths: Int
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isInAdolescence: Bool {
        puppyAgeMonths >= 6 && puppyAgeMonths <= 18
    }

    var body: some View {
        if isInAdolescence {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)

                    Text(Strings.Training.adolescenceTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(Strings.Training.adolescenceMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.yellow.opacity(0.08) : Color.yellow.opacity(0.05))
            )
        }
    }
}

// MARK: - Flow Layout Helper

/// Simple horizontal flow layout for skill chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets

        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for size in sizes {
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxX = max(maxX, currentX)
        }

        return (offsets, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

// MARK: - Preview

#Preview("Recovery Card") {
    VStack(spacing: 20) {
        RegressionRecoveryCard(
            skillName: "Recall",
            sessionsToRecover: 3,
            onDismiss: {}
        )

        HStack {
            RegressionBadge(isCompact: false)
            RegressionBadge(isCompact: true)
        }

        AdolescenceInfoCard(
            puppyAgeMonths: 8,
            onDismiss: {}
        )
    }
    .padding()
}
