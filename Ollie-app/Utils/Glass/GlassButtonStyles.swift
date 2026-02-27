//
//  GlassButtonStyles.swift
//  Ollie-app
//
//  iOS 26 "Liquid Glass" design system - Button styles
//

import SwiftUI

// MARK: - Pill Button Style

/// Capsule-shaped glass button for actions
struct GlassPillButtonStyle: ButtonStyle {
    let tint: GlassTint
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(tint.color ?? .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(glassPillBackground(isPressed: configuration.isPressed))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(GlassButtonHelpers.capsuleBorderGradient(colorScheme: colorScheme), lineWidth: 0.5))
            .shadow(
                color: tint.color?.opacity(0.2) ?? Color.black.opacity(0.08),
                radius: configuration.isPressed ? 2 : 6,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }

    @ViewBuilder
    private func glassPillBackground(isPressed: Bool) -> some View {
        ZStack {
            Color.white.opacity(GlassButtonHelpers.baseOpacity(isPressed: isPressed, colorScheme: colorScheme))
            if let tintColor = tint.color {
                tintColor.opacity(GlassButtonHelpers.tintOpacity(colorScheme: colorScheme))
            }
        }
        .background(.ultraThinMaterial)
    }
}

extension ButtonStyle where Self == GlassPillButtonStyle {
    static func glassPill(tint: GlassTint = .accent) -> GlassPillButtonStyle {
        GlassPillButtonStyle(tint: tint)
    }
}

// MARK: - Compact Pill Button Style

/// Compact capsule-shaped glass button for inline actions (e.g., in status card headers)
struct GlassPillCompactButtonStyle: ButtonStyle {
    let tint: GlassTint
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(tint.color ?? .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(glassPillBackground(isPressed: configuration.isPressed))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(GlassButtonHelpers.capsuleBorderGradient(colorScheme: colorScheme), lineWidth: 0.5))
            .shadow(
                color: tint.color?.opacity(0.15) ?? Color.black.opacity(0.06),
                radius: configuration.isPressed ? 1 : 4,
                y: configuration.isPressed ? 0 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }

    @ViewBuilder
    private func glassPillBackground(isPressed: Bool) -> some View {
        ZStack {
            Color.white.opacity(GlassButtonHelpers.baseOpacity(isPressed: isPressed, colorScheme: colorScheme))
            if let tintColor = tint.color {
                tintColor.opacity(GlassButtonHelpers.tintOpacity(colorScheme: colorScheme))
            }
        }
        .background(.ultraThinMaterial)
    }
}

extension ButtonStyle where Self == GlassPillCompactButtonStyle {
    static func glassPillCompact(tint: GlassTint = .accent) -> GlassPillCompactButtonStyle {
        GlassPillCompactButtonStyle(tint: tint)
    }
}

// MARK: - Icon Button Style

/// Circular glass button for icon actions
struct GlassIconButtonStyle: ButtonStyle {
    let tint: GlassTint
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.45, weight: .medium))
            .foregroundStyle(tint.color ?? .primary)
            .frame(width: size, height: size)
            .background(glassIconBackground(isPressed: configuration.isPressed))
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(GlassButtonHelpers.circleBorderGradient(colorScheme: colorScheme), lineWidth: 0.5))
            .shadow(
                color: tint.color?.opacity(0.25) ?? Color.black.opacity(0.1),
                radius: configuration.isPressed ? 2 : 6,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }

    @ViewBuilder
    private func glassIconBackground(isPressed: Bool) -> some View {
        ZStack {
            Color.white.opacity(GlassButtonHelpers.baseOpacity(
                isPressed: isPressed,
                colorScheme: colorScheme,
                pressedLight: 0.95,
                normalLight: 0.75,
                pressedDark: 0.18,
                normalDark: 0.1
            ))
            if let tintColor = tint.color {
                tintColor.opacity(GlassButtonHelpers.tintOpacity(colorScheme: colorScheme, dark: 0.2, light: 0.1))
            }
            GlassButtonHelpers.highlightGradient(colorScheme: colorScheme)
        }
        .background(.ultraThinMaterial)
    }
}

extension ButtonStyle where Self == GlassIconButtonStyle {
    static func glassIcon(tint: GlassTint = .none, size: CGFloat = 44) -> GlassIconButtonStyle {
        GlassIconButtonStyle(tint: tint, size: size)
    }
}

// MARK: - Scale Button Style

/// Lightweight button style with scale/opacity feedback
/// Use this for interactive cards, rows, and list items
struct GlassScaleButtonStyle: ButtonStyle {
    let scaleAmount: CGFloat
    let opacityAmount: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(scaleAmount: CGFloat = 0.97, opacityAmount: CGFloat = 0.85) {
        self.scaleAmount = scaleAmount
        self.opacityAmount = opacityAmount
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? opacityAmount : 1.0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == GlassScaleButtonStyle {
    /// Scale button style for interactive cards and rows
    static var glassScale: GlassScaleButtonStyle {
        GlassScaleButtonStyle()
    }

    /// Scale button style with custom amounts
    static func glassScale(scale: CGFloat = 0.97, opacity: CGFloat = 0.85) -> GlassScaleButtonStyle {
        GlassScaleButtonStyle(scaleAmount: scale, opacityAmount: opacity)
    }
}

// MARK: - Primary Action Button Style

/// Primary action button with glass styling
/// Use this for main CTAs like "Save", "Continue", "Start"
struct GlassPrimaryButtonStyle: ButtonStyle {
    let tint: GlassTint

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    init(tint: GlassTint = .accent) {
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if let tintColor = tint.color {
                        tintColor
                            .opacity(isEnabled ? 1.0 : 0.5)
                    } else {
                        Color.ollieAccent
                            .opacity(isEnabled ? 1.0 : 0.5)
                    }

                    // Highlight gradient
                    LinearGradient(
                        colors: [
                            Color.white.opacity(configuration.isPressed ? 0.1 : 0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM, style: .continuous))
            .shadow(
                color: (tint.color ?? .ollieAccent).opacity(isEnabled ? 0.3 : 0.1),
                radius: configuration.isPressed ? 4 : 8,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassPrimaryButtonStyle {
    /// Primary action button style
    static var glassPrimary: GlassPrimaryButtonStyle {
        GlassPrimaryButtonStyle()
    }

    /// Primary action button style with custom tint
    static func glassPrimary(tint: GlassTint) -> GlassPrimaryButtonStyle {
        GlassPrimaryButtonStyle(tint: tint)
    }
}

// MARK: - Secondary Action Button Style

/// Secondary action button with glass styling
/// Use this for secondary CTAs like "Cancel", "Skip"
struct GlassSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if colorScheme == .dark {
                        Color.white.opacity(configuration.isPressed ? 0.12 : 0.08)
                    } else {
                        Color.white.opacity(configuration.isPressed ? 0.95 : 0.8)
                    }
                }
                .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM, style: .continuous)
                    .strokeBorder(
                        Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.1),
                        lineWidth: 0.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassSecondaryButtonStyle {
    /// Secondary action button style
    static var glassSecondary: GlassSecondaryButtonStyle {
        GlassSecondaryButtonStyle()
    }
}

// MARK: - Destructive Button Style

/// Destructive action button with glass styling
/// Use this for destructive actions like "Delete", "Remove"
struct GlassDestructiveButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(Color.ollieDanger)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Color.ollieDanger.opacity(colorScheme == .dark ? 0.15 : 0.1)

                    if configuration.isPressed {
                        Color.ollieDanger.opacity(0.1)
                    }
                }
                .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM, style: .continuous)
                    .strokeBorder(
                        Color.ollieDanger.opacity(0.3),
                        lineWidth: 0.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassDestructiveButtonStyle {
    /// Destructive action button style
    static var glassDestructive: GlassDestructiveButtonStyle {
        GlassDestructiveButtonStyle()
    }
}

// MARK: - Preview

#Preview("Glass Button Styles") {
    ZStack {
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                // Pill buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pill Buttons").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        Button("Action") {}
                            .buttonStyle(.glassPill(tint: .accent))

                        Button("Success") {}
                            .buttonStyle(.glassPill(tint: .success))

                        Button("Warning") {}
                            .buttonStyle(.glassPill(tint: .warning))
                    }
                }

                // Icon buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon Buttons").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        Button {} label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.glassIcon(tint: .accent, size: 44))

                        Button {} label: {
                            Image(systemName: "gear")
                        }
                        .buttonStyle(.glassIcon(tint: .none, size: 44))

                        Button {} label: {
                            Image(systemName: "heart.fill")
                        }
                        .buttonStyle(.glassIcon(tint: .danger, size: 50))
                    }
                }

                // Primary/Secondary buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Action Buttons").font(.caption).foregroundStyle(.secondary)

                    Button("Primary Action") {}
                        .buttonStyle(.glassPrimary)

                    Button("Secondary Action") {}
                        .buttonStyle(.glassSecondary)

                    Button("Destructive Action") {}
                        .buttonStyle(.glassDestructive)
                }

                // Scale button demo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scale Button (for cards)").font(.caption).foregroundStyle(.secondary)

                    Button {
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Tap me for scale effect")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(LayoutConstants.cornerRadiusM)
                    }
                    .buttonStyle(.glassScale)
                }
            }
            .padding()
        }
    }
}
