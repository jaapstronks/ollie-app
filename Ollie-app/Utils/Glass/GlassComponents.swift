//
//  GlassComponents.swift
//  Ollie-app
//
//  iOS 26 "Liquid Glass" design system - Reusable components
//

import SwiftUI

// MARK: - Glass Icon Circle

/// Circular glass background for icons in status cards
struct GlassIconCircle<Content: View>: View {
    let tintColor: Color
    let size: CGFloat
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        tintColor: Color,
        size: CGFloat = 40,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tintColor = tintColor
        self.size = size
        self.content = content
    }

    var body: some View {
        content()
            .frame(width: size, height: size)
            .background(iconBackground)
            .clipShape(Circle())
            .overlay(iconOverlay)
    }

    @ViewBuilder
    private var iconBackground: some View {
        ZStack {
            tintColor.opacity(colorScheme == .dark ? 0.2 : 0.15)

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var iconOverlay: some View {
        Circle()
            .strokeBorder(
                tintColor.opacity(0.3),
                lineWidth: 0.5
            )
    }
}

// MARK: - Glass Separator

/// Vertical glass separator line for use between stat items
struct GlassSeparator: View {
    let height: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(height: CGFloat = 40) {
        self.height = height
    }

    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.08))
            .frame(width: 1, height: height)
    }
}

// MARK: - Glass Divider

/// Horizontal glass divider line for use between sections
struct GlassDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06))
            .frame(height: 1)
    }
}

// MARK: - Glass Status Pill

/// Status pill/badge with glass styling
struct GlassStatusPill: View {
    let text: String
    let tintColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(tintColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tintColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(tintColor.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: - Preview

#Preview("Glass Components") {
    ZStack {
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 24) {
            // Icon circles
            HStack(spacing: 16) {
                GlassIconCircle(tintColor: .blue) {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.blue)
                }

                GlassIconCircle(tintColor: .green, size: 50) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                }

                GlassIconCircle(tintColor: .orange, size: 36) {
                    Image(systemName: "exclamationmark")
                        .foregroundStyle(.orange)
                }
            }

            // Separators
            HStack(spacing: 20) {
                Text("Item 1")
                GlassSeparator()
                Text("Item 2")
                GlassSeparator(height: 30)
                Text("Item 3")
            }

            // Divider
            VStack(spacing: 12) {
                Text("Section 1")
                GlassDivider()
                Text("Section 2")
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)

            // Status pills
            HStack(spacing: 12) {
                GlassStatusPill(text: "Good", tintColor: .green)
                GlassStatusPill(text: "Warning", tintColor: .orange)
                GlassStatusPill(text: "Alert", tintColor: .red)
            }
        }
        .padding()
    }
}
