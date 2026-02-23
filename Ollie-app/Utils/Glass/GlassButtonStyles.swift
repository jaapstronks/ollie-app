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
            .background(
                ZStack {
                    if colorScheme == .dark {
                        Color.white.opacity(configuration.isPressed ? 0.15 : 0.1)
                    } else {
                        Color.white.opacity(configuration.isPressed ? 0.95 : 0.8)
                    }

                    if let tintColor = tint.color {
                        tintColor.opacity(colorScheme == .dark ? 0.2 : 0.12)
                    }
                }
                .background(.ultraThinMaterial)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: tint.color?.opacity(0.2) ?? Color.black.opacity(0.08),
                radius: configuration.isPressed ? 2 : 6,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassPillButtonStyle {
    static func glassPill(tint: GlassTint = .accent) -> GlassPillButtonStyle {
        GlassPillButtonStyle(tint: tint)
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
            .background(
                ZStack {
                    if colorScheme == .dark {
                        Color.white.opacity(configuration.isPressed ? 0.18 : 0.1)
                    } else {
                        Color.white.opacity(configuration.isPressed ? 0.95 : 0.75)
                    }

                    if let tintColor = tint.color {
                        tintColor.opacity(colorScheme == .dark ? 0.2 : 0.1)
                    }

                    // Highlight
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
                .background(.ultraThinMaterial)
            )
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: tint.color?.opacity(0.25) ?? Color.black.opacity(0.1),
                radius: configuration.isPressed ? 2 : 6,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassIconButtonStyle {
    static func glassIcon(tint: GlassTint = .none, size: CGFloat = 44) -> GlassIconButtonStyle {
        GlassIconButtonStyle(tint: tint, size: size)
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

        VStack(spacing: 24) {
            // Pill buttons
            HStack(spacing: 16) {
                Button("Action") {}
                    .buttonStyle(.glassPill(tint: .accent))

                Button("Success") {}
                    .buttonStyle(.glassPill(tint: .success))

                Button("Warning") {}
                    .buttonStyle(.glassPill(tint: .warning))
            }

            // Icon buttons
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
        .padding()
    }
}
