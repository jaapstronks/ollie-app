//
//  InfoListRow.swift
//  Otis-app
//
//  Reusable list row component for tips, principles, and info items.
//  Consolidates duplicated principleRow, tipRow, mistakeRow patterns.
//

import SwiftUI

/// Style presets for info list rows
enum InfoListRowStyle {
    case tip       // Green checkmark - positive/recommended
    case principle // Accent color icon - key points
    case warning   // Orange/warning icon - mistakes to avoid
    case info      // Secondary icon - neutral information

    var defaultIcon: String {
        switch self {
        case .tip: return "checkmark.circle.fill"
        case .principle: return "lightbulb.fill"
        case .warning: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .tip: return .otisSuccess
        case .principle: return .otisAccent
        case .warning: return .otisWarning
        case .info: return .secondary
        }
    }
}

/// A reusable row for displaying tips, principles, or info items
struct InfoListRow: View {
    let text: String
    var icon: String? = nil
    var style: InfoListRowStyle = .info
    var iconColor: Color? = nil

    private var resolvedIcon: String {
        icon ?? style.defaultIcon
    }

    private var resolvedColor: Color {
        iconColor ?? style.iconColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: resolvedIcon)
                .font(.caption)
                .foregroundStyle(resolvedColor)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

/// Convenience initializers for common styles
extension InfoListRow {
    /// Creates a tip row (green checkmark)
    static func tip(_ text: String) -> InfoListRow {
        InfoListRow(text: text, style: .tip)
    }

    /// Creates a principle row (accent color icon)
    static func principle(_ text: String, icon: String = "lightbulb.fill") -> InfoListRow {
        InfoListRow(text: text, icon: icon, style: .principle)
    }

    /// Creates a warning/mistake row (orange X)
    static func warning(_ text: String) -> InfoListRow {
        InfoListRow(text: text, style: .warning)
    }

    /// Creates an info row with custom icon
    static func info(_ text: String, icon: String) -> InfoListRow {
        InfoListRow(text: text, icon: icon, style: .info)
    }
}

// MARK: - Preview

#Preview("Info List Rows") {
    VStack(spacing: 12) {
        Text("Tips").font(.headline)
        InfoListRow.tip("Take out after waking, eating, and playing")
        InfoListRow.tip("Reward immediately when they go outside")

        Divider()

        Text("Principles").font(.headline)
        InfoListRow.principle("Supervise constantly indoors", icon: "eye.fill")
        InfoListRow.principle("Never punish accidents", icon: "heart.fill")

        Divider()

        Text("Warnings").font(.headline)
        InfoListRow.warning("Punishing accidents creates fear")
        InfoListRow.warning("Waiting too long after triggers")

        Divider()

        Text("Custom").font(.headline)
        InfoListRow(text: "Custom icon and color", icon: "star.fill", iconColor: .purple)
    }
    .padding()
}
