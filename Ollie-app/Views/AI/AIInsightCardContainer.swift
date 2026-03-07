//
//  AIInsightCardContainer.swift
//  Ollie-app
//
//  Reusable container for AI-powered insight cards.
//  Consolidates duplicated header, loading, and background patterns.
//

import SwiftUI

/// Container view for AI insight cards providing consistent styling
///
/// Usage:
/// ```swift
/// AIInsightCardContainer(
///     title: "Training Suggestion",
///     tint: .purple,
///     isLoading: isLoading,
///     isVisible: shouldShow
/// ) {
///     // Your content here
///     Text(guidance.message)
/// }
/// ```
struct AIInsightCardContainer<Content: View>: View {
    let title: String
    let tint: Color
    let isLoading: Bool
    let isVisible: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        tint: Color,
        isLoading: Bool,
        isVisible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.tint = tint
        self.isLoading = isLoading
        self.isVisible = isVisible
        self.content = content
    }

    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: 12) {
                headerView

                if isLoading {
                    loadingView
                } else {
                    content()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(colorScheme == .dark ? 0.12 : 0.08))
            )
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundStyle(tint)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 8)
            Spacer()
        }
    }
}

// MARK: - AI Content Building Blocks

/// A suggestion row with lightbulb icon
struct AISuggestionRow: View {
    let text: String
    var icon: String = "lightbulb.fill"
    var iconColor: Color = .yellow

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// A bullet point list for AI insights
struct AIBulletList: View {
    let items: [String]
    var bulletColor: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(bulletColor)
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// A warning row for risk factors or alerts
struct AIWarningRow: View {
    let text: String
    var color: Color = .orange

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(color)
        }
    }
}

/// A category badge (commonly used in AI cards)
struct AICategoryBadge: View {
    let label: String
    let value: String
    var badgeColor: Color = .pink

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(badgeColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                .clipShape(Capsule())
        }
    }
}

/// A labeled section within AI content
struct AILabeledSection: View {
    let label: String
    var labelColor: Color = .blue
    let content: () -> any View

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(labelColor)

            AnyView(content())
        }
    }
}

// MARK: - Preview

#Preview("AI Insight Cards") {
    ScrollView {
        VStack(spacing: 16) {
            AIInsightCardContainer(
                title: "Training Suggestion",
                tint: .purple,
                isLoading: false,
                isVisible: true
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Great progress this week!")
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    AISuggestionRow(text: "Try a 3-minute session before dinner")

                    AIBulletList(
                        items: ["Focus on consistency", "Keep treats handy"],
                        bulletColor: .purple
                    )
                }
            }

            AIInsightCardContainer(
                title: "Health Insight",
                tint: .blue,
                isLoading: false,
                isVisible: true
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Sleep patterns look healthy")
                            .font(.subheadline)
                    }

                    AIWarningRow(text: "Consider more outdoor time")
                }
            }

            AIInsightCardContainer(
                title: "Loading Example",
                tint: .green,
                isLoading: true,
                isVisible: true
            ) {
                EmptyView()
            }
        }
        .padding()
    }
}
