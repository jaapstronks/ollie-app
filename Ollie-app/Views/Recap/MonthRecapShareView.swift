//
//  MonthRecapShareView.swift
//  Otis-app
//
//  Shareable card view for monthly recaps (1080x1080 square)

import SwiftUI
import OtisShared

/// A shareable square card for monthly recaps
/// Designed for social media sharing at 1080x1080 resolution
struct MonthRecapShareView: View {
    let stats: MonthSummaryStats
    let photoEvents: [PuppyEvent]

    // Card dimensions (1:1 square for social media)
    private let cardSize = CGSize(width: 1080, height: 1080)

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 40) {
                Spacer()

                // Title section
                titleSection

                // Photo grid (2x2)
                if !photoEvents.isEmpty {
                    photoGrid
                }

                // Stats row
                statsRow

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
                Color.otisAccent.opacity(0.2),
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
            // Month
            Text(stats.monthName)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Puppy name with paw
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                Text("\(Strings.Recap.monthWith) \(stats.puppyName)")
                    .font(.system(size: 28, weight: .semibold))
            }
            .foregroundStyle(Color.otisAccent)
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
                SharePhotoItem(event: event)
                    .frame(height: gridSize / 2 - 6)
            }
        }
        .frame(width: gridSize, height: gridSize)
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 48) {
            ShareStatItem(
                icon: "figure.walk",
                value: "\(stats.totalWalks)",
                label: "walks",
                color: .otisInfo
            )

            ShareStatItem(
                icon: "graduationcap.fill",
                value: "\(stats.totalTrainingSessions)",
                label: "training",
                color: .otisPurple
            )

            ShareStatItem(
                icon: "dog.fill",
                value: "\(stats.totalSocialEvents)",
                label: "social",
                color: .otisAccent
            )
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

private struct SharePhotoItem: View {
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

private struct ShareStatItem: View {
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
    let sampleStats = MonthSummaryStats(
        month: Date(),
        puppyName: "Max",
        totalWalks: 45,
        totalWalkMinutes: 1350,
        totalPottyEvents: 120,
        outdoorPottyCount: 115,
        totalTrainingSessions: 22,
        totalSocialEvents: 8,
        photoCount: 15,
        dayStats: []
    )

    return MonthRecapShareView(
        stats: sampleStats,
        photoEvents: []
    )
    .scaleEffect(0.35)
}

#Preview("No Photos") {
    let sampleStats = MonthSummaryStats(
        month: Date(),
        puppyName: "Bella",
        totalWalks: 38,
        totalWalkMinutes: 1140,
        totalPottyEvents: 98,
        outdoorPottyCount: 90,
        totalTrainingSessions: 18,
        totalSocialEvents: 5,
        photoCount: 0,
        dayStats: []
    )

    return MonthRecapShareView(
        stats: sampleStats,
        photoEvents: []
    )
    .scaleEffect(0.35)
}
