//
//  SectionHeader.swift
//  Otis-app
//
//  Reusable section header component with icon, title, and optional trailing content
//

import SwiftUI
import OtisShared

/// Styled section header with icon, title, and optional trailing content
struct SectionHeader<Trailing: View>: View {
    let title: String
    var icon: String? = nil
    var tint: Color = .secondary
    @ViewBuilder var trailing: () -> Trailing

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

            Spacer()

            trailing()
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Convenience Initializers

extension SectionHeader where Trailing == EmptyView {
    /// Initialize without trailing content
    init(title: String, icon: String? = nil, tint: Color = .secondary) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.trailing = { EmptyView() }
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

        SectionHeader(title: "With Trailing", icon: "calendar", tint: .purple) {
            Button {
            } label: {
                HStack(spacing: 4) {
                    Text("See All")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }

        UppercaseSectionLabel(title: "How To")

        Text("Content here")
            .inSection(title: "With Extension", icon: "star.fill", tint: .yellow)
    }
    .padding()
}
