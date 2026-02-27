//
//  GlassToggleButton.swift
//  Ollie-app
//
//  Reusable glass toggle button component for selection UIs.
//  Used by CatchUpSheet, StartCoverageGapSheet, and similar selection interfaces.
//

import SwiftUI

// MARK: - Simple Glass Toggle Button

/// A simple glass toggle button with just a text label
struct GlassToggleButton: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        _ label: String,
        isSelected: Bool,
        color: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? color : GlassButtonHelpers.glassColor(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? color : Color.primary.opacity(0.1),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Glass Toggle Button

/// A glass toggle button with icon and label
struct IconGlassToggleButton: View {
    let icon: String
    let label: String
    let subtitle: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        label: String,
        subtitle: String? = nil,
        isSelected: Bool,
        color: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? color : GlassButtonHelpers.glassColor(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? color : Color.primary.opacity(0.1),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Simple Toggle") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            GlassToggleButton("Yes", isSelected: true, action: {})
            GlassToggleButton("No", isSelected: false, action: {})
        }

        HStack(spacing: 12) {
            GlassToggleButton("Option A", isSelected: false, color: .orange, action: {})
            GlassToggleButton("Option B", isSelected: true, color: .orange, action: {})
        }
    }
    .padding()
}

#Preview("Icon Toggle") {
    HStack(spacing: 12) {
        IconGlassToggleButton(
            icon: "moon.fill",
            label: "Sleeping",
            subtitle: "Currently napping",
            isSelected: true,
            color: .purple,
            action: {}
        )
        IconGlassToggleButton(
            icon: "sun.max.fill",
            label: "Awake",
            subtitle: "Active and alert",
            isSelected: false,
            color: .yellow,
            action: {}
        )
    }
    .padding()
}
