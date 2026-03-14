//
//  GotchaDayCard.swift
//  Otis-app
//
//  Anniversary celebration card for Gotcha Day (adoption anniversary)

import SwiftUI
import OtisShared

/// Card displayed on the gotcha day anniversary
/// Shows celebration UI and lifetime stats with option to share
struct GotchaDayCard: View {
    let stats: GotchaDayStats
    let firstDayPhoto: PuppyEvent?
    let latestPhoto: PuppyEvent?
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with party theme
                HStack(spacing: 8) {
                    Text("🎉")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Recap.gotchaDayTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(stats.anniversaryText)
                            .font(.caption)
                            .foregroundStyle(Color.otisPurple)
                    }

                    Spacer()

                    // Share indicator
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundStyle(Color.otisAccent)
                }

                // Then vs Now photo comparison (if available)
                if firstDayPhoto != nil || latestPhoto != nil {
                    HStack(spacing: 12) {
                        if let firstDay = firstDayPhoto {
                            VStack(spacing: 4) {
                                GotchaDayPhotoThumbnail(event: firstDay)
                                Text(Strings.Recap.thenLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if firstDayPhoto != nil && latestPhoto != nil {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        if let latest = latestPhoto {
                            VStack(spacing: 4) {
                                GotchaDayPhotoThumbnail(event: latest)
                                Text(Strings.Recap.nowLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                }

                // Quick stats
                HStack(spacing: 16) {
                    MiniStat(
                        icon: "figure.walk",
                        value: "\(stats.totalWalks)",
                        label: Strings.Recap.walks,
                        color: .otisInfo
                    )

                    MiniStat(
                        icon: "camera.fill",
                        value: "\(stats.totalPhotos)",
                        label: Strings.Recap.photos,
                        color: .otisPurple
                    )

                    MiniStat(
                        icon: "graduationcap.fill",
                        value: "\(stats.totalTrainingSessions)",
                        label: Strings.Recap.training,
                        color: .otisAccent
                    )
                }

                // Home date
                HStack {
                    Text(Strings.Recap.cameHome(stats.shortHomeDate))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Text(Strings.Recap.shareCelebration)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.otisPurple)
                }
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [
                        Color.otisPurple.opacity(0.15),
                        Color(UIColor.secondarySystemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.otisPurple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Recap.gotchaDayAccessibilityLabel(
            years: stats.yearsHome,
            name: stats.puppyName
        ))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Mini Stat

private struct MiniStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)

                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Gotcha Day Photo Thumbnail

private struct GotchaDayPhotoThumbnail: View {
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
        .frame(width: 56, height: 56)
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

#Preview("First Anniversary") {
    let sampleStats = GotchaDayStats(
        homeDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
        puppyName: "Max",
        yearsHome: 1,
        totalWalks: 365,
        totalWalkMinutes: 10950,
        totalPhotos: 150,
        totalTrainingSessions: 100,
        totalSocialEvents: 50,
        skillsMastered: 12,
        totalPottyEvents: 2500,
        outdoorPottyCount: 2400
    )

    return VStack {
        GotchaDayCard(
            stats: sampleStats,
            firstDayPhoto: nil,
            latestPhoto: nil,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}

#Preview("Second Anniversary") {
    let sampleStats = GotchaDayStats(
        homeDate: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
        puppyName: "Bella",
        yearsHome: 2,
        totalWalks: 730,
        totalWalkMinutes: 21900,
        totalPhotos: 300,
        totalTrainingSessions: 180,
        totalSocialEvents: 100,
        skillsMastered: 18,
        totalPottyEvents: 5000,
        outdoorPottyCount: 4900
    )

    return VStack {
        GotchaDayCard(
            stats: sampleStats,
            firstDayPhoto: nil,
            latestPhoto: nil,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}
