//
//  WeekRecapSheet.swift
//  Otis-app
//
//  Full weekly recap sheet with stats, photos, and sharing

import SwiftUI
import OtisShared

/// Full-screen sheet showing weekly statistics and moments
struct WeekRecapSheet: View {
    @Bindable var viewModel: WeekRecapViewModel
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week picker
                    weekPicker

                    if let stats = viewModel.currentStats {
                        // Stats overview
                        statsSection(stats)

                        // Photo grid
                        photoGridSection

                        // Day breakdown
                        dayBreakdownSection(stats)
                    } else if viewModel.isLoading {
                        RecapSheetSkeleton()
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Recap.weekSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        onDismiss()
                    }
                }

                if viewModel.currentStats != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            generateAndShare()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
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

    // MARK: - Week Picker

    @ViewBuilder
    private var weekPicker: some View {
        HStack {
            Button {
                viewModel.goToPreviousWeek()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel(Strings.Recap.previousWeek)

            Spacer()

            Text(viewModel.currentStats?.dateRangeText ?? "")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                viewModel.goToNextWeek()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(viewModel.canGoToNextWeek ? .primary : .tertiary)
            }
            .disabled(!viewModel.canGoToNextWeek)
            .accessibilityLabel(Strings.Recap.nextWeek)
        }
        .padding(.horizontal)
    }

    // MARK: - Stats Section

    @ViewBuilder
    private func statsSection(_ stats: WeekSummaryStats) -> some View {
        VStack(spacing: 16) {
            // Primary stats row
            HStack(spacing: 20) {
                StatBox(
                    icon: "figure.walk",
                    value: "\(stats.totalWalks)",
                    label: Strings.Recap.walksCount(stats.totalWalks),
                    color: .otisInfo
                )

                StatBox(
                    icon: "graduationcap.fill",
                    value: "\(stats.totalTrainingSessions)",
                    label: Strings.Recap.trainingSessions(stats.totalTrainingSessions),
                    color: .otisPurple
                )

                StatBox(
                    icon: "checkmark.circle.fill",
                    value: "\(stats.outdoorPottyPercentage)%",
                    label: Strings.Recap.outdoors,
                    color: .otisSuccess
                )
            }

            // Secondary stats
            HStack(spacing: 16) {
                if stats.totalSocialEvents > 0 {
                    MiniStat(
                        label: Strings.Recap.socialMeetups(stats.totalSocialEvents),
                        icon: "dog.fill",
                        color: .otisAccent
                    )
                }

                if stats.totalWalkMinutes > 0 {
                    MiniStat(
                        label: Strings.Recap.totalTime(stats.formattedWalkDuration),
                        icon: "clock.fill",
                        color: .otisInfo
                    )
                }

                MiniStat(
                    label: Strings.Recap.avgSleep(stats.formattedAvgSleep),
                    icon: "moon.fill",
                    color: .secondary
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Photo Grid

    @ViewBuilder
    private var photoGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Strings.Recap.moments)
                    .font(.headline)

                Spacer()

                if !viewModel.photoEvents.isEmpty {
                    Text(Strings.Recap.photoCount(viewModel.photoEvents.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.displayPhotos.isEmpty {
                Text(Strings.Recap.noPhotosThisWeek)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // 2x3 grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(viewModel.displayPhotos) { event in
                        WeekPhotoGridItem(event: event)
                    }
                }
            }
        }
    }

    // MARK: - Day Breakdown

    @ViewBuilder
    private func dayBreakdownSection(_ stats: WeekSummaryStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Recap.dailyActivity)
                .font(.headline)

            // Day-by-day activity dots
            HStack(spacing: 8) {
                ForEach(stats.dayStats) { day in
                    VStack(spacing: 4) {
                        let hasActivity = day.walks > 0 || day.trainingSessions > 0
                        Circle()
                            .fill(hasActivity ? Color.otisAccent : Color.secondary.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay {
                                if day.walks > 0 {
                                    Text("\(day.walks)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }

                        Text(day.shortDateLabel)
                            .font(.caption2)
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

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(Strings.Recap.noDataThisWeek)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Sharing

    private func generateAndShare() {
        guard let stats = viewModel.currentStats else { return }

        let shareView = WeekRecapShareView(
            stats: stats,
            photoEvents: viewModel.shareCardPhotos
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

private struct StatBox: View {
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
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MiniStat: View {
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WeekPhotoGridItem: View {
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
        .frame(height: 120)
        .cornerRadius(12)
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

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = WeekRecapViewModel(eventStore: eventStore, profileStore: profileStore)

    return WeekRecapSheet(
        viewModel: viewModel,
        onDismiss: { print("Dismiss") }
    )
}
