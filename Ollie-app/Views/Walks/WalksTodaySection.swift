//
//  WalksTodaySection.swift
//  Ollie-app
//
//  Today's walks section with suggestions
//

import SwiftUI
import OllieShared

/// Today's walks section showing completed walks and next suggestion
struct WalksTodaySection: View {
    let todaysWalks: [PuppyEvent]
    let walkSuggestion: WalkSuggestion?
    let totalWalkMinutes: Int
    let onQuickLog: () -> Void
    let onEditWalk: (PuppyEvent) -> Void
    let onDeleteWalk: (PuppyEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.WalksTab.todaysWalks,
                icon: "figure.walk",
                tint: .ollieAccent
            )

            if todaysWalks.isEmpty {
                emptyState
            } else {
                walkSummaryCard
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            // Show next suggested walk time
            if let suggestion = walkSuggestion {
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title2)
                        .foregroundStyle(Color.ollieAccent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Walks.nextWalk)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(Strings.Walks.nextWalkSuggestion(time: suggestion.timeString))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Progress indicator
                    Text(Strings.Walks.walksProgress(
                        completed: suggestion.walksCompletedToday,
                        total: suggestion.targetWalksPerDay
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.ollieAccent.opacity(0.1))
                .cornerRadius(10)
            }

            Text(Strings.WalksTab.noWalksToday)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                HapticFeedback.light()
                onQuickLog()
            } label: {
                Label(Strings.WalksTab.startWalk, systemImage: "plus")
            }
            .buttonStyle(.glassPill(tint: .accent))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard(tint: .accent)
    }

    // MARK: - Walk Summary Card

    @ViewBuilder
    private var walkSummaryCard: some View {
        VStack(spacing: 12) {
            // Header with progress
            HStack {
                // Walk count and progress
                VStack(alignment: .leading, spacing: 4) {
                    if let suggestion = walkSuggestion {
                        Text(Strings.Walks.walksProgress(
                            completed: suggestion.walksCompletedToday,
                            total: suggestion.targetWalksPerDay
                        ))
                        .font(.headline)
                    } else {
                        Text(Strings.WalksTab.walksCount(todaysWalks.count))
                            .font(.headline)
                    }

                    if totalWalkMinutes > 0 {
                        Text(Strings.WalksTab.totalDuration(totalWalkMinutes))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Progress ring
                if let suggestion = walkSuggestion {
                    ZStack {
                        Circle()
                            .stroke(Color.ollieAccent.opacity(0.2), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: CGFloat(suggestion.walksCompletedToday) / CGFloat(suggestion.targetWalksPerDay))
                            .stroke(Color.ollieAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(Color.ollieAccent)
                    }
                    .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "figure.walk")
                        .font(.title)
                        .foregroundStyle(Color.ollieAccent)
                }
            }

            // Next walk suggestion (if not all done)
            if let suggestion = walkSuggestion {
                Divider()
                nextWalkSuggestionRow(suggestion)
            }

            // List of today's walks
            if !todaysWalks.isEmpty {
                Divider()

                ForEach(todaysWalks) { walk in
                    WalkRowView(walk: walk)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEditWalk(walk)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDeleteWalk(walk)
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding()
        .glassCard(tint: .accent)
    }

    @ViewBuilder
    private func nextWalkSuggestionRow(_ suggestion: WalkSuggestion) -> some View {
        HStack(spacing: 8) {
            Image(systemName: suggestion.isOverdue ? "exclamationmark.circle.fill" : "arrow.right.circle")
                .font(.caption)
                .foregroundStyle(suggestion.isOverdue ? .orange : Color.ollieAccent)

            Text(Strings.Walks.nextWalk)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(suggestion.timeString)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(suggestion.isOverdue ? .orange : .primary)

            if suggestion.isOverdue {
                Text("(\(Strings.Upcoming.overdue))")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Spacer()

            // Quick log button
            Button {
                HapticFeedback.light()
                onQuickLog()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.ollieAccent)
            }
        }
        .padding(8)
        .background(suggestion.isOverdue ? Color.orange.opacity(0.1) : Color.ollieAccent.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Walk Row View

struct WalkRowView: View {
    let walk: PuppyEvent

    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(walk.time, format: .dateTime.hour().minute())
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(width: 50, alignment: .leading)

            // Duration (if available)
            if let duration = walk.durationMin {
                Text("\(duration) \(Strings.Common.minutes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Spot name (if available)
            if let spotName = walk.spotName {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                    Text(spotName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Note indicator
            if let note = walk.note, !note.isEmpty {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Chevron to indicate tappable
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
