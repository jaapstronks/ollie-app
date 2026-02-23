//
//  GlassModifiers.swift
//  Ollie-app
//
//  iOS 26 "Liquid Glass" design system - View modifiers
//

import SwiftUI

// MARK: - Glass Effect Helpers

/// Shared helpers for creating glass backgrounds and overlays
/// Reduces duplication across glass modifiers
enum GlassEffects {
    /// Create a glass background layer
    @ViewBuilder
    static func background(
        baseOpacity: (dark: Double, light: Double),
        tintColor: Color?,
        tintOpacity: (dark: Double, light: Double) = (0.15, 0.1),
        gradientOpacity: (dark: Double, light: Double) = (0.1, 0.3),
        material: Material = .ultraThinMaterial,
        colorScheme: ColorScheme
    ) -> some View {
        ZStack {
            // Base color
            if colorScheme == .dark {
                Color.white.opacity(baseOpacity.dark)
            } else {
                Color.white.opacity(baseOpacity.light)
            }

            // Tint overlay
            if let tintColor = tintColor {
                tintColor.opacity(colorScheme == .dark ? tintOpacity.dark : tintOpacity.light)
            }

            // Inner glow gradient for depth
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? gradientOpacity.dark : gradientOpacity.light),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(material)
    }

    /// Create a glass border overlay
    @ViewBuilder
    static func overlay(
        cornerRadius: CGFloat,
        borderOpacity: (topDark: Double, topLight: Double, bottomDark: Double, bottomLight: Double) = (0.2, 0.5, 0.05, 0.1),
        colorScheme: ColorScheme
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? borderOpacity.topDark : borderOpacity.topLight),
                        Color.white.opacity(colorScheme == .dark ? borderOpacity.bottomDark : borderOpacity.bottomLight),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

// MARK: - Liquid Glass View Modifier

struct LiquidGlassModifier: ViewModifier {
    let style: GlassStyle
    let tint: GlassTint
    let cornerRadius: CGFloat
    let isInteractive: Bool

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(glassOverlay)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .scaleEffect(isPressed && isInteractive ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    // MARK: - Glass Background

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Base blur layer
            switch style {
            case .regular:
                if colorScheme == .dark {
                    Color.white.opacity(0.08)
                } else {
                    Color.white.opacity(0.7)
                }
            case .clear:
                if colorScheme == .dark {
                    Color.white.opacity(0.05)
                } else {
                    Color.white.opacity(0.5)
                }
            case .card:
                if colorScheme == .dark {
                    Color.white.opacity(0.06)
                } else {
                    Color.white.opacity(0.8)
                }
            case .prominent:
                if colorScheme == .dark {
                    Color.white.opacity(0.1)
                } else {
                    Color.white.opacity(0.85)
                }
            }

            // Tint overlay
            if let tintColor = tint.color {
                tintColor.opacity(colorScheme == .dark ? 0.15 : 0.1)
            }

            // Inner glow gradient for depth
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Glass Overlay (Border Effect)

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    // MARK: - Shadow Properties

    private var shadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08)
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .regular: return 8
        case .clear: return 4
        case .card: return 6
        case .prominent: return 12
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .regular: return 4
        case .clear: return 2
        case .card: return 3
        case .prominent: return 6
        }
    }
}

// MARK: - Interactive Glass Button Modifier

struct InteractiveGlassModifier: ViewModifier {
    let style: GlassStyle
    let tint: GlassTint
    let cornerRadius: CGFloat

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(glassOverlay)
            .shadow(color: shadowColor, radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .brightness(isPressed ? 0.05 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(isPressed ? 0.12 : 0.08)
            } else {
                Color.white.opacity(isPressed ? 0.9 : 0.75)
            }

            if let tintColor = tint.color {
                tintColor.opacity(colorScheme == .dark ? 0.2 : 0.15)
            }

            // Highlight gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    private var shadowColor: Color {
        if let tintColor = tint.color {
            return tintColor.opacity(0.3)
        }
        return Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1)
    }
}

// MARK: - Glass Bar Modifier (for QuickLogBar, TabBar)

struct GlassBarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base material
                    if colorScheme == .dark {
                        Color.black.opacity(0.3)
                    } else {
                        Color.white.opacity(0.7)
                    }

                    // Top highlight
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.4),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 1)

                        Spacer()
                    }
                }
                .background(.ultraThinMaterial)
            )
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    let tint: GlassTint
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base
                    if colorScheme == .dark {
                        Color.white.opacity(0.05)
                    } else {
                        Color.white.opacity(0.6)
                    }

                    // Tint
                    if let tintColor = tint.color {
                        tintColor.opacity(colorScheme == .dark ? 0.1 : 0.08)
                    }

                    // Top highlight
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
                .background(.thinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                Color.white.opacity(colorScheme == .dark ? 0.03 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: tint.color?.opacity(0.15) ?? Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Glass Status Card Modifier

/// Glass card background and overlay for status cards
/// Use this for cards that need custom tint colors (not GlassTint enum)
struct GlassStatusCardModifier: ViewModifier {
    let tintColor: Color?
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(tintColor: Color? = nil, cornerRadius: CGFloat = 16) {
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(glassOverlay)
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.05)
            } else {
                Color.white.opacity(0.7)
            }

            // Tint
            if let tintColor = tintColor {
                tintColor.opacity(colorScheme == .dark ? 0.06 : 0.04)
            }

            // Top highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                        (tintColor ?? Color.white).opacity(colorScheme == .dark ? 0.08 : 0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply liquid glass effect to navigation layer elements
    func liquidGlass(
        style: GlassStyle = .regular,
        tint: GlassTint = .none,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(LiquidGlassModifier(
            style: style,
            tint: tint,
            cornerRadius: cornerRadius,
            isInteractive: false
        ))
    }

    /// Apply interactive liquid glass effect (for buttons)
    func liquidGlassButton(
        style: GlassStyle = .regular,
        tint: GlassTint = .none,
        cornerRadius: CGFloat = 12
    ) -> some View {
        modifier(InteractiveGlassModifier(
            style: style,
            tint: tint,
            cornerRadius: cornerRadius
        ))
    }

    /// Apply glass bar effect (for bottom bars, tab bars)
    func glassBar() -> some View {
        modifier(GlassBarModifier())
    }

    /// Apply glass card effect
    func glassCard(
        tint: GlassTint = .none,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(GlassCardModifier(tint: tint, cornerRadius: cornerRadius))
    }

    /// Apply glass status card styling with custom tint color
    func glassStatusCard(tintColor: Color? = nil, cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassStatusCardModifier(tintColor: tintColor, cornerRadius: cornerRadius))
    }
}
