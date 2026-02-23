//
//  GlassBackground.swift
//  Ollie-app
//
//  Reusable liquid glass background styling for iOS 26 aesthetic
//

import SwiftUI

// MARK: - Glass Background Configurations

/// Configuration for glass background styling
struct GlassBackgroundConfig {
    let cornerRadius: CGFloat
    let baseOpacityLight: CGFloat
    let baseOpacityDark: CGFloat
    let highlightOpacityLight: CGFloat
    let highlightOpacityDark: CGFloat
    let borderOpacityLight: (top: CGFloat, bottom: CGFloat)
    let borderOpacityDark: (top: CGFloat, bottom: CGFloat)
    let material: Material

    /// Standard card style (DigestCard, status cards)
    static let card = GlassBackgroundConfig(
        cornerRadius: 16,
        baseOpacityLight: 0.7,
        baseOpacityDark: 0.05,
        highlightOpacityLight: 0.25,
        highlightOpacityDark: 0.08,
        borderOpacityLight: (top: 0.35, bottom: 0.08),
        borderOpacityDark: (top: 0.12, bottom: 0.03),
        material: .thinMaterial
    )

    /// Bar style (QuickLogBar)
    static let bar = GlassBackgroundConfig(
        cornerRadius: 20,
        baseOpacityLight: 0.75,
        baseOpacityDark: 0.08,
        highlightOpacityLight: 0.4,
        highlightOpacityDark: 0.12,
        borderOpacityLight: (top: 0.6, bottom: 0.15),
        borderOpacityDark: (top: 0.25, bottom: 0.05),
        material: .ultraThinMaterial
    )

    /// Menu style (FAB menu)
    static let menu = GlassBackgroundConfig(
        cornerRadius: 16,
        baseOpacityLight: 0.85,
        baseOpacityDark: 0.08,
        highlightOpacityLight: 0.4,
        highlightOpacityDark: 0.12,
        borderOpacityLight: (top: 0.6, bottom: 0.15),
        borderOpacityDark: (top: 0.25, bottom: 0.05),
        material: .ultraThinMaterial
    )
}

// MARK: - Glass Background View

/// Liquid glass background with configurable styling
struct GlassBackgroundView: View {
    let config: GlassBackgroundConfig
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Base layer
            Color.white.opacity(colorScheme == .dark ? config.baseOpacityDark : config.baseOpacityLight)

            // Top highlight gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? config.highlightOpacityDark : config.highlightOpacityLight),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(config.material)
    }
}

/// Glass border overlay with gradient
struct GlassOverlayView: View {
    let config: GlassBackgroundConfig
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? config.borderOpacityDark.top : config.borderOpacityLight.top),
                        Color.white.opacity(colorScheme == .dark ? config.borderOpacityDark.bottom : config.borderOpacityLight.bottom),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

// MARK: - View Modifier

/// ViewModifier that applies glass background styling
struct GlassBackgroundModifier: ViewModifier {
    let config: GlassBackgroundConfig

    func body(content: Content) -> some View {
        content
            .background(GlassBackgroundView(config: config))
            .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous))
            .overlay(GlassOverlayView(config: config))
    }
}

// MARK: - View Extension

extension View {
    /// Applies liquid glass background styling
    func glassBackground(_ config: GlassBackgroundConfig = .card) -> some View {
        modifier(GlassBackgroundModifier(config: config))
    }
}

// MARK: - Preview

#Preview("Glass Backgrounds") {
    VStack(spacing: 20) {
        Text("Card Style")
            .padding()
            .frame(maxWidth: .infinity)
            .glassBackground(.card)

        Text("Bar Style")
            .padding()
            .frame(maxWidth: .infinity)
            .glassBackground(.bar)

        Text("Menu Style")
            .padding()
            .frame(maxWidth: .infinity)
            .glassBackground(.menu)
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
