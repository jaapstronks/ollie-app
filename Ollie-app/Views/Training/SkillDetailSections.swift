//
//  SkillDetailSections.swift
//  Otis-app
//
//  Reusable section components for skill detail views
//

import SwiftUI
import OtisShared

// MARK: - Numbered Steps Section

/// Displays a numbered list of steps (used for "How To" instructions)
struct NumberedStepsSection: View {
    let title: String
    let icon: String
    let steps: [String]
    var accentColor: Color = .otisAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TrainingSectionHeader(title: title, icon: icon)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(accentColor)
                            .frame(width: 24, alignment: .leading)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Bulleted List Section

/// Displays a bulleted list with custom icon and styling
struct BulletedListSection: View {
    let title: String
    let headerIcon: String
    let items: [String]
    let bulletIcon: String
    var bulletColor: Color = .secondary
    var backgroundColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TrainingSectionHeader(title: title, icon: headerIcon)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: bulletIcon)
                            .font(.caption)
                            .foregroundStyle(bulletColor)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(backgroundColor != nil ? 16 : 0)
            .background(
                Group {
                    if let bgColor = backgroundColor {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(bgColor)
                    }
                }
            )
        }
    }
}

// MARK: - Single Item Section

/// Displays a section with a single item (used for "Done When" criteria)
struct SingleItemSection: View {
    let title: String
    let headerIcon: String
    let text: String
    let bulletIcon: String
    var bulletColor: Color = .otisSuccess

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TrainingSectionHeader(title: title, icon: headerIcon)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: bulletIcon)
                    .font(.subheadline)
                    .foregroundStyle(bulletColor)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Recent Sessions Section

/// Displays a list of recent training sessions
struct RecentSessionsSection: View {
    let sessions: [PuppyEvent]
    var maxCount: Int = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TrainingSectionHeader(title: Strings.Training.recentSessions, icon: "clock")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(sessions.prefix(maxCount)) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

/// A single session row showing date, duration, and result
private struct SessionRow: View {
    let session: PuppyEvent

    var body: some View {
        HStack(spacing: 12) {
            Text(session.time.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let duration = session.durationMin {
                Text("•")
                    .foregroundStyle(.tertiary)
                Text("\(duration) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let result = session.result, !result.isEmpty {
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(result)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Skill Action Buttons

/// Primary and secondary action buttons for skill detail views
struct SkillActionButtons: View {
    let status: SkillStatus
    let onStartTraining: () -> Void
    let onLogSession: () -> Void
    let onToggleMastered: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            // Primary action: Start training
            Button {
                HapticFeedback.medium()
                onDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onStartTraining()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text(Strings.TrainingSession.startTraining)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.otisAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // Secondary actions row
            HStack(spacing: 12) {
                // Log session
                Button {
                    HapticFeedback.light()
                    onDismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onLogSession()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text(Strings.Training.logSession)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.otisAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.otisAccent, lineWidth: 1.5)
                    )
                }

                // Toggle mastered
                if status == .practicing || status == .mastered {
                    Button {
                        HapticFeedback.medium()
                        onToggleMastered()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: status == .mastered ? "checkmark.circle.fill" : "checkmark.circle")
                            Text(status == .mastered ? Strings.Training.unmarkMastered : Strings.Training.markMastered)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(status == .mastered ? Color.otisSuccess : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Skill Header Card

/// Header card showing skill icon, status, method, and session count
struct SkillHeaderCard: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int

    var body: some View {
        HStack(spacing: 16) {
            IconCircle(systemName: skill.icon)

            VStack(alignment: .leading, spacing: 4) {
                StatusBadge(status: status)

                HStack(spacing: 8) {
                    if let method = skill.method {
                        MethodBadge(method: method)
                    }

                    if let recommendation = skill.sessionRecommendation {
                        if skill.method != nil {
                            Text("•")
                                .foregroundStyle(.tertiary)
                        }
                        Text(recommendation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if sessionCount > 0 {
                    Text(Strings.Training.sessionCount(sessionCount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .glassStatusCard(tintColor: status == .mastered ? .otisSuccess : nil)
    }
}

// MARK: - Previews

#Preview("Numbered Steps") {
    NumberedStepsSection(
        title: "How to Train",
        icon: "list.number",
        steps: [
            "Get your clicker and treats ready",
            "Click and immediately give a treat",
            "Repeat 10-15 times per session",
            "Practice 2-3 times per day"
        ]
    )
    .padding()
}

#Preview("Bulleted List - Tips") {
    BulletedListSection(
        title: "Tips",
        headerIcon: "lightbulb",
        items: [
            "Keep sessions short and fun",
            "End on a positive note",
            "Practice in different locations"
        ],
        bulletIcon: "lightbulb.fill",
        bulletColor: .orange
    )
    .padding()
}

#Preview("Bulleted List - Mistakes") {
    BulletedListSection(
        title: "Common Mistakes",
        headerIcon: "exclamationmark.triangle",
        items: [
            "Clicking without treating",
            "Clicking too late"
        ],
        bulletIcon: "xmark.circle.fill",
        bulletColor: .red.opacity(0.8),
        backgroundColor: .red.opacity(0.08)
    )
    .padding()
}

#Preview("Single Item") {
    SingleItemSection(
        title: "Done When",
        headerIcon: "checkmark.circle",
        text: "Your puppy looks at you immediately when they hear the click",
        bulletIcon: "checkmark.circle.fill",
        bulletColor: .green
    )
    .padding()
}
