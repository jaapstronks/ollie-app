//
//  GotchaDayShareView.swift
//  Otis-app
//
//  Shareable card view for Gotcha Day anniversary (1080x1080 square)

import SwiftUI
import OtisShared

/// A shareable square card for Gotcha Day anniversary
/// Designed for social media sharing at 1080x1080 resolution with festive theme
struct GotchaDayShareView: View {
    let stats: GotchaDayStats
    let firstDayPhoto: PuppyEvent?
    let latestPhoto: PuppyEvent?

    // Card dimensions (1:1 square for social media)
    private let cardSize = CGSize(width: 1080, height: 1080)

    var body: some View {
        ZStack {
            // Festive background gradient
            backgroundGradient

            VStack(spacing: 32) {
                Spacer()

                // Celebration header
                celebrationHeader

                // Then vs Now photo comparison
                if firstDayPhoto != nil || latestPhoto != nil {
                    photoComparison
                }

                // Anniversary headline
                anniversaryHeadline

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
                Color.otisPurple.opacity(0.3),
                Color.otisAccent.opacity(0.2),
                Color(UIColor.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Confetti-like overlay
            GeometryReader { geometry in
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(confettiColor(for: index))
                        .frame(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
                        .offset(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height * 0.3)
                        )
                        .opacity(0.6)
                }
            }
        )
    }

    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [.otisPurple, .otisAccent, .otisInfo, .yellow, .pink]
        return colors[index % colors.count]
    }

    // MARK: - Celebration Header

    @ViewBuilder
    private var celebrationHeader: some View {
        HStack(spacing: 8) {
            Text("🎉")
                .font(.system(size: 48))
            Text(Strings.Recap.gotchaDayTitle)
                .font(.system(size: 32, weight: .bold))
            Text("🎉")
                .font(.system(size: 48))
        }
    }

    // MARK: - Photo Comparison

    @ViewBuilder
    private var photoComparison: some View {
        HStack(spacing: 24) {
            if let firstDay = firstDayPhoto {
                VStack(spacing: 8) {
                    GotchaDaySharePhoto(event: firstDay)
                        .frame(width: 280, height: 280)

                    Text(Strings.Recap.dayOne)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            if firstDayPhoto != nil && latestPhoto != nil {
                Image(systemName: "arrow.right")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.otisPurple)
            }

            if let latest = latestPhoto {
                VStack(spacing: 8) {
                    GotchaDaySharePhoto(event: latest)
                        .frame(width: 280, height: 280)

                    Text(Strings.Recap.today)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Anniversary Headline

    @ViewBuilder
    private var anniversaryHeadline: some View {
        VStack(spacing: 8) {
            Text(stats.anniversaryText)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.otisPurple, .otisAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                Text(stats.puppyName)
                    .font(.system(size: 28, weight: .semibold))
            }
            .foregroundStyle(Color.otisPurple)
        }
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 48) {
            GotchaDayStatItem(
                icon: "figure.walk",
                value: "\(stats.totalWalks)",
                label: Strings.Recap.walks,
                color: .otisInfo
            )

            GotchaDayStatItem(
                icon: "camera.fill",
                value: "\(stats.totalPhotos)",
                label: Strings.Recap.photos,
                color: .otisPurple
            )

            GotchaDayStatItem(
                icon: "dog.fill",
                value: "\(stats.totalSocialEvents)",
                label: Strings.Recap.friends,
                color: .otisAccent
            )
        }
    }

    // MARK: - Branding

    @ViewBuilder
    private var branding: some View {
        HStack {
            Text(stats.shortHomeDate)
                .font(.system(size: 18))
                .foregroundStyle(.tertiary)

            Spacer()

            Text("ollie.pet")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Gotcha Day Share Photo

private struct GotchaDaySharePhoto: View {
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
        .cornerRadius(20)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.otisPurple.opacity(0.3), lineWidth: 3)
        )
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

// MARK: - Gotcha Day Stat Item

private struct GotchaDayStatItem: View {
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

    return GotchaDayShareView(
        stats: sampleStats,
        firstDayPhoto: nil,
        latestPhoto: nil
    )
    .scaleEffect(0.35)
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

    return GotchaDayShareView(
        stats: sampleStats,
        firstDayPhoto: nil,
        latestPhoto: nil
    )
    .scaleEffect(0.35)
}
