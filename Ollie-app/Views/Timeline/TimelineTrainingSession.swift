//
//  TimelineTrainingSession.swift
//  Otis-app
//
//  Extracted training session card from VerticalTimelineView
//  - TrainingSessionCardWithStem: expandable training session card

import SwiftUI
import OtisShared

// MARK: - Training Session Card with Stem

/// Card for grouped training sessions with expand/collapse
struct TrainingSessionCardWithStem: View {
    let session: TrainingSession
    let anchorY: CGFloat
    let cardWidth: CGFloat
    let timeColumnWidth: CGFloat
    let contentWidth: CGFloat
    let isExpanded: Bool
    let onTap: () -> Void
    let onEventTap: (PuppyEvent) -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Icon size
    private let iconSize: CGFloat = 28

    /// Height of collapsed card
    private let collapsedHeight: CGFloat = 28

    /// Height of each expanded event row
    private let expandedRowHeight: CGFloat = 24

    /// X position for card's left edge
    private var cardLeftX: CGFloat {
        timeColumnWidth + contentWidth - cardWidth + 8
    }

    /// X position for icon center (where stem should connect)
    private var iconCenterX: CGFloat {
        cardLeftX + iconSize / 2
    }

    /// X position for anchor dot (just to the left of the icon)
    private var anchorX: CGFloat {
        cardLeftX - 12
    }

    /// Card Y position (centered on anchor when collapsed)
    private var cardY: CGFloat {
        max(anchorY - (collapsedHeight / 2), 0)
    }

    /// Total card height
    private var totalHeight: CGFloat {
        if isExpanded {
            return collapsedHeight + CGFloat(session.events.count) * expandedRowHeight + 8
        }
        return collapsedHeight
    }

    /// Card vertical center (for stem connection)
    private var cardCenterY: CGFloat {
        cardY + iconSize / 2
    }

    private let iconColor: Color = .otisPurple

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Stem line (horizontal from anchor to icon center)
            StemLine(
                anchorX: anchorX,
                anchorY: anchorY,
                cardLeftX: iconCenterX,
                cardCenterY: cardCenterY,
                color: iconColor.opacity(0.3)
            )

            // Anchor dot at true timestamp position
            Circle()
                .fill(iconColor)
                .frame(width: 6, height: 6)
                .offset(x: anchorX - 3, y: anchorY - 3)

            // Training session card
            VStack(alignment: .leading, spacing: 0) {
                // Collapsed header (always visible)
                Button(action: onTap) {
                    HStack(spacing: 0) {
                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(iconColor.opacity(0.15))
                                .frame(width: iconSize, height: iconSize)

                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(iconColor)
                        }

                        // Time and label
                        HStack(spacing: 4) {
                            Text(session.startTime.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Text(Strings.VerticalTimeline.trainingSessionCount(count: session.count))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)

                            // Skill names preview (when collapsed)
                            if !isExpanded && !session.skillNames.isEmpty {
                                Text("· " + session.skillNames.prefix(3).joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Expand/collapse chevron
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 6)
                        .padding(.trailing, 12)
                    }
                    .frame(height: collapsedHeight)
                    .background(
                        Capsule()
                            .fill(cardBackground)
                            .padding(.leading, iconSize / 2)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(iconColor.opacity(0.15), lineWidth: 0.5)
                            .padding(.leading, iconSize / 2)
                    )
                }
                .buttonStyle(.plain)

                // Expanded event list
                if isExpanded {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(session.events) { event in
                            Button {
                                onEventTap(event)
                            } label: {
                                HStack(spacing: 8) {
                                    // Skill name or "Training"
                                    Text(event.exercise ?? Strings.VerticalTimeline.training)
                                        .font(.caption)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    // Time
                                    Text(event.time.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .frame(height: expandedRowHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(iconColor.opacity(0.05))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.leading, iconSize + 6)
                    .padding(.trailing, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                }
            }
            .frame(width: cardWidth)
            .offset(x: cardLeftX, y: cardY)
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.95)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Text("Training session cards are rendered within VerticalTimelineView")
            .foregroundStyle(.secondary)
    }
    .padding()
}
