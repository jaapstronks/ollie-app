//
//  TimelineEventMarker.swift
//  Ollie-app
//
//  Point event marker for the vertical day-planner timeline

import SwiftUI
import OllieShared

/// Point event marker (pee, poo, meals, etc.) for vertical timeline
/// Times are shown on the hour grid, not on individual markers
struct TimelineEventMarker: View {
    let item: VerticalTimelineItem
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Left pin marker
                PinMarker(color: iconColor)

                // Event icon
                EventMarkerIcon(item: item, color: iconColor)

                // Description and details
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let note = item.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Polaroid thumbnail (if photo exists)
                if let thumbnailPath = item.photoThumbnail {
                    PolaroidThumbnail(relativePath: thumbnailPath, size: 32, rotation: 2)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(height: LayoutConstants.timelineEventMarkerHeight)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusS)
                    .fill(cardBackground)
                    .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Colors

    private var iconColor: Color {
        switch item.type {
        case .pointEvent(let event):
            return colorForEvent(event)
        default:
            return .ollieAccent
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.ollieCardDark.opacity(0.9)
            : Color.ollieCardLight
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.3)
            : Color.black.opacity(0.08)
    }

    private var accessibilityLabel: String {
        var parts = [item.startTime.timeString, item.description]
        if let note = item.note, !note.isEmpty {
            parts.append(note)
        }
        return parts.joined(separator: ", ")
    }

    private func colorForEvent(_ event: PuppyEvent) -> Color {
        switch event.type {
        case .plassen, .poepen:
            // Green for outdoor, red for indoor
            if event.location == .buiten {
                return .ollieSuccess
            } else {
                return .ollieDanger
            }
        case .eten, .drinken:
            return .ollieAccent
        case .training:
            return .olliePurple
        case .sociaal:
            return .ollieSuccess
        case .tuin:
            return .ollieSuccess
        case .milestone:
            return .ollieRose
        case .gewicht:
            return .ollieHealth
        case .medicatie:
            return .ollieHealth
        case .coverageGap:
            return .secondary
        default:
            return .secondary
        }
    }
}

// MARK: - Pin Marker

private struct PinMarker: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Event Marker Icon

private struct EventMarkerIcon: View {
    let item: VerticalTimelineItem
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 28, height: 28)

            Image(systemName: item.icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        TimelineEventMarker(
            item: VerticalTimelineItem(
                id: UUID(),
                type: .pointEvent(PuppyEvent(time: Date(), type: .plassen, location: .buiten)),
                startTime: Date(),
                endTime: nil,
                photoThumbnail: nil,
                note: "After breakfast",
                description: "Luna peed outside"
            ),
            onTap: {}
        )

        TimelineEventMarker(
            item: VerticalTimelineItem(
                id: UUID(),
                type: .pointEvent(PuppyEvent(time: Date(), type: .plassen, location: .binnen)),
                startTime: Date(),
                endTime: nil,
                photoThumbnail: nil,
                note: nil,
                description: "Luna had an accident (pee)"
            ),
            onTap: {}
        )

        TimelineEventMarker(
            item: VerticalTimelineItem(
                id: UUID(),
                type: .pointEvent(PuppyEvent(time: Date(), type: .eten)),
                startTime: Date(),
                endTime: nil,
                photoThumbnail: nil,
                note: nil,
                description: "Luna had breakfast"
            ),
            onTap: {}
        )
    }
    .padding()
}
