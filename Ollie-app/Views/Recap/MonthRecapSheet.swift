//
//  MonthRecapSheet.swift
//  Otis-app
//
//  Full monthly recap sheet with stats, photos, and sharing

import SwiftUI
import OtisShared

/// Full-screen sheet showing monthly statistics and moments
struct MonthRecapSheet: View {
    @ObservedObject var viewModel: MonthRecapViewModel
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Month picker
                    monthPicker

                    if let stats = viewModel.currentStats {
                        // Stats overview
                        statsSection(stats)

                        // Photo grid
                        photoGridSection

                        // Activity breakdown
                        activityBreakdownSection(stats)
                    } else if viewModel.isLoading {
                        RecapSheetSkeleton()
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Recap.sheetTitle)
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

    // MARK: - Month Picker

    @ViewBuilder
    private var monthPicker: some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(viewModel.canGoToPreviousMonth ? .primary : .tertiary)
            }
            .disabled(!viewModel.canGoToPreviousMonth)
            .accessibilityLabel(Strings.Recap.previousMonth)

            Spacer()

            Text(viewModel.currentStats?.monthName ?? "")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(viewModel.canGoToNextMonth ? .primary : .tertiary)
            }
            .disabled(!viewModel.canGoToNextMonth)
            .accessibilityLabel(Strings.Recap.nextMonth)
        }
        .padding(.horizontal)
    }

    // MARK: - Stats Section

    @ViewBuilder
    private func statsSection(_ stats: MonthSummaryStats) -> some View {
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
                    icon: "dog.fill",
                    value: "\(stats.totalSocialEvents)",
                    label: Strings.Recap.socialMeetups(stats.totalSocialEvents),
                    color: .otisAccent
                )
            }

            // Secondary stats
            HStack(spacing: 16) {
                if stats.totalPottyEvents > 0 {
                    MiniStat(
                        label: Strings.Recap.pottyOutdoors(stats.outdoorPottyPercentage),
                        icon: "checkmark.circle.fill",
                        color: .otisSuccess
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
                    label: Strings.Recap.daysWithWalks(stats.daysWithWalks, total: stats.daysInMonth),
                    icon: "calendar",
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
                Text(Strings.Recap.noPhotos)
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
                        PhotoGridItem(event: event)
                    }
                }
            }
        }
    }

    // MARK: - Activity Breakdown

    @ViewBuilder
    private func activityBreakdownSection(_ stats: MonthSummaryStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Week-by-week activity indicator
            weekActivityIndicator(stats)
        }
    }

    @ViewBuilder
    private func weekActivityIndicator(_ stats: MonthSummaryStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day-by-day activity dots
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(stats.dayStats.enumerated()), id: \.offset) { _, day in
                    let hasActivity = day.walks > 0 || day.trainingSessions > 0
                    Circle()
                        .fill(hasActivity ? Color.otisAccent : Color.secondary.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(Strings.Recap.noDataThisMonth)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Sharing

    private func generateAndShare() {
        guard let stats = viewModel.currentStats else { return }

        let shareView = MonthRecapShareView(
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

private struct PhotoGridItem: View {
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
    let viewModel = MonthRecapViewModel(eventStore: eventStore, profileStore: profileStore)

    return MonthRecapSheet(
        viewModel: viewModel,
        onDismiss: { print("Dismiss") }
    )
}
