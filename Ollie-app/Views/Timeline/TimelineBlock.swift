//
//  TimelineBlock.swift
//  Ollie-app
//
//  Duration block for sleep sessions and walks in vertical timeline

import SwiftUI
import OllieShared

/// Duration block view for sleep sessions and walks
/// Height is calculated externally based on grid position
struct TimelineBlock: View {
    let item: VerticalTimelineItem
    let height: CGFloat
    let isWalkTrack: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var blockColor: Color {
        switch item.type {
        case .sleepSession:
            return .ollieSleep
        case .walkEvent:
            return .ollieSuccess
        case .pointEvent:
            return .secondary
        case .appointmentItem:
            return .ollieAccent
        }
    }

    /// Walk blocks use reduced opacity
    private var backgroundOpacity: Double {
        isWalkTrack ? 0.08 : 0.1
    }

    private var borderOpacity: Double {
        isWalkTrack ? 0.2 : 0.3
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Header: Icon + Title + Duration pill
                HStack(spacing: 8) {
                    BlockIcon(item: item, color: blockColor)

                    HStack(spacing: 6) {
                        Text(blockTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if item.isOngoing {
                            LiveDurationPill(startTime: item.startTime, color: blockColor)
                        } else if let duration = item.durationString {
                            DurationPill(text: duration, color: blockColor, isHighlighted: true)
                        }
                    }

                    Spacer()

                    // Polaroid thumbnail (if photo exists)
                    if let thumbnailPath = item.photoThumbnail {
                        PolaroidThumbnail(relativePath: thumbnailPath, size: 36, rotation: 3)
                    }
                }

                // Description
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Note (if present)
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                // Walk details (spot name)
                if case .walkEvent(let event) = item.type {
                    WalkBlockDetails(event: event)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                    .fill(blockColor.opacity(backgroundOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                            .strokeBorder(blockColor.opacity(borderOpacity), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var blockTitle: String {
        switch item.type {
        case .sleepSession:
            return Strings.VerticalTimeline.sleep
        case .walkEvent:
            return Strings.VerticalTimeline.walk
        case .pointEvent, .appointmentItem:
            return ""
        }
    }

    private var accessibilityLabel: String {
        var parts = [blockTitle, item.description]
        if let duration = item.durationString {
            parts.append(duration)
        }
        if let note = item.note, !note.isEmpty {
            parts.append(note)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Block Icon

private struct BlockIcon: View {
    let item: VerticalTimelineItem
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)

            Image(systemName: item.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Walk Block Details

private struct WalkBlockDetails: View {
    let event: PuppyEvent

    var body: some View {
        HStack(spacing: 12) {
            // Spot name
            if let spotName = event.spotName {
                Label(spotName, systemImage: "mappin.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.ollieAccent)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TimelineBlock(
            item: VerticalTimelineItem(
                id: UUID(),
                type: .sleepSession(SleepSession(
                    id: UUID(),
                    startTime: Date().addingTimeInterval(-3600),
                    endTime: Date(),
                    startEventId: UUID(),
                    endEventId: UUID()
                )),
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date(),
                photoThumbnail: nil,
                note: "Slept on the couch",
                description: "Luna took a nap"
            ),
            height: 80,
            isWalkTrack: false,
            onTap: {}
        )

        TimelineBlock(
            item: VerticalTimelineItem(
                id: UUID(),
                type: .walkEvent(PuppyEvent(
                    time: Date().addingTimeInterval(-7200),
                    type: .uitlaten,
                    durationMin: 25,
                    spotName: "Park"
                )),
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-5700),
                photoThumbnail: nil,
                note: "Morning walk",
                description: "Luna went for a walk",
                track: .walk
            ),
            height: 70,
            isWalkTrack: true,
            onTap: {}
        )
    }
    .padding()
}
