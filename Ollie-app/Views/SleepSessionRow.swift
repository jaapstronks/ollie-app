//
//  SleepSessionRow.swift
//  Ollie-app
//
//  Timeline row for displaying sleep sessions with live timer for ongoing sleep

import SwiftUI

/// Row displaying a sleep session in the timeline
struct SleepSessionRow: View {
    let session: SleepSession
    let onEditStart: () -> Void
    let onEditEnd: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time display
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.startTime.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let endTime = session.endTime {
                    Text(endTime.timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 44, alignment: .trailing)

            // Sleep icon
            EventIcon(type: .slapen, size: 28)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                if session.isOngoing {
                    ongoingContent
                } else {
                    completedContent
                }
            }

            Spacer()

            // Duration pill
            durationPill
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Ongoing Sleep Content

    @ViewBuilder
    private var ongoingContent: some View {
        HStack(spacing: 6) {
            Text(Strings.SleepSession.sleeping)
                .font(.body)
                .fontWeight(.medium)
        }

        // Live timer using TimelineView for updates
        SwiftUI.TimelineView(.periodic(from: Date(), by: 60)) { _ in
            Text(Strings.SleepStatus.started(time: session.startTime.timeString))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Completed Sleep Content

    @ViewBuilder
    private var completedContent: some View {
        HStack(spacing: 6) {
            Text(Strings.SleepSession.nap)
                .font(.body)
                .fontWeight(.medium)

            if session.isShortNap {
                Text("(\(Strings.SleepSession.shortNap))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }

        Text("\(session.startTime.timeString) \u{2192} \(session.endTime?.timeString ?? "")")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    // MARK: - Duration Pill

    @ViewBuilder
    private var durationPill: some View {
        if session.isOngoing {
            // Live updating duration for ongoing sleep
            SwiftUI.TimelineView(.periodic(from: Date(), by: 60)) { _ in
                Text(formatLiveDuration())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.15))
                    .clipShape(Capsule())
            }
        } else {
            Text(session.durationString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())
        }
    }

    // MARK: - Helpers

    private func formatLiveDuration() -> String {
        let minutes = Date().minutesSince(session.startTime)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h\(mins)m"
        }
    }

    private var accessibilityLabel: String {
        if session.isOngoing {
            return "\(Strings.SleepSession.sleeping), \(Strings.SleepStatus.started(time: session.startTime.timeString)), \(formatLiveDuration())"
        } else {
            return "\(Strings.SleepSession.nap), \(session.startTime.timeString) to \(session.endTime?.timeString ?? ""), \(session.durationString)"
        }
    }
}

// MARK: - Preview

#Preview("Ongoing Sleep") {
    List {
        SleepSessionRow(
            session: SleepSession(
                id: UUID(),
                startTime: Date().addingTimeInterval(-45 * 60),
                endTime: nil,
                startEventId: UUID(),
                endEventId: nil
            ),
            onEditStart: {},
            onEditEnd: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
    }
    .listStyle(.plain)
}

#Preview("Completed Nap") {
    List {
        SleepSessionRow(
            session: SleepSession(
                id: UUID(),
                startTime: Date().addingTimeInterval(-90 * 60),
                endTime: Date().addingTimeInterval(-30 * 60),
                startEventId: UUID(),
                endEventId: UUID()
            ),
            onEditStart: {},
            onEditEnd: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
    }
    .listStyle(.plain)
}

#Preview("Short Nap") {
    List {
        SleepSessionRow(
            session: SleepSession(
                id: UUID(),
                startTime: Date().addingTimeInterval(-20 * 60),
                endTime: Date().addingTimeInterval(-10 * 60),
                startEventId: UUID(),
                endEventId: UUID()
            ),
            onEditStart: {},
            onEditEnd: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
    }
    .listStyle(.plain)
}
