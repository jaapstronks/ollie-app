//
//  YearRecapTeaseCard.swift
//  Otis-app
//
//  Teaser card for Year in Review shown in TodayView
//  Shows December 15 - January 15 to encourage engagement

import SwiftUI
import OtisShared

/// Card that teases the year in review feature
/// Appears on TodayView near year boundaries
struct YearRecapTeaseCard: View {
    let puppyName: String
    let year: Int
    let photoEvents: [PuppyEvent]
    let stats: YearStats?
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Whether this is showing in January (recap ready) or December (preview)
    private var isRecapReady: Bool {
        Calendar.current.component(.month, from: Date()) == 1
    }

    /// Up to 4 photo thumbnails
    private var displayPhotos: [PuppyEvent] {
        Array(photoEvents.prefix(4))
    }

    /// Quick stats summary
    private var statsSummary: String {
        guard let stats = stats else { return "" }

        var parts: [String] = []

        if stats.totalWalks > 0 {
            parts.append(Strings.Recap.yearWalksCount(stats.totalWalks))
        }

        if stats.photoCount > 0 {
            parts.append(Strings.Recap.yearPhotosCount(stats.photoCount))
        }

        if stats.totalTrainingSessions > 0 {
            parts.append(Strings.Recap.yearTrainingCount(stats.totalTrainingSessions))
        }

        return parts.prefix(2).joined(separator: " · ")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundStyle(Color.otisPurple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isRecapReady ? Strings.Recap.yearRecapReady : Strings.Recap.yearInReview)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(Strings.Recap.yearWith(year: year, name: puppyName))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Photo thumbnails (if available)
                if !displayPhotos.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(displayPhotos) { event in
                            YearPhotoThumbnail(event: event)
                        }

                        if photoEvents.count > 4 {
                            Text("+\(photoEvents.count - 4)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }

                // Stats summary
                if !statsSummary.isEmpty {
                    Text(statsSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Year indicator
                HStack {
                    Text("\(String(year))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Text(Strings.Recap.viewYearRecap)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.otisPurple)
                }
            }
            .padding(14)
            .glassCard(tint: .custom(.otisPurple))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        if let stats = stats {
            return Strings.Recap.yearRecapAccessibilityLabel(
                year: year,
                walks: stats.totalWalks,
                photos: stats.photoCount
            )
        }
        return isRecapReady ? Strings.Recap.yearRecapReady : Strings.Recap.yearInReview
    }
}

// MARK: - Photo Thumbnail

private struct YearPhotoThumbnail: View {
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
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .frame(width: 44, height: 44)
        .cornerRadius(8)
        .clipped()
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let photoPath = event.photo else { return }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let imageURL = documentsURL?.appendingPathComponent(photoPath) else { return }

        if let data = try? Data(contentsOf: imageURL),
           let loadedImage = UIImage(data: data) {
            await MainActor.run {
                self.image = loadedImage
            }
        }
    }
}

// MARK: - Preview

#Preview("Year Recap Ready (January)") {
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

    return VStack {
        YearRecapTeaseCard(
            puppyName: "Max",
            year: 2025,
            photoEvents: [],
            stats: sampleStats,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}

#Preview("Year Preview (December)") {
    let sampleStats = YearStats(
        totalWalks: 480,
        totalWalkMinutes: 14400,
        totalMeals: 1000,
        totalSleepHours: 4000,
        totalTrainingSessions: 140,
        totalSocialEvents: 75,
        totalPottyEvents: 3400,
        outdoorPottyCount: 3300,
        photoCount: 220,
        milestoneCount: 10,
        uniqueSocialContacts: 30,
        daysLogged: 340
    )

    return VStack {
        YearRecapTeaseCard(
            puppyName: "Bella",
            year: 2025,
            photoEvents: [],
            stats: sampleStats,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}
