//
//  TimelineBlock.swift
//  Otis-app
//
//  Duration block for sleep sessions and walks in vertical timeline

import SwiftUI
import OtisShared

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
            return .otisSleep
        case .walkEvent:
            return .otisSuccess
        case .pointEvent:
            return .secondary
        case .appointmentItem:
            return .otisAccent
        case .trainingSession:
            return .otisPurple
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
            HStack(spacing: 6) {
                // Icon
                BlockIcon(item: item, color: blockColor)

                // Title (just "Nap" or "Walk")
                Text(blockTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                // Duration pill
                if item.isOngoing {
                    LiveDurationPill(startTime: item.startTime, color: blockColor)
                } else if let duration = item.durationString {
                    DurationPill(text: duration, color: blockColor, isHighlighted: true)
                }

                // Polaroid thumbnail (if photo exists)
                if let thumbnailPath = item.photoThumbnail {
                    PolaroidThumbnail(relativePath: thumbnailPath, size: 28, rotation: 2)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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
            return Strings.VerticalTimeline.sleep  // Localized as "Nap"
        case .walkEvent:
            return Strings.VerticalTimeline.walk
        case .trainingSession:
            return Strings.VerticalTimeline.training
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
                .frame(width: 26, height: 26)

            Image(systemName: item.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
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
