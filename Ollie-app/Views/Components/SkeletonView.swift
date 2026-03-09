//
//  SkeletonView.swift
//  Otis-app
//
//  Skeleton loading placeholders for content

import SwiftUI

/// A shimmering skeleton placeholder view
struct SkeletonView: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 4

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: isAnimating ? .trailing : .leading,
                    endPoint: isAnimating ? .leading : .trailing
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// Skeleton placeholder for a card
struct SkeletonCard: View {
    var lineCount: Int = 3
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title line
            SkeletonView(height: 16, cornerRadius: 4)
                .frame(width: 120)

            // Content lines
            ForEach(0..<lineCount, id: \.self) { index in
                SkeletonView(height: 12, cornerRadius: 3)
                    .frame(width: index == lineCount - 1 ? 180 : nil)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

/// Skeleton for milestone row
struct MilestoneRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Icon placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                SkeletonView(height: 14, cornerRadius: 3)
                    .frame(width: 140)

                SkeletonView(height: 10, cornerRadius: 2)
                    .frame(width: 80)
            }

            Spacer()

            SkeletonView(height: 12, cornerRadius: 3)
                .frame(width: 50)
        }
        .padding(.vertical, 8)
    }
}

/// Skeleton for the This Week card
struct ThisWeekCardSkeleton: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 20, height: 20)

                SkeletonView(height: 14, cornerRadius: 3)
                    .frame(width: 80)

                Spacer()

                SkeletonView(height: 20, cornerRadius: 10)
                    .frame(width: 60)
            }

            // Socialization progress
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(height: 12, cornerRadius: 3)
                    .frame(width: 120)

                // Week dots
                HStack(spacing: 4) {
                    ForEach(0..<9, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 28, height: 28)
                    }
                }

                SkeletonView(height: 8, cornerRadius: 4)
            }

            // Milestone preview
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    SkeletonView(height: 12, cornerRadius: 3)
                        .frame(width: 120)

                    SkeletonView(height: 10, cornerRadius: 2)
                        .frame(width: 80)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

/// Skeleton for socialization week timeline
struct SocializationTimelineSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                SkeletonView(height: 14, cornerRadius: 3)
                    .frame(width: 140)

                Spacer()

                SkeletonView(height: 20, cornerRadius: 10)
                    .frame(width: 80)
            }

            // Week dots
            HStack(spacing: 4) {
                ForEach(0..<9, id: \.self) { _ in
                    VStack(spacing: 4) {
                        SkeletonView(height: 10, cornerRadius: 2)
                            .frame(width: 16)

                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 28, height: 28)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 8, height: 8)

                        SkeletonView(height: 10, cornerRadius: 2)
                            .frame(width: 50)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - AI Insight Card Skeleton

/// Skeleton placeholder for AI insight cards (used by AIInsightCardContainer)
struct AIInsightCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SkeletonView(height: 16, cornerRadius: 4)

            SkeletonView(height: 12, cornerRadius: 3)
                .frame(width: 200)

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 14, height: 14)

                SkeletonView(height: 12, cornerRadius: 3)
                    .frame(width: 180)
            }
        }
    }
}

// MARK: - Morning Briefing Skeleton

/// Skeleton placeholder for the morning briefing card
struct MorningBriefingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 24, height: 24)

                SkeletonView(height: 18, cornerRadius: 4)
                    .frame(width: 180)

                Spacer()
            }

            SkeletonView(height: 14, cornerRadius: 3)

            SkeletonView(height: 14, cornerRadius: 3)
                .frame(width: 240)

            SkeletonView(height: 32, cornerRadius: 8)
                .frame(width: 200)
        }
    }
}

// MARK: - Weather Section Skeleton

/// Skeleton placeholder for weather section
struct WeatherSectionSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 16, height: 16)

                SkeletonView(height: 14, cornerRadius: 3)
                    .frame(width: 40)
            }

            SkeletonView(height: 12, cornerRadius: 3)
                .frame(width: 60)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

// MARK: - Recap Sheet Skeleton

/// Skeleton placeholder for week/month recap sheets
struct RecapSheetSkeleton: View {
    var body: some View {
        VStack(spacing: 24) {
            // Navigation placeholder
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 24, height: 24)

                Spacer()

                SkeletonView(height: 24, cornerRadius: 4)
                    .frame(width: 120)

                Spacer()

                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal)

            // Stats grid
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 28, height: 28)

                        SkeletonView(height: 24, cornerRadius: 4)
                            .frame(width: 40)

                        SkeletonView(height: 10, cornerRadius: 2)
                            .frame(width: 60)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)

            // Photo grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonView(height: 120, cornerRadius: 12)
                }
            }
        }
    }
}

// MARK: - View Modifier for Loading State

extension View {
    /// Shows a skeleton placeholder when loading
    @ViewBuilder
    func skeleton<Placeholder: View>(
        isLoading: Bool,
        @ViewBuilder placeholder: () -> Placeholder
    ) -> some View {
        if isLoading {
            placeholder()
        } else {
            self
        }
    }
}

// MARK: - Previews

#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Skeleton Card")
                .font(.headline)
            SkeletonCard()

            Text("Milestone Row Skeleton")
                .font(.headline)
            VStack {
                MilestoneRowSkeleton()
                MilestoneRowSkeleton()
                MilestoneRowSkeleton()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("This Week Card Skeleton")
                .font(.headline)
            ThisWeekCardSkeleton()

            Text("Timeline Skeleton")
                .font(.headline)
            SocializationTimelineSkeleton()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("AI Insight Card Skeleton")
                .font(.headline)
            AIInsightCardSkeleton()
                .padding()
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("Morning Briefing Skeleton")
                .font(.headline)
            MorningBriefingSkeleton()
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("Weather Section Skeleton")
                .font(.headline)
            WeatherSectionSkeleton()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Recap Sheet Skeleton")
                .font(.headline)
            RecapSheetSkeleton()
                .padding()
        }
        .padding()
    }
}
