//
//  SheetHeader.swift
//  Ollie-app
//
//  Reusable header component for sheets with consistent styling
//

import SwiftUI
import OllieShared

// MARK: - Sheet Header Icon

/// Icon configuration for sheet headers
enum SheetHeaderIcon {
    /// Standard event type icon
    case eventType(EventType)

    /// Combined icons (e.g., pee + poop for potty sheet)
    case combined(
        primary: String,
        secondary: String,
        primaryColor: Color,
        secondaryColor: Color
    )

    /// Custom system icon with color
    case custom(systemName: String, color: Color)

    /// Training skill icon
    case skill(Skill)
}

// MARK: - Sheet Header

/// Reusable header for log sheets with icon and title
struct SheetHeader: View {
    let title: String
    let icon: SheetHeaderIcon
    var subtitle: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 8)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .eventType(let eventType):
            EventIcon(type: eventType, size: 36)

        case .combined(let primary, let secondary, let primaryColor, let secondaryColor):
            HStack(spacing: 4) {
                Image(systemName: primary)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(primaryColor)
                Image(systemName: secondary)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(secondaryColor)
            }
            .frame(width: 44, height: 44)
            .background(primaryColor.opacity(0.1))
            .clipShape(Circle())
            .accessibilityHidden(true)

        case .custom(let systemName, let color):
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .accessibilityHidden(true)

        case .skill(let skill):
            ZStack {
                Circle()
                    .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: skill.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.ollieAccent)
            }
        }
    }
}

// MARK: - Sheet Header Card

/// Sheet header displayed as a card (for more prominent display like training sheets)
struct SheetHeaderCard: View {
    let title: String
    let icon: SheetHeaderIcon
    var subtitle: String?
    var tintColor: Color = .ollieAccent

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassStatusCard(tintColor: tintColor)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .eventType(let eventType):
            ZStack {
                Circle()
                    .fill(eventType.iconColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 56, height: 56)

                EventIcon(type: eventType, size: 24)
            }

        case .combined(let primary, let secondary, let primaryColor, let secondaryColor):
            ZStack {
                Circle()
                    .fill(primaryColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 56, height: 56)

                HStack(spacing: 4) {
                    Image(systemName: primary)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(primaryColor)
                    Image(systemName: secondary)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                }
            }

        case .custom(let systemName, let color):
            ZStack {
                Circle()
                    .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
            }

        case .skill(let skill):
            ZStack {
                Circle()
                    .fill(tintColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(tintColor)
            }
        }
    }
}

// MARK: - Previews

#Preview("Event Type Header") {
    VStack(spacing: 20) {
        SheetHeader(
            title: "Eat",
            icon: .eventType(.eten)
        )

        SheetHeader(
            title: "Walk",
            icon: .eventType(.uitlaten),
            subtitle: "Morning walk"
        )
    }
    .padding()
}

#Preview("Combined Icon Header") {
    SheetHeader(
        title: "Toilet",
        icon: .combined(
            primary: "drop.fill",
            secondary: "circle.inset.filled",
            primaryColor: .ollieInfo,
            secondaryColor: .ollieWarning
        )
    )
    .padding()
}

#Preview("Custom Icon Header") {
    SheetHeader(
        title: "Weight",
        icon: .custom(systemName: "scalemass.fill", color: .purple)
    )
    .padding()
}

#Preview("Header Card") {
    let previewSkill = Skill(
        id: "sit",
        icon: "arrow.down.to.line",
        category: .basicCommands,
        week: 2,
        priority: 1,
        requires: ["luring"]
    )
    return SheetHeaderCard(
        title: "Sit",
        icon: .skill(previewSkill),
        subtitle: "Basic Commands"
    )
    .padding()
}
