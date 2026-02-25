//
//  QuickLogIconButton.swift
//  Ollie-app
//
//  Generic quick log button component for QuickLogBar
//

import SwiftUI
import OllieShared

/// Generic button for quick logging actions
struct QuickLogIconButton: View {
    let icon: CircleIconContent
    let label: String
    let color: Color
    let action: () -> Void
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    var accessibilityIdentifier: String? = nil
    var showBorder: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                CircleIconView(
                    icon: icon,
                    color: color,
                    size: 44,
                    showBorder: showBorder
                )

                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(GlassQuickLogButtonStyle())
        .accessibilityLabel(accessibilityLabel ?? label)
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityIdentifier(accessibilityIdentifier ?? "QUICK_LOG_\(label.uppercased())")
    }
}

/// Interactive button style for quick log buttons
struct GlassQuickLogButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Convenience Initializers

extension QuickLogIconButton {
    /// Create a button for an EventType
    static func forEventType(
        _ type: EventType,
        action: @escaping () -> Void
    ) -> QuickLogIconButton {
        QuickLogIconButton(
            icon: .eventType(type),
            label: type.label,
            color: type.quickLogColor,
            action: action,
            accessibilityLabel: Strings.QuickLog.logEventAccessibility(type.label),
            accessibilityHint: Strings.QuickLog.logEventAccessibilityHint(type.label.lowercased()),
            accessibilityIdentifier: "QUICK_LOG_\(type.rawValue.uppercased())"
        )
    }

    /// Create potty button (combined plassen + poepen)
    static func potty(action: @escaping () -> Void) -> QuickLogIconButton {
        QuickLogIconButton(
            icon: .potty,
            label: Strings.QuickLog.toilet,
            color: .ollieInfo,
            action: action,
            accessibilityLabel: Strings.QuickLog.toiletAccessibility,
            accessibilityHint: Strings.QuickLog.toiletAccessibilityHint,
            accessibilityIdentifier: "QUICK_LOG_POTTY"
        )
    }

    /// Create camera button
    static func camera(action: @escaping () -> Void) -> QuickLogIconButton {
        QuickLogIconButton(
            icon: .system("camera.fill"),
            label: Strings.QuickLog.photo,
            color: .ollieAccent,
            action: action,
            accessibilityLabel: Strings.QuickLog.photoAccessibility,
            accessibilityHint: Strings.QuickLog.photoAccessibilityHint,
            accessibilityIdentifier: "QUICK_LOG_CAMERA",
            showBorder: true
        )
    }

    /// Create "more" button (+ icon)
    static func more(action: @escaping () -> Void) -> QuickLogIconButton {
        QuickLogIconButton(
            icon: .system("plus"),
            label: Strings.QuickLog.more,
            color: .ollieAccent,
            action: action,
            accessibilityLabel: Strings.QuickLog.moreAccessibility,
            accessibilityHint: Strings.QuickLog.moreAccessibilityHint,
            accessibilityIdentifier: "QUICK_LOG_MORE",
            showBorder: true
        )
    }
}

// MARK: - EventType Extension

extension EventType {
    /// Color to use in quick log buttons
    var quickLogColor: Color {
        switch self {
        case .plassen, .poepen: return .ollieInfo
        case .eten, .drinken: return .ollieAccent
        case .slapen, .ontwaken: return .ollieSleep
        case .uitlaten, .tuin: return .ollieSuccess
        default: return .ollieMuted
        }
    }
}

// MARK: - Preview

#Preview("Quick Log Buttons") {
    HStack(spacing: 8) {
        QuickLogIconButton.potty { print("Potty") }
        QuickLogIconButton.forEventType(.eten) { print("Eat") }
        QuickLogIconButton.forEventType(.slapen) { print("Sleep") }
        QuickLogIconButton.camera { print("Camera") }
        QuickLogIconButton.more { print("More") }
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
