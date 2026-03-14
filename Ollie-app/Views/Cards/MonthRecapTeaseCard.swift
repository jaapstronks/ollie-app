//
//  MonthRecapTeaseCard.swift
//  Otis-app
//
//  Teaser card for Monthly Recap shown in TodayView
//  Shows on days 28-31 ("Month almost complete") or days 1-3 ("Your recap is ready!")

import SwiftUI
import OtisShared

/// Card that teases the monthly recap feature
/// Appears on TodayView near month boundaries to encourage engagement
struct MonthRecapTeaseCard: View {
    let puppyName: String
    let photoEvents: [PuppyEvent]
    let stats: MonthSummaryStats?
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Whether this is showing as "ready" (start of month) or "preview" (end of month)
    private var isRecapReady: Bool {
        Date().isStartOfMonth
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

        if stats.totalSocialEvents > 0 {
            parts.append(Strings.Recap.socialMeetups(stats.totalSocialEvents))
        }

        return parts.prefix(2).joined(separator: " · ")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.body)
                        .foregroundStyle(Color.otisAccent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isRecapReady ? Strings.Recap.cardTitleReady : Strings.Recap.cardTitle)
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
                            PhotoThumbnail(event: event)
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

                // Month indicator
                if let stats = stats {
                    HStack {
                        Text(stats.monthName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        Text(Strings.Recap.viewRecap)
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
            return Strings.Recap.recapAccessibilityLabel(
                month: stats.monthName,
                walks: stats.totalWalks,
                training: stats.totalTrainingSessions
            )
        }
        return isRecapReady ? Strings.Recap.cardTitleReady : "\(Strings.Recap.cardTitle) \(puppyName)"
    }
}

// MARK: - Photo Thumbnail

private struct PhotoThumbnail: View {
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

#Preview("Recap Ready (Start of Month)") {
    let sampleStats = MonthSummaryStats(
        month: Date().previousMonth,
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

    return VStack {
        MonthRecapTeaseCard(
            puppyName: "Max",
            photoEvents: [],
            stats: sampleStats,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}

#Preview("Month Almost Complete") {
    let sampleStats = MonthSummaryStats(
        month: Date(),
        puppyName: "Bella",
        totalWalks: 38,
        totalWalkMinutes: 1140,
        totalPottyEvents: 98,
        outdoorPottyCount: 90,
        totalTrainingSessions: 18,
        totalSocialEvents: 5,
        photoCount: 12,
        dayStats: []
    )

    return VStack {
        MonthRecapTeaseCard(
            puppyName: "Bella",
            photoEvents: [],
            stats: sampleStats,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}
