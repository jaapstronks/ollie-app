//
//  SleepSessionRow.swift
//  Ollie-app
//
//  Timeline row for displaying sleep sessions with live timer for ongoing sleep

import SwiftUI

/// Row displaying a sleep session in the timeline
/// Shows start → end time as a single unified event
struct SleepSessionRow: View {
    let session: SleepSession
    var note: String?
    let onEditStart: () -> Void
    let onEditEnd: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time display - shows start and end stacked
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.startTime.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let endTime = session.endTime {
                    Text(endTime.timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    // Ongoing indicator
                    Text("...")
                        .font(.caption)
                        .foregroundColor(.ollieSleep)
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

                // Note (if any)
                if let note = note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
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
        .accessibilityIdentifier("SLEEP_SESSION_ROW")
    }

    // MARK: - Ongoing Sleep Content

    @ViewBuilder
    private var ongoingContent: some View {
        HStack(spacing: 6) {
            Text(Strings.SleepSession.sleeping)
                .font(.body)
                .fontWeight(.medium)

            // Pulsing dot indicator
            Circle()
                .fill(Color.ollieSleep)
                .frame(width: 8, height: 8)
                .modifier(PulsingAnimation())
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
                    .foregroundColor(.ollieSleep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ollieSleep.opacity(0.15))
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
        var parts: [String] = []

        if session.isOngoing {
            parts.append(Strings.SleepSession.sleeping)
            parts.append(Strings.SleepStatus.started(time: session.startTime.timeString))
            parts.append(formatLiveDuration())
        } else {
            parts.append(Strings.SleepSession.nap)
            parts.append("\(session.startTime.timeString) to \(session.endTime?.timeString ?? "")")
            parts.append(session.durationString)
        }

        if let note = note, !note.isEmpty {
            parts.append(note)
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Pulsing Animation

private struct PulsingAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
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
            note: nil,
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
            note: "After lunch nap",
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
            note: nil,
            onEditStart: {},
            onEditEnd: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
    }
    .listStyle(.plain)
}
