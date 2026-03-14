//
//  GotchaDaySheet.swift
//  Otis-app
//
//  Full Gotcha Day celebration sheet with stats, photos, and sharing

import SwiftUI
import OtisShared

/// Full-screen sheet showing gotcha day celebration and lifetime stats
struct GotchaDaySheet: View {
    let stats: GotchaDayStats
    let firstDayPhoto: PuppyEvent?
    let latestPhoto: PuppyEvent?
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration header
                    celebrationHeader

                    // Then vs Now comparison
                    if firstDayPhoto != nil || latestPhoto != nil {
                        photoComparison
                    }

                    // Lifetime stats
                    statsSection

                    // Journey timeline
                    journeySection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.otisPurple.opacity(0.1),
                        Color(UIColor.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle(Strings.Recap.gotchaDayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        generateAndShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
    }

    // MARK: - Celebration Header

    @ViewBuilder
    private var celebrationHeader: some View {
        VStack(spacing: 12) {
            // Party emoji banner
            HStack(spacing: 8) {
                Text("🎉")
                    .font(.system(size: 40))
                Text("🐕")
                    .font(.system(size: 40))
                Text("🎉")
                    .font(.system(size: 40))
            }

            // Anniversary text
            Text(stats.anniversaryText)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.otisPurple, .otisAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Puppy name
            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(Color.otisPurple)
                Text(stats.puppyName)
                    .fontWeight(.semibold)
            }
            .font(.title2)

            // Home date
            Text(Strings.Recap.cameHome(stats.formattedHomeDate))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    // MARK: - Photo Comparison

    @ViewBuilder
    private var photoComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Recap.thenLabel + " → " + Strings.Recap.nowLabel)
                .font(.headline)

            HStack(spacing: 16) {
                if let firstDay = firstDayPhoto {
                    VStack(spacing: 6) {
                        PhotoComparisonItem(event: firstDay)
                        Text(Strings.Recap.dayOne)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if firstDayPhoto != nil && latestPhoto != nil {
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundStyle(Color.otisPurple)
                }

                if let latest = latestPhoto {
                    VStack(spacing: 6) {
                        PhotoComparisonItem(event: latest)
                        Text(Strings.Recap.today)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Recap.lifetimeStats)
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "figure.walk",
                    value: "\(stats.totalWalks)",
                    label: Strings.Recap.walks,
                    color: .otisInfo
                )

                StatCard(
                    icon: "camera.fill",
                    value: "\(stats.totalPhotos)",
                    label: Strings.Recap.photos,
                    color: .otisPurple
                )

                StatCard(
                    icon: "graduationcap.fill",
                    value: "\(stats.totalTrainingSessions)",
                    label: Strings.Recap.training,
                    color: .otisAccent
                )

                StatCard(
                    icon: "dog.fill",
                    value: "\(stats.totalSocialEvents)",
                    label: Strings.Recap.friends,
                    color: .otisInfo
                )

                StatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(stats.outdoorPottyPercentage)%",
                    label: Strings.Recap.outdoors,
                    color: .otisSuccess
                )

                StatCard(
                    icon: "star.fill",
                    value: "\(stats.skillsMastered)",
                    label: Strings.Recap.skillsLearned,
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Journey Section

    @ViewBuilder
    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Recap.yourJourney)
                .font(.headline)

            VStack(spacing: 8) {
                JourneyRow(
                    icon: "house.fill",
                    text: Strings.Recap.cameHome(stats.shortHomeDate),
                    color: .otisPurple
                )

                JourneyRow(
                    icon: "calendar",
                    text: "\(stats.daysHome) \(Strings.Recap.daysTogetherLabel)",
                    color: .otisAccent
                )

                if stats.totalWalkMinutes > 0 {
                    JourneyRow(
                        icon: "figure.walk",
                        text: Strings.Recap.totalWalkTime(stats.formattedTotalWalkTime),
                        color: .otisInfo
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Sharing

    private func generateAndShare() {
        let shareView = GotchaDayShareView(
            stats: stats,
            firstDayPhoto: firstDayPhoto,
            latestPhoto: latestPhoto
        )

        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
        }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

private struct JourneyRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct PhotoComparisonItem: View {
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
                        ProgressView()
                    }
            }
        }
        .frame(width: 140, height: 140)
        .cornerRadius(16)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.otisPurple.opacity(0.3), lineWidth: 2)
        )
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

#Preview {
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

    return GotchaDaySheet(
        stats: sampleStats,
        firstDayPhoto: nil,
        latestPhoto: nil,
        onDismiss: { print("Dismiss") }
    )
}
