//
//  SectionHeader.swift
//  Ollie-app
//
//  Reusable section header component with icon and title
//

import SwiftUI
import OllieShared

/// Styled section header with icon and title
struct SectionHeader: View {
    let title: String
    var icon: String? = nil
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Uppercase section label (for training cards, etc.)
struct UppercaseSectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
    }
}

// MARK: - View Extension for Section Building

extension View {
    /// Wraps content in a section with header
    func inSection(
        title: String,
        icon: String? = nil,
        tint: Color = .secondary
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, icon: icon, tint: tint)
            self
        }
    }
}

// MARK: - Preview

#Preview("Section Headers") {
    VStack(alignment: .leading, spacing: 20) {
        SectionHeader(title: "Outdoor Streak", icon: "flame.fill", tint: .orange)

        SectionHeader(title: "Potty Gaps", icon: "chart.bar.fill", tint: .blue)

        SectionHeader(title: "Simple Header")

        UppercaseSectionLabel(title: "How To")

        Text("Content here")
            .inSection(title: "With Extension", icon: "star.fill", tint: .yellow)
    }
    .padding()
}
