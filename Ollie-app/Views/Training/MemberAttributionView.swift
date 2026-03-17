//
//  MemberAttributionView.swift
//  Ollie-app
//
//  Components for displaying training session attribution.
//  Uses CloudKit-based identity (UserIdentityStore) and ParticipantResolver for names.
//

import SwiftUI
import OtisShared

// MARK: - Training Contribution Card

/// Shows training contributions by user (using CloudKit record IDs)
struct TrainingContributionCard: View {
    /// Session counts keyed by CloudKit record ID
    let sessionsByRecordID: [String: Int]
    let totalSessions: Int

    @Environment(\.colorScheme) private var colorScheme

    private var sortedContributions: [(recordID: String, count: Int, percentage: Double, isCurrentUser: Bool)] {
        var contributions: [(recordID: String, count: Int, percentage: Double, isCurrentUser: Bool)] = []

        for (recordID, count) in sessionsByRecordID.sorted(by: { $0.value > $1.value }) {
            let percentage = totalSessions > 0 ? Double(count) / Double(totalSessions) : 0
            let isCurrentUser = UserIdentityStore.shared.isCurrentUser(recordID)
            contributions.append((recordID, count, percentage, isCurrentUser))
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
            ForEach(sortedContributions, id: \.recordID) { contribution in
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
    private func contributionRow(_ contribution: (recordID: String, count: Int, percentage: Double, isCurrentUser: Bool)) -> some View {
        HStack(spacing: 10) {
            UserAvatarFromRecordID(cloudKitRecordID: contribution.recordID, size: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName(for: contribution))
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
                            .fill(contribution.isCurrentUser ? Color.accentColor : Color.secondary)
                            .frame(width: geo.size.width * contribution.percentage, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private func displayName(for contribution: (recordID: String, count: Int, percentage: Double, isCurrentUser: Bool)) -> String {
        if contribution.isCurrentUser {
            return UserIdentityStore.shared.currentIdentity?.name ?? Strings.UserProfile.me
        }
        return ParticipantResolver.shared.resolve(cloudKitRecordID: contribution.recordID).displayName
    }
}

// MARK: - Session Attribution Label

/// Inline label showing who logged a training session
struct SessionAttributionLabel: View {
    let cloudKitRecordID: String?
    let timestamp: Date
    let showName: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(cloudKitRecordID: String?, timestamp: Date, showName: Bool = true) {
        self.cloudKitRecordID = cloudKitRecordID
        self.timestamp = timestamp
        self.showName = showName
    }

    private var isCurrentUser: Bool {
        guard let recordID = cloudKitRecordID else { return false }
        return UserIdentityStore.shared.isCurrentUser(recordID)
    }

    private var displayName: String {
        if isCurrentUser {
            return UserIdentityStore.shared.currentIdentity?.name ?? Strings.UserProfile.me
        }
        guard let recordID = cloudKitRecordID else { return Strings.Handoff.partner }
        return ParticipantResolver.shared.resolve(cloudKitRecordID: recordID).displayName
    }

    var body: some View {
        HStack(spacing: 6) {
            UserAvatarFromRecordID(cloudKitRecordID: cloudKitRecordID, size: 24)

            if showName, cloudKitRecordID != nil {
                Text(displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(timestamp.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Recent Sessions by User

/// Shows recent training sessions grouped by user
struct RecentSessionsByUser: View {
    let sessions: [(skillId: String, recordID: String?, timestamp: Date, successRate: Double)]
    let skillNames: [String: String]  // skillId -> name mapping

    @Environment(\.colorScheme) private var colorScheme

    private var sessionsByRecordID: [String: [(skillId: String, timestamp: Date, successRate: Double)]] {
        var grouped: [String: [(skillId: String, timestamp: Date, successRate: Double)]] = [:]

        for session in sessions {
            let key = session.recordID ?? "unknown"
            grouped[key, default: []].append((session.skillId, session.timestamp, session.successRate))
        }

        return grouped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(sessionsByRecordID.keys.sorted()), id: \.self) { recordID in
                if let userSessions = sessionsByRecordID[recordID] {
                    userSection(recordID: recordID, sessions: userSessions)
                }
            }
        }
    }

    @ViewBuilder
    private func userSection(recordID: String, sessions: [(skillId: String, timestamp: Date, successRate: Double)]) -> some View {
        let isCurrentUser = UserIdentityStore.shared.isCurrentUser(recordID)
        let displayName = isCurrentUser
            ? (UserIdentityStore.shared.currentIdentity?.name ?? Strings.UserProfile.me)
            : ParticipantResolver.shared.resolve(cloudKitRecordID: recordID).displayName

        VStack(alignment: .leading, spacing: 8) {
            // User header
            HStack(spacing: 8) {
                UserAvatarFromRecordID(cloudKitRecordID: recordID, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
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

// MARK: - User Streak Badge

/// Shows a user's training streak
struct UserStreakBadge: View {
    let cloudKitRecordID: String
    let streakDays: Int
    let isCurrentStreak: Bool

    private var isCurrentUser: Bool {
        UserIdentityStore.shared.isCurrentUser(cloudKitRecordID)
    }

    private var displayName: String {
        if isCurrentUser {
            return UserIdentityStore.shared.currentIdentity?.name ?? Strings.UserProfile.me
        }
        return ParticipantResolver.shared.resolve(cloudKitRecordID: cloudKitRecordID).displayName
    }

    var body: some View {
        HStack(spacing: 8) {
            UserAvatarFromRecordID(cloudKitRecordID: cloudKitRecordID, size: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
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
    let rankings: [(recordID: String, sessionCount: Int, streakDays: Int)]

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
            ForEach(Array(rankings.enumerated()), id: \.element.recordID) { index, ranking in
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
    private func leaderboardRow(index: Int, ranking: (recordID: String, sessionCount: Int, streakDays: Int)) -> some View {
        let isCurrentUser = UserIdentityStore.shared.isCurrentUser(ranking.recordID)
        let displayName = isCurrentUser
            ? (UserIdentityStore.shared.currentIdentity?.name ?? Strings.UserProfile.me)
            : ParticipantResolver.shared.resolve(cloudKitRecordID: ranking.recordID).displayName

        HStack(spacing: 12) {
            // Rank
            Text("\(index)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(index == 1 ? Color.otisWarning : .secondary)
                .frame(width: 20)

            UserAvatarFromRecordID(cloudKitRecordID: ranking.recordID, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
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

#Preview("Contribution Card") {
    TrainingContributionCard(
        sessionsByRecordID: [
            "user-1": 15,
            "user-2": 8
        ],
        totalSessions: 23
    )
    .padding()
}

#Preview("Session Attribution") {
    VStack(spacing: 16) {
        SessionAttributionLabel(
            cloudKitRecordID: "user-1",
            timestamp: Date().addingTimeInterval(-3600)
        )

        SessionAttributionLabel(
            cloudKitRecordID: nil,
            timestamp: Date().addingTimeInterval(-7200)
        )
    }
    .padding()
}

#Preview("Leaderboard") {
    TrainingLeaderboard(
        rankings: [
            ("user-1", 12, 5),
            ("user-2", 8, 3),
            ("user-3", 4, 0)
        ]
    )
    .padding()
}
