//
//  LiquidGlass.swift
//  Ollie-app
//
//  iOS 26 "Liquid Glass" design system implementation
//  Provides translucent, dynamic materials for navigation layer elements

import SwiftUI

// MARK: - Glass Style Configuration

/// Glass effect variants matching iOS 26 design language
enum GlassStyle {
    /// Default glass for toolbars, buttons, navigation
    case regular
    /// Clearer glass for floating controls over media
    case clear
    /// Subtle glass for cards and containers
    case card
    /// Prominent glass for hero elements
    case prominent
}

/// Tint colors for semantic meaning
enum GlassTint {
    case none
    case accent
    case success
    case warning
    case danger
    case info
    case sleep

    var color: Color? {
        switch self {
        case .none: return nil
        case .accent: return Color.ollieAccent
        case .success: return Color.ollieSuccess
        case .warning: return Color.ollieWarning
        case .danger: return Color.ollieDanger
        case .info: return Color.ollieInfo
        case .sleep: return Color.ollieSleep
        }
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

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(glassOverlay)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .scaleEffect(isPressed && isInteractive ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
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

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(glassOverlay)
            .shadow(color: shadowColor, radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .brightness(isPressed ? 0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
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
}

// MARK: - Pill Button Style

/// Capsule-shaped glass button for actions
struct GlassPillButtonStyle: ButtonStyle {
    let tint: GlassTint
    @Environment(\.colorScheme) private var colorScheme

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
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
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
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassIconButtonStyle {
    static func glassIcon(tint: GlassTint = .none, size: CGFloat = 44) -> GlassIconButtonStyle {
        GlassIconButtonStyle(tint: tint, size: size)
    }
}

// MARK: - Preview

#Preview("Glass Styles") {
    ZStack {
        // Background gradient
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                // Regular glass
                Text("Regular Glass")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .liquidGlass(style: .regular)

                // Tinted glass
                Text("Accent Tinted")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .liquidGlass(style: .regular, tint: .accent)

                // Card glass
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(.headline)
                    Text("Subtle glass for content cards")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(tint: .success)

                // Buttons
                HStack(spacing: 16) {
                    Button("Action") {}
                        .buttonStyle(.glassPill(tint: .accent))

                    Button {} label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glassIcon(tint: .accent, size: 44))

                    Button {} label: {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.glassIcon(tint: .none, size: 44))
                }

                // Bar style
                HStack {
                    ForEach(["🚽", "💩", "🍽️", "😴"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .glassBar()
            }
            .padding()
        }
    }
}
