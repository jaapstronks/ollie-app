//
//  WeekHeroCard.swift
//  Ollie-app
//
//  Hero card showing current week and focus skills
//

import SwiftUI

/// Hero card displaying the current training week and focus skills
struct WeekHeroCard: View {
    let currentWeek: Int
    let weekTitle: String
    let focusSkills: [Skill]
    let progress: (started: Int, total: Int)
    let onSkillTap: (Skill) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Week header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Training.weekNumber(currentWeek))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(weekTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Progress indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Strings.Training.progressCount(started: progress.started, total: progress.total))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    ProgressView(value: progress.total > 0 ? Double(progress.started) / Double(progress.total) : 0)
                        .frame(width: 80)
                        .tint(Color.ollieAccent)
                }
            }

            // Focus skills chips
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Training.focusSkills)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                FlowLayout(spacing: 8) {
                    ForEach(focusSkills) { skill in
                        Button {
                            onSkillTap(skill)
                        } label: {
                            HStack(spacing: 6) {
                                Text(skill.emoji)
                                    .font(.system(size: 14))
                                Text(skill.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(skillChipBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        Color.ollieAccent.opacity(colorScheme == .dark ? 0.3 : 0.2),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .glassStatusCard(tintColor: Color.ollieAccent)
    }

    @ViewBuilder
    private var skillChipBackground: some View {
        if colorScheme == .dark {
            Color.ollieAccent.opacity(0.15)
        } else {
            Color.ollieAccent.opacity(0.1)
        }
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a flowing grid
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                self.size.width = max(self.size.width, currentX - spacing)
            }

            self.size.height = currentY + lineHeight
        }
    }
}

// MARK: - Preview

#Preview {
    let skill1 = Skill(
        id: "clicker",
        name: "Clicker",
        emoji: "🔔",
        description: "Learn the clicker",
        howTo: ["Step 1"],
        doneWhen: "When done",
        tips: ["Tip 1"],
        category: .fundamenten,
        week: 1,
        priority: 1,
        requires: []
    )

    let skill2 = Skill(
        id: "naam",
        name: "Name Recognition",
        emoji: "📛",
        description: "Learn the name",
        howTo: ["Step 1"],
        doneWhen: "When done",
        tips: ["Tip 1"],
        category: .fundamenten,
        week: 1,
        priority: 2,
        requires: []
    )

    return WeekHeroCard(
        currentWeek: 1,
        weekTitle: "Foundation Week",
        focusSkills: [skill1, skill2],
        progress: (1, 5),
        onSkillTap: { _ in }
    )
    .padding()
}
