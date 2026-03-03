//
//  TrainingComponents.swift
//  Otis-app
//
//  Shared components for training views - badges, icons, headers, and button styles
//

import SwiftUI

// MARK: - Animation Constants

/// Standardized animations for training views
enum TrainingAnimations {
    /// Standard card toggle animation
    static let cardToggle = Animation.spring(response: 0.3, dampingFraction: 0.8)
    /// Faster toggle for nested elements like mistakes
    static let quickToggle = Animation.spring(response: 0.25, dampingFraction: 0.8)
    /// Checkbox/item toggle animation
    static let checkboxToggle = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

// MARK: - Status Badge

/// Displays a skill's current status with icon and label
struct StatusBadge: View {
    let status: SkillStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(status.color)
    }
}

// MARK: - Method Badge

/// Displays a training method with icon and label
struct MethodBadge: View {
    let method: TrainingMethod
    var showLabel: Bool = true
    var fontSize: Font = .caption

    var body: some View {
        HStack(spacing: showLabel ? 4 : 0) {
            Image(systemName: method.icon)
                .font(fontSize == .caption ? .caption2 : .system(size: 9))
            if showLabel {
                Text(method.label)
                    .font(fontSize == .caption ? .caption : .caption2)
            }
        }
        .foregroundStyle(method == .operant ? Color.purple : Color.blue)
    }
}

// MARK: - Icon Circle

/// Circular background with centered icon - used for skill headers
struct IconCircle: View {
    let systemName: String
    var size: CGFloat = 56
    var iconSize: CGFloat = 24
    var foregroundColor: Color = .otisAccent
    var backgroundOpacity: (dark: Double, light: Double) = (0.2, 0.15)

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(foregroundColor.opacity(colorScheme == .dark ? backgroundOpacity.dark : backgroundOpacity.light))
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: iconSize))
                .foregroundStyle(foregroundColor)
        }
    }
}

// MARK: - Training Section Header

/// Uppercase section header with icon - used in training detail sheets
/// Extends the existing UppercaseSectionLabel with an icon
struct TrainingSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
        }
    }
}

// MARK: - Scale Button Style

/// A button style that provides scale feedback without blocking scroll gestures
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.92
    var pressedOpacity: CGFloat = 0.85

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Circular Icon Button

/// Circular button with icon - used for info buttons, etc.
struct CircularIconButton: View {
    let systemName: String
    let action: () -> Void
    var size: CGFloat = 40

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.light()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Previews

#Preview("Status Badges") {
    VStack(spacing: 12) {
        StatusBadge(status: .notStarted)
        StatusBadge(status: .started)
        StatusBadge(status: .practicing)
        StatusBadge(status: .mastered)
    }
    .padding()
}

#Preview("Method Badges") {
    VStack(spacing: 12) {
        MethodBadge(method: .operant)
        MethodBadge(method: .classical)
        MethodBadge(method: .operant, showLabel: false)
    }
    .padding()
}

#Preview("Icon Circle") {
    HStack(spacing: 20) {
        IconCircle(systemName: "bell.fill")
        IconCircle(systemName: "arrow.down.to.line", foregroundColor: .otisSuccess)
        IconCircle(systemName: "lock.fill", size: 40, iconSize: 18, foregroundColor: .secondary)
    }
    .padding()
}

#Preview("Training Section Header") {
    VStack(alignment: .leading, spacing: 16) {
        TrainingSectionHeader(title: "How to Train", icon: "list.number")
        TrainingSectionHeader(title: "Common Mistakes", icon: "exclamationmark.triangle")
        TrainingSectionHeader(title: "Tips", icon: "lightbulb")
    }
    .padding()
}
