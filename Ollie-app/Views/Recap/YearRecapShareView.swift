//
//  YearRecapShareView.swift
//  Otis-app
//
//  Shareable card view for year recaps (1080x1080 square)

import SwiftUI
import OtisShared

/// A shareable square card for year recaps
/// Designed for social media sharing at 1080x1080 resolution
struct YearRecapShareView: View {
    let recap: YearRecap
    let photoEvents: [PuppyEvent]

    // Card dimensions (1:1 square for social media)
    private let cardSize = CGSize(width: 1080, height: 1080)

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 32) {
                Spacer()

                // Title section
                titleSection

                // Photo grid (2x2)
                if !photoEvents.isEmpty {
                    photoGrid
                }

                // Stats row
                statsRow

                // Journey summary
                if let journey = recap.growthJourney, journey.hasData {
                    journeySummary(journey)
                }

                Spacer()

                // Branding footer
                branding
            }
            .padding(48)
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.otisPurple.opacity(0.2),
                Color(UIColor.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Subtle pattern overlay
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }

    // MARK: - Title Section

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 16) {
            // Year with sparkle
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                Text("\(String(recap.year))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
            }
            .foregroundStyle(Color.otisPurple)

            // Puppy name with paw
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                Text(Strings.Recap.yearWith(year: recap.year, name: recap.puppyName))
                    .font(.system(size: 28, weight: .semibold))
            }
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Photo Grid

    @ViewBuilder
    private var photoGrid: some View {
        let displayPhotos = Array(photoEvents.prefix(4))
        let gridSize: CGFloat = 400

        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(displayPhotos) { event in
                ShareYearPhotoItem(event: event)
                    .frame(height: gridSize / 2 - 6)
            }
        }
        .frame(width: gridSize, height: gridSize)
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 48) {
            ShareYearStatItem(
                icon: "figure.walk",
                value: "\(recap.stats.totalWalks)",
                label: "walks",
                color: .otisInfo
            )

            ShareYearStatItem(
                icon: "camera.fill",
                value: "\(recap.stats.photoCount)",
                label: "photos",
                color: .otisPurple
            )

            ShareYearStatItem(
                icon: "dog.fill",
                value: "\(recap.stats.uniqueSocialContacts)",
                label: "friends",
                color: .orange
            )
        }
    }

    // MARK: - Journey Summary

    @ViewBuilder
    private func journeySummary(_ journey: GrowthJourney) -> some View {
        if let gain = journey.formattedWeightGain {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.green)
                Text(gain)
                    .font(.system(size: 24, weight: .medium))
                Text("grown")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Branding

    @ViewBuilder
    private var branding: some View {
        HStack {
            Spacer()
            Text("ollie.pet")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Share Photo Item

private struct ShareYearPhotoItem: View {
    let event: PuppyEvent

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
            }
        }
        .cornerRadius(16)
        .clipped()
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let photoPath = event.photo else { return }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let imageURL = documentsURL?.appendingPathComponent(photoPath),
              let data = try? Data(contentsOf: imageURL),
              let loadedImage = UIImage(data: data) else { return }

        image = loadedImage
    }
}

// MARK: - Share Stat Item

private struct ShareYearStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("With Photos") {
    let sampleStats = YearStats(
        totalWalks: 520,
        totalWalkMinutes: 15600,
        totalMeals: 1095,
        totalSleepHours: 4380,
        totalTrainingSessions: 156,
        totalSocialEvents: 89,
        totalPottyEvents: 3650,
        outdoorPottyCount: 3500,
        photoCount: 247,
        milestoneCount: 12,
        uniqueSocialContacts: 34,
        daysLogged: 365
    )

    let sampleJourney = GrowthJourney(
        monthlyWeights: [],
        startWeight: 5.2,
        endWeight: 12.8,
        totalGain: 7.6,
        phaseCompletions: []
    )

    let sampleRecap = YearRecap(
        year: 2025,
        puppyName: "Max",
        stats: sampleStats,
        monthHighlights: [],
        topMoments: [],
        growthJourney: sampleJourney
    )

    return YearRecapShareView(
        recap: sampleRecap,
        photoEvents: []
    )
    .scaleEffect(0.35)
}

#Preview("No Photos") {
    let sampleStats = YearStats(
        totalWalks: 480,
        totalWalkMinutes: 14400,
        totalMeals: 1000,
        totalSleepHours: 4000,
        totalTrainingSessions: 140,
        totalSocialEvents: 75,
        totalPottyEvents: 3400,
        outdoorPottyCount: 3300,
        photoCount: 0,
        milestoneCount: 10,
        uniqueSocialContacts: 30,
        daysLogged: 340
    )

    let sampleRecap = YearRecap(
        year: 2025,
        puppyName: "Bella",
        stats: sampleStats,
        monthHighlights: [],
        topMoments: [],
        growthJourney: nil
    )

    return YearRecapShareView(
        recap: sampleRecap,
        photoEvents: []
    )
    .scaleEffect(0.35)
}
