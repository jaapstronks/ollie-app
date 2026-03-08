//
//  ReusableBadges.swift
//  Otis-app
//
//  Reusable badge and row components to eliminate DRY violations.
//  Consolidates repeated patterns for capsule badges, activity rows, and stat displays.
//

import SwiftUI
import OtisShared

// MARK: - Capsule Badge

/// A reusable capsule-shaped badge for displaying labels, tags, and status indicators.
///
/// Usage:
/// ```swift
/// CapsuleBadge("Week 12", color: .secondary)
/// CapsuleBadge("Active", color: .green, style: .filled)
/// CapsuleBadge("3 days", icon: "clock", color: .blue)
/// ```
struct CapsuleBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = .secondary
    var style: CapsuleBadgeStyle = .subtle

    @Environment(\.colorScheme) private var colorScheme

    /// Initialize with unlabeled text parameter for convenience
    init(_ text: String, icon: String? = nil, color: Color = .secondary, style: CapsuleBadgeStyle = .subtle) {
        self.text = text
        self.icon = icon
        self.color = color
        self.style = style
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        switch style {
        case .subtle:
            return .secondary
        case .tinted:
            return color
        case .filled:
            return .white
        }
    }

    private var backgroundColor: some ShapeStyle {
        switch style {
        case .subtle:
            return Color(.tertiarySystemFill)
        case .tinted:
            return color.opacity(colorScheme == .dark ? 0.2 : 0.1)
        case .filled:
            return color
        }
    }
}

/// Style options for CapsuleBadge
enum CapsuleBadgeStyle {
    /// Neutral gray background
    case subtle
    /// Tinted background matching the color
    case tinted
    /// Solid color background with white text
    case filled
}

// MARK: - Activity Row

/// A reusable row for displaying an activity with icon, text, and optional trailing content.
///
/// Usage:
/// ```swift
/// ActivityRow(icon: "figure.walk", iconColor: .green, text: "30 min walk")
/// ActivityRow(icon: "graduationcap.fill", iconColor: .orange, text: "Training: Sit")
/// ```
struct ActivityRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    var iconSize: CGFloat = 24
    var iconFontSize: CGFloat = 12

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: iconFontSize))
                .foregroundStyle(iconColor)
                .frame(width: iconSize, height: iconSize)
                .background(iconColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()
        }
    }
}

// MARK: - Stat Badge

/// A reusable component for displaying a statistic with icon, value, and label.
///
/// Usage:
/// ```swift
/// StatBadge(value: "12", label: "Walks", icon: "figure.walk", color: .green)
/// StatBadge(value: 45, label: "Events", icon: "list.bullet", color: .blue)
/// ```
struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    init(value: String, label: String, icon: String, color: Color) {
        self.value = value
        self.label = label
        self.icon = icon
        self.color = color
    }

    init(value: Int, label: String, icon: String, color: Color) {
        self.value = "\(value)"
        self.label = label
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat Cell

/// A stat display for grid layouts, similar to StatBadge but optimized for LazyVGrid.
///
/// Usage:
/// ```swift
/// LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
///     StatCell(value: 8, label: "Walks", icon: "figure.walk", color: .green)
///     StatCell(value: 120, label: "Minutes", icon: "timer", color: .blue)
/// }
/// ```
struct StatCell: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Period Badge

/// A badge specifically for displaying time periods (commonly used in cards).
///
/// Usage:
/// ```swift
/// PeriodBadge(text: "This Week")
/// PeriodBadge(text: "Week 12", style: .tinted, color: .blue)
/// ```
struct PeriodBadge: View {
    let text: String
    var style: CapsuleBadgeStyle = .subtle
    var color: Color = .secondary

    var body: some View {
        CapsuleBadge(text, color: color, style: style)
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Applies capsule badge styling to any view
    func capsuleBadgeStyle(color: Color = .secondary, style: CapsuleBadgeStyle = .subtle) -> some View {
        modifier(CapsuleBadgeModifier(color: color, style: style))
    }
}

private struct CapsuleBadgeModifier: ViewModifier {
    let color: Color
    let style: CapsuleBadgeStyle

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        switch style {
        case .subtle: return .secondary
        case .tinted: return color
        case .filled: return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .subtle: return Color(.tertiarySystemFill)
        case .tinted: return color.opacity(colorScheme == .dark ? 0.2 : 0.1)
        case .filled: return color
        }
    }
}

// MARK: - Preview

#Preview("Capsule Badges") {
    VStack(spacing: 16) {
        Text("Subtle Style").font(.headline)
        HStack {
            CapsuleBadge("Week 12")
            CapsuleBadge("3 days", icon: "clock")
            CapsuleBadge("Active")
        }

        Divider()

        Text("Tinted Style").font(.headline)
        HStack {
            CapsuleBadge("Week 12", color: .blue, style: .tinted)
            CapsuleBadge("Active", color: .green, style: .tinted)
            CapsuleBadge("Warning", color: .orange, style: .tinted)
        }

        Divider()

        Text("Filled Style").font(.headline)
        HStack {
            CapsuleBadge("New", color: .blue, style: .filled)
            CapsuleBadge("Pro", color: .purple, style: .filled)
        }
    }
    .padding()
}

#Preview("Activity Rows") {
    VStack(spacing: 12) {
        ActivityRow(icon: "figure.walk", iconColor: .green, text: "30 min walk")
        ActivityRow(icon: "graduationcap.fill", iconColor: .orange, text: "Training: Sit")
        ActivityRow(icon: "dog.fill", iconColor: .purple, text: "Met Luna the Labrador")
        ActivityRow(icon: "camera.fill", iconColor: .pink, text: "Captured a moment")
    }
    .padding()
}

#Preview("Stat Badges") {
    HStack(spacing: 16) {
        StatBadge(value: "45", label: "Events", icon: "list.bullet", color: .blue)
        StatBadge(value: 12, label: "Walks", icon: "figure.walk", color: .green)
        StatBadge(value: 180, label: "Minutes", icon: "timer", color: .orange)
    }
    .padding()
}

#Preview("Stat Cells in Grid") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        StatCell(value: 8, label: "Walks", icon: "figure.walk", color: .green)
        StatCell(value: 120, label: "Walk Minutes", icon: "timer", color: .orange)
        StatCell(value: 4, label: "Training Sessions", icon: "star.fill", color: .yellow)
    }
    .padding()
}
