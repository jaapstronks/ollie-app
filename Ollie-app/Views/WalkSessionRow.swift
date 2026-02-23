//
//  WalkSessionRow.swift
//  Ollie-app
//
//  Timeline row for displaying walk sessions as a card container with nested potty events

import SwiftUI

/// Card-style row displaying a walk session with nested child events
struct WalkSessionRow: View {
    let session: WalkSession
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Walk header
            walkHeader

            // Child events (potty/moments during walk)
            if !session.childPottyEvents.isEmpty {
                Divider()
                    .padding(.leading, 56)

                childEventsSection
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.ollieSuccess.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Walk Header

    @ViewBuilder
    private var walkHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time display
            Text(session.startTime.timeString)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .trailing)

            // Walk icon with green accent
            ZStack {
                Circle()
                    .fill(Color.ollieSuccess.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: "figure.walk")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.ollieSuccess)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(Strings.WalkSession.walk)
                        .font(.body)
                        .fontWeight(.semibold)

                    // Duration pill
                    if let durationString = session.durationString {
                        Text(durationString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.ollieSuccess)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.ollieSuccess.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                // Spot name
                if let spotName = session.spotName {
                    Label(spotName, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ollieAccent)
                }

                // Note
                if let note = session.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Child Events Section

    @ViewBuilder
    private var childEventsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(session.childPottyEvents) { event in
                childEventRow(event)

                if event.id != session.childPottyEvents.last?.id {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
    }

    @ViewBuilder
    private func childEventRow(_ event: PuppyEvent) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Indented time (empty space to align with parent)
            Text(event.time.timeString)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .trailing)

            // Small icon
            childEventIcon(for: event.type)

            // Label
            Text(event.type.label)
                .font(.subheadline)
                .foregroundColor(.primary)

            if let location = event.location {
                Text("(\(location.label.lowercased()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.5))
    }

    @ViewBuilder
    private func childEventIcon(for type: EventType) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case .plassen:
                return ("drop.fill", .ollieInfo)
            case .poepen:
                return ("circle.inset.filled", .ollieWarning)
            default:
                return (type.icon, .secondary)
            }
        }()

        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 24, height: 24)

            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(.secondarySystemBackground)
            } else {
                Color(.secondarySystemBackground).opacity(0.6)
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts = [
            Strings.WalkSession.walk,
            session.startTime.timeString
        ]

        if session.didPee {
            parts.append(Strings.WalkSession.peed)
        }
        if session.didPoop {
            parts.append(Strings.WalkSession.pooped)
        }

        if let spotName = session.spotName {
            parts.append("at \(spotName)")
        }

        if let duration = session.durationString {
            parts.append(duration)
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("Walk with pee and poop") {
    List {
        WalkSessionRow(
            session: WalkSession(
                id: UUID(),
                walkEvent: PuppyEvent(
                    time: Date().addingTimeInterval(-60 * 60),
                    type: .uitlaten,
                    note: "Morning walk",
                    durationMin: 30,
                    spotName: "Vondelpark"
                ),
                childPottyEvents: [
                    PuppyEvent(time: Date().addingTimeInterval(-45 * 60), type: .plassen, location: .buiten),
                    PuppyEvent(time: Date().addingTimeInterval(-40 * 60), type: .poepen, location: .buiten)
                ]
            ),
            onEdit: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
}

#Preview("Walk with pee only") {
    List {
        WalkSessionRow(
            session: WalkSession(
                id: UUID(),
                walkEvent: PuppyEvent(
                    time: Date().addingTimeInterval(-2 * 60 * 60),
                    type: .uitlaten,
                    durationMin: 15
                ),
                childPottyEvents: [
                    PuppyEvent(time: Date().addingTimeInterval(-2 * 60 * 60 + 7 * 60), type: .plassen, location: .buiten)
                ]
            ),
            onEdit: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
}

#Preview("Walk without potty") {
    List {
        WalkSessionRow(
            session: WalkSession(
                id: UUID(),
                walkEvent: PuppyEvent(
                    time: Date().addingTimeInterval(-3 * 60 * 60),
                    type: .uitlaten,
                    note: "Quick walk around the block",
                    durationMin: 10
                ),
                childPottyEvents: []
            ),
            onEdit: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
}

#Preview("Multiple walks in list") {
    List {
        WalkSessionRow(
            session: WalkSession(
                id: UUID(),
                walkEvent: PuppyEvent(
                    time: Date().addingTimeInterval(-3 * 60 * 60),
                    type: .uitlaten,
                    note: "Morning walk",
                    durationMin: 25,
                    spotName: "Park"
                ),
                childPottyEvents: [
                    PuppyEvent(time: Date().addingTimeInterval(-2.5 * 60 * 60), type: .plassen, location: .buiten),
                    PuppyEvent(time: Date().addingTimeInterval(-2.3 * 60 * 60), type: .poepen, location: .buiten)
                ]
            ),
            onEdit: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)

        WalkSessionRow(
            session: WalkSession(
                id: UUID(),
                walkEvent: PuppyEvent(
                    time: Date().addingTimeInterval(-1 * 60 * 60),
                    type: .uitlaten,
                    durationMin: 10
                ),
                childPottyEvents: []
            ),
            onEdit: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
}
