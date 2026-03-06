//
//  MemberAttributionView.swift
//  Ollie-app
//
//  Components for displaying training session attribution to household members.
//  Shows who trained what, contribution stats, and session history.
//

import SwiftUI
import OtisShared

// MARK: - Member Avatar

/// Small avatar for household member display
struct MemberAvatar: View {
    let member: HouseholdMember?
    let size: AvatarSize

    @Environment(\.colorScheme) private var colorScheme

    enum AvatarSize {
        case small   // 24pt - inline use
        case medium  // 32pt - list items
        case large   // 44pt - headers

        var dimension: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 44
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 14
            case .large: return 18
            }
        }
    }

    var body: some View {
        if let member = member {
            memberAvatar(member)
        } else {
            unknownAvatar
        }
    }

    @ViewBuilder
    private func memberAvatar(_ member: HouseholdMember) -> some View {
        if let avatarData = member.avatarData,
           let uiImage = UIImage(data: avatarData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
        } else {
            Text(member.initial)
                .font(.system(size: size.fontSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size.dimension, height: size.dimension)
                .background(memberColor(member))
                .clipShape(Circle())
        }
    }

    private var unknownAvatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size.fontSize))
            .foregroundStyle(.secondary)
            .frame(width: size.dimension, height: size.dimension)
            .background(Color.secondary.opacity(0.2))
            .clipShape(Circle())
    }

    private func memberColor(_ member: HouseholdMember) -> Color {
        Color(hex: member.colorHex)
    }
}

// MARK: - Training Contribution Card

/// Shows training contributions by household member
struct TrainingContributionCard: View {
    let sessionsByMember: [String: Int]
    let householdMembers: [HouseholdMember]
    let totalSessions: Int

    @Environment(\.colorScheme) private var colorScheme

    private var sortedContributions: [(member: HouseholdMember?, count: Int, percentage: Double)] {
        var contributions: [(member: HouseholdMember?, count: Int, percentage: Double)] = []

        for (memberId, count) in sessionsByMember.sorted(by: { $0.value > $1.value }) {
            let member = householdMembers.first { $0.id.uuidString == memberId }
            let percentage = totalSessions > 0 ? Double(count) / Double(totalSessions) : 0
            contributions.append((member, count, percentage))
        }

        return contributions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(Color.otisAccent)
                Text(Strings.Training.teamContributions)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalSessions) " + Strings.Training.sessions)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Contribution bars
            ForEach(sortedContributions, id: \.member?.id) { contribution in
                contributionRow(contribution)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
        )
    }

    @ViewBuilder
    private func contributionRow(_ contribution: (member: HouseholdMember?, count: Int, percentage: Double)) -> some View {
        HStack(spacing: 10) {
            MemberAvatar(member: contribution.member, size: .small)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contribution.member?.name ?? Strings.Common.unknown)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(contribution.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 6)

                        Capsule()
                            .fill(memberColor(contribution.member))
                            .frame(width: geo.size.width * contribution.percentage, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private func memberColor(_ member: HouseholdMember?) -> Color {
        guard let member = member else { return Color.secondary }
        return Color(hex: member.colorHex)
    }
}

// MARK: - Session Attribution Label

/// Inline label showing who logged a training session
struct SessionAttributionLabel: View {
    let member: HouseholdMember?
    let timestamp: Date
    let showName: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(member: HouseholdMember?, timestamp: Date, showName: Bool = true) {
        self.member = member
        self.timestamp = timestamp
        self.showName = showName
    }

    var body: some View {
        HStack(spacing: 6) {
            MemberAvatar(member: member, size: .small)

            if showName, let member = member {
                Text(member.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(timestamp.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Recent Sessions by Member

/// Shows recent training sessions grouped by household member
struct RecentSessionsByMember: View {
    let sessions: [(skillId: String, memberId: String?, timestamp: Date, successRate: Double)]
    let householdMembers: [HouseholdMember]
    let skillNames: [String: String]  // skillId -> name mapping

    @Environment(\.colorScheme) private var colorScheme

    private var sessionsByMember: [String: [(skillId: String, timestamp: Date, successRate: Double)]] {
        var grouped: [String: [(skillId: String, timestamp: Date, successRate: Double)]] = [:]

        for session in sessions {
            let key = session.memberId ?? "unknown"
            grouped[key, default: []].append((session.skillId, session.timestamp, session.successRate))
        }

        return grouped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(sessionsByMember.keys.sorted()), id: \.self) { memberId in
                if let memberSessions = sessionsByMember[memberId] {
                    memberSection(memberId: memberId, sessions: memberSessions)
                }
            }
        }
    }

    @ViewBuilder
    private func memberSection(memberId: String, sessions: [(skillId: String, timestamp: Date, successRate: Double)]) -> some View {
        let member = householdMembers.first { $0.id.uuidString == memberId }

        VStack(alignment: .leading, spacing: 8) {
            // Member header
            HStack(spacing: 8) {
                MemberAvatar(member: member, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(member?.name ?? Strings.Common.unknown)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(sessions.count) " + Strings.Training.sessionsThisWeek)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Recent sessions
            ForEach(Array(sessions.prefix(3).enumerated()), id: \.offset) { _, session in
                sessionRow(session)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    @ViewBuilder
    private func sessionRow(_ session: (skillId: String, timestamp: Date, successRate: Double)) -> some View {
        HStack {
            Text(skillNames[session.skillId] ?? session.skillId)
                .font(.caption)
                .foregroundStyle(.primary)

            Spacer()

            // Success rate indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(session.successRate >= 0.8 ? Color.otisSuccess : (session.successRate >= 0.5 ? Color.otisWarning : Color.otisDanger))
                    .frame(width: 6, height: 6)

                Text(String(format: "%.0f%%", session.successRate * 100))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Text(session.timestamp.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Member Streak Badge

/// Shows member's training streak
struct MemberStreakBadge: View {
    let member: HouseholdMember
    let streakDays: Int
    let isCurrentStreak: Bool

    var body: some View {
        HStack(spacing: 8) {
            MemberAvatar(member: member, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.caption)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(isCurrentStreak ? Color.otisWarning : Color.secondary)

                    Text("\(streakDays)d streak")
                        .font(.caption2)
                        .foregroundStyle(isCurrentStreak ? .primary : .secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

// MARK: - Training Leaderboard

/// Fun leaderboard showing top trainers this week
struct TrainingLeaderboard: View {
    let rankings: [(member: HouseholdMember, sessionCount: Int, streakDays: Int)]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.otisWarning)
                Text(Strings.Training.weeklyLeaderboard)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Rankings
            ForEach(Array(rankings.enumerated()), id: \.element.member.id) { index, ranking in
                leaderboardRow(index: index + 1, ranking: ranking)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
        )
    }

    @ViewBuilder
    private func leaderboardRow(index: Int, ranking: (member: HouseholdMember, sessionCount: Int, streakDays: Int)) -> some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(index)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(index == 1 ? Color.otisWarning : .secondary)
                .frame(width: 20)

            MemberAvatar(member: ranking.member, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(ranking.member.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(ranking.sessionCount) " + Strings.Training.sessions)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Streak
            if ranking.streakDays > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(Color.otisWarning)
                    Text("\(ranking.streakDays)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Member Avatar") {
    let member = HouseholdMember(name: "John", colorHex: "#FF6B6B")
    return VStack(spacing: 16) {
        MemberAvatar(member: member, size: .small)
        MemberAvatar(member: member, size: .medium)
        MemberAvatar(member: member, size: .large)
        MemberAvatar(member: nil, size: .medium)
    }
    .padding()
}

#Preview("Contribution Card") {
    let members = [
        HouseholdMember(id: UUID(), name: "John", colorHex: "#FF6B6B"),
        HouseholdMember(id: UUID(), name: "Sarah", colorHex: "#4ECDC4")
    ]

    return TrainingContributionCard(
        sessionsByMember: [
            members[0].id.uuidString: 15,
            members[1].id.uuidString: 8
        ],
        householdMembers: members,
        totalSessions: 23
    )
    .padding()
}

#Preview("Leaderboard") {
    let members = [
        HouseholdMember(name: "John", colorHex: "#FF6B6B"),
        HouseholdMember(name: "Sarah", colorHex: "#4ECDC4"),
        HouseholdMember(name: "Mike", colorHex: "#45B7D1")
    ]

    return TrainingLeaderboard(
        rankings: [
            (members[0], 12, 5),
            (members[1], 8, 3),
            (members[2], 4, 0)
        ]
    )
    .padding()
}
