//
//  TimelinePointEvent.swift
//  Otis-app
//
//  Extracted point event components from VerticalTimelineView
//  - PointEventWithStem: wrapper with stem and anchor dot
//  - StemLine: L-shaped connecting line
//  - PointEventCard: pill-shaped event card

import SwiftUI
import OtisShared

// MARK: - Point Event with Stem

/// Point event with stem line connecting to timeline anchor
struct PointEventWithStem: View {
    let item: VerticalTimelineItem
    let anchorY: CGFloat
    let cardY: CGFloat
    let cardWidth: CGFloat
    let stemAnchorX: CGFloat  // Not used anymore, kept for API compatibility
    let timeColumnWidth: CGFloat
    let contentWidth: CGFloat
    // Note: householdMembers removed - attribution now uses CloudKit record IDs
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Icon size (must match PointEventCard)
    private let iconSize: CGFloat = 28

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

    /// Card vertical center
    private var cardCenterY: CGFloat {
        cardY + iconSize / 2
    }

    private var iconColor: Color {
        switch item.type {
        case .pointEvent(let event):
            return colorForEvent(event)
        default:
            return .otisAccent
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Stem line (horizontal from anchor to icon center)
            StemLine(
                anchorX: anchorX,
                anchorY: anchorY,
                cardLeftX: iconCenterX,  // Connect to icon center, not card edge
                cardCenterY: cardCenterY,
                color: iconColor.opacity(0.3)
            )

            // Anchor dot at true timestamp position
            Circle()
                .fill(iconColor)
                .frame(width: 6, height: 6)
                .offset(x: anchorX - 3, y: anchorY - 3)

            // Event card (right-aligned, pill-shaped)
            PointEventCard(item: item, iconColor: iconColor, onTap: onTap)
                .frame(width: cardWidth, height: iconSize)
                .offset(x: cardLeftX, y: cardY)
        }
    }

    private func colorForEvent(_ event: PuppyEvent) -> Color {
        switch event.type {
        case .plassen, .poepen:
            return event.location == .buiten ? .otisSuccess : .otisDanger
        case .eten, .drinken:
            return .otisAccent
        case .training:
            return .otisPurple
        case .sociaal:
            return .otisSuccess
        case .tuin:
            return .otisSuccess
        case .milestone:
            return .otisRose
        case .gewicht:
            return .otisHealth
        case .medicatie:
            return .otisHealth
        case .coverageGap:
            return .secondary
        default:
            return .secondary
        }
    }
}

// MARK: - Stem Line

/// L-shaped stem connecting anchor point to card
struct StemLine: View {
    let anchorX: CGFloat
    let anchorY: CGFloat
    let cardLeftX: CGFloat
    let cardCenterY: CGFloat
    let color: Color

    var body: some View {
        Path { path in
            // Start at anchor point
            path.move(to: CGPoint(x: anchorX, y: anchorY))

            // If anchor and card are at different Y positions, draw L-shape
            // First go horizontally part way, then vertically, then horizontally to card
            let midX = anchorX + 8  // Small horizontal segment from anchor

            if abs(anchorY - cardCenterY) > 2 {
                // Draw to mid point at anchor height
                path.addLine(to: CGPoint(x: midX, y: anchorY))
                // Draw vertically to card height
                path.addLine(to: CGPoint(x: midX, y: cardCenterY))
            }

            // Draw horizontally to card
            path.addLine(to: CGPoint(x: cardLeftX, y: cardCenterY))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Point Event Card

/// Pill-shaped card with icon overlapping left edge
/// Height matches icon size (28pt) for compact stacking
/// Shows thumbnail on the right when event has a photo
struct PointEventCard: View {
    let item: VerticalTimelineItem
    let iconColor: Color
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Icon size matches card height for perfect circle overlap
    private let iconSize: CGFloat = 28

    /// Whether this event has a photo to display
    private var hasPhoto: Bool {
        item.photoThumbnail != nil
    }

    /// Get the CloudKit record ID of who logged this event
    private var loggedByRecordID: String? {
        guard case .pointEvent(let event) = item.type else { return nil }
        return event.loggedBy
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Icon circle (overlaps the left edge of the pill)
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: iconSize, height: iconSize)

                    Image(systemName: item.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                // Time and label on same line
                HStack(spacing: 4) {
                    Text(item.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(shortDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    // Attribution avatar (only shown when event was logged by someone else)
                    if let recordID = loggedByRecordID,
                       !UserIdentityStore.shared.isCurrentUser(recordID) {
                        UserAvatarFromRecordID(cloudKitRecordID: recordID, size: 14)
                    }
                }
                .padding(.leading, 6)
                .padding(.trailing, hasPhoto ? 4 : 12)

                // Photo thumbnail (if available)
                if let thumbnailPath = item.photoThumbnail {
                    AsyncThumbnailView(relativePath: thumbnailPath, showErrorPlaceholder: false)
                        .frame(width: iconSize - 4, height: iconSize - 4)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(.trailing, 4)
                }
            }
            .frame(height: iconSize)
            .background(
                // Pill background that starts where icon ends
                Capsule()
                    .fill(cardBackground)
                    .padding(.leading, iconSize / 2)  // Start pill from icon center
            )
            .overlay(
                // Subtle border on pill portion
                Capsule()
                    .strokeBorder(iconColor.opacity(0.15), lineWidth: 0.5)
                    .padding(.leading, iconSize / 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var shortDescription: String {
        switch item.type {
        case .pointEvent(let event):
            switch event.type {
            case .plassen:
                return event.location == .buiten ? Strings.VerticalTimeline.pee : Strings.VerticalTimeline.accident
            case .poepen:
                return event.location == .buiten ? Strings.VerticalTimeline.poop : Strings.VerticalTimeline.accident
            case .eten:
                return Strings.VerticalTimeline.meal
            case .drinken:
                return Strings.VerticalTimeline.water
            case .training:
                return event.exercise ?? Strings.VerticalTimeline.training
            case .sociaal:
                return event.who ?? Strings.VerticalTimeline.social
            case .gewicht:
                if let kg = event.weightKg {
                    return String(format: "%.1f kg", kg)
                }
                return Strings.VerticalTimeline.weighed
            case .medicatie:
                return Strings.VerticalTimeline.medication
            default:
                return event.type.label
            }
        default:
            return item.description
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
        Text("Point events are rendered within VerticalTimelineView")
            .foregroundStyle(.secondary)
    }
    .padding()
}
