//
//  WeekRecapTeaseCard.swift
//  Otis-app
//
//  Teaser card for Weekly Recap shown in TodayView
//  Shows on Sundays (week almost complete) or Mondays (your week recap is ready!)

import SwiftUI
import OtisShared

/// Card that teases the weekly recap feature
/// Appears on TodayView on Sundays/Mondays to encourage engagement
struct WeekRecapTeaseCard: View {
    let puppyName: String
    let photoEvents: [PuppyEvent]
    let stats: WeekSummaryStats?
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Whether this is showing as "ready" (Monday) or "preview" (Sunday)
    private var isRecapReady: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 2 // Monday
    }

    /// Up to 3 photo thumbnails
    private var displayPhotos: [PuppyEvent] {
        Array(photoEvents.prefix(3))
    }

    /// Quick stats summary
    private var statsSummary: String {
        guard let stats = stats else { return "" }

        var parts: [String] = []

        if stats.totalWalks > 0 {
            parts.append(Strings.Recap.walksCount(stats.totalWalks))
        }

        if stats.totalTrainingSessions > 0 {
            parts.append(Strings.Recap.trainingSessions(stats.totalTrainingSessions))
        }

        if stats.outdoorPottyPercentage >= 80 {
            parts.append(Strings.Recap.pottyOutdoors(stats.outdoorPottyPercentage))
        }

        return parts.prefix(2).joined(separator: " · ")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.body)
                        .foregroundStyle(Color.otisAccent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isRecapReady ? Strings.Recap.weekRecapReady : Strings.Recap.weekRecapTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if !isRecapReady {
                            Text(puppyName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
                            WeekPhotoThumbnail(event: event)
                        }

                        if photoEvents.count > 3 {
                            Text("+\(photoEvents.count - 3)")
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

                // Date range indicator
                if let stats = stats {
                    HStack {
                        Text(stats.dateRangeText)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        Text(Strings.Recap.viewWeekRecap)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.otisAccent)
                    }
                }
            }
            .padding(14)
            .glassCard(tint: .accent)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        if let stats = stats {
            return Strings.Recap.weekRecapAccessibilityLabel(
                dateRange: stats.dateRangeText,
                walks: stats.totalWalks,
                training: stats.totalTrainingSessions
            )
        }
        return isRecapReady ? Strings.Recap.weekRecapReady : "\(Strings.Recap.weekRecapTitle) \(puppyName)"
    }
}

// MARK: - Week Photo Thumbnail

private struct WeekPhotoThumbnail: View {
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

#Preview("Recap Ready (Monday)") {
    let sampleStats = WeekSummaryStats(
        weekStart: Date().addingTimeInterval(-7 * 24 * 60 * 60),
        weekEnd: Date(),
        puppyName: "Max",
        totalWalks: 14,
        totalWalkMinutes: 420,
        totalPottyEvents: 56,
        outdoorPottyCount: 52,
        totalTrainingSessions: 5,
        totalSocialEvents: 2,
        avgSleepHours: 10.5,
        photoCount: 8,
        dayStats: []
    )

    return VStack {
        WeekRecapTeaseCard(
            puppyName: "Max",
            photoEvents: [],
            stats: sampleStats,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}

#Preview("Week Almost Complete (Sunday)") {
    let sampleStats = WeekSummaryStats(
        weekStart: Date().addingTimeInterval(-6 * 24 * 60 * 60),
        weekEnd: Date(),
        puppyName: "Bella",
        totalWalks: 12,
        totalWalkMinutes: 360,
        totalPottyEvents: 48,
        outdoorPottyCount: 44,
        totalTrainingSessions: 4,
        totalSocialEvents: 1,
        avgSleepHours: 11.0,
        photoCount: 5,
        dayStats: []
    )

    return VStack {
        WeekRecapTeaseCard(
            puppyName: "Bella",
            photoEvents: [],
            stats: sampleStats,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}
