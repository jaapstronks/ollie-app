//
//  YearRecapView.swift
//  Otis-app
//
//  Full Year in Review sheet with statistics, photos, and growth journey

import SwiftUI
import OtisShared

/// Full-screen sheet showing year-end statistics and moments
struct YearRecapView: View {
    @ObservedObject var viewModel: YearRecapViewModel
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Year picker
                    yearPicker

                    if let recap = viewModel.recap {
                        // Year title
                        yearTitle(recap)

                        // Stats overview
                        statsSection(recap.stats)

                        // Monthly highlights carousel
                        if recap.monthHighlights.contains(where: { $0.hasData }) {
                            monthlyHighlightsSection(recap.monthHighlights)
                        }

                        // Photo grid
                        if !viewModel.displayPhotos.isEmpty {
                            photoGridSection
                        }

                        // Top moments
                        if !recap.topMoments.isEmpty {
                            topMomentsSection(recap.topMoments)
                        }

                        // Growth journey
                        if let journey = recap.growthJourney, journey.hasData {
                            growthJourneySection(journey)
                        }
                    } else if viewModel.isLoading {
                        ProgressView()
                            .padding(.vertical, 40)
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Recap.yearRecapTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        onDismiss()
                    }
                }

                if viewModel.recap != nil {
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

    // MARK: - Year Picker

    @ViewBuilder
    private var yearPicker: some View {
        HStack {
            Button {
                viewModel.goToPreviousYear()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(viewModel.canGoToPreviousYear ? .primary : .tertiary)
            }
            .disabled(!viewModel.canGoToPreviousYear)

            Spacer()

            Text("\(String(viewModel.selectedYear))")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            Button {
                viewModel.goToNextYear()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(viewModel.canGoToNextYear ? .primary : .tertiary)
            }
            .disabled(!viewModel.canGoToNextYear)
        }
        .padding(.horizontal)
    }

    // MARK: - Year Title

    @ViewBuilder
    private func yearTitle(_ recap: YearRecap) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(Color.otisPurple)

            Text(Strings.Recap.yearWithName(name: recap.puppyName))
                .font(.title2)
                .fontWeight(.semibold)

            Text(Strings.Recap.yearJourney(year: recap.year))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 8)
    }

    // MARK: - Stats Section

    @ViewBuilder
    private func statsSection(_ stats: YearStats) -> some View {
        VStack(spacing: 16) {
            // Primary stats row
            HStack(spacing: 16) {
                YearStatBox(
                    icon: "figure.walk",
                    value: "\(stats.totalWalks)",
                    label: Strings.Recap.walks,
                    color: .otisInfo
                )

                YearStatBox(
                    icon: "clock.fill",
                    value: stats.formattedWalkHours,
                    label: Strings.Recap.hours,
                    color: .otisAccent
                )

                YearStatBox(
                    icon: "camera.fill",
                    value: "\(stats.photoCount)",
                    label: Strings.Recap.photos,
                    color: .otisPurple
                )
            }

            // Secondary stats row
            HStack(spacing: 16) {
                YearStatBox(
                    icon: "graduationcap.fill",
                    value: "\(stats.totalTrainingSessions)",
                    label: Strings.Recap.training,
                    color: .mint
                )

                YearStatBox(
                    icon: "dog.fill",
                    value: "\(stats.totalSocialEvents)",
                    label: Strings.Recap.social,
                    color: .orange
                )

                YearStatBox(
                    icon: "person.2.fill",
                    value: "\(stats.uniqueSocialContacts)",
                    label: Strings.Recap.friends,
                    color: .pink
                )
            }

            // Activity indicator
            HStack(spacing: 16) {
                MiniYearStat(
                    label: Strings.Recap.daysLogged(stats.daysLogged),
                    icon: "calendar",
                    color: .secondary
                )

                if stats.totalPottyEvents > 0 {
                    MiniYearStat(
                        label: Strings.Recap.pottyOutdoors(stats.outdoorPottyPercentage),
                        icon: "checkmark.circle.fill",
                        color: .otisSuccess
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Monthly Highlights

    @ViewBuilder
    private func monthlyHighlightsSection(_ highlights: [MonthHighlight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Recap.monthlyHighlights)
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(highlights.filter { $0.hasData }) { month in
                        MonthHighlightCard(highlight: month)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
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

            // 2x3 grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(viewModel.displayPhotos) { event in
                    YearPhotoGridItem(event: event)
                }
            }
        }
    }

    // MARK: - Top Moments

    @ViewBuilder
    private func topMomentsSection(_ moments: [TopMoment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Recap.topMoments)
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(moments) { moment in
                    TopMomentRow(moment: moment)
                }
            }
        }
    }

    // MARK: - Growth Journey

    @ViewBuilder
    private func growthJourneySection(_ journey: GrowthJourney) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Recap.growthJourney)
                .font(.headline)

            VStack(spacing: 12) {
                // Weight progress
                if let start = journey.startWeight, let end = journey.endWeight {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(Strings.Recap.startedAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f kg", start))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        if let gain = journey.formattedWeightGain {
                            Text(gain)
                                .font(.headline)
                                .foregroundStyle(Color.otisSuccess)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(Strings.Recap.endedAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f kg", end))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                // Weight chart
                if !journey.monthlyWeights.isEmpty {
                    WeightProgressChart(weights: journey.monthlyWeights)
                        .frame(height: 120)
                }
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(Strings.Recap.noDataThisYear)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Sharing

    private func generateAndShare() {
        guard let recap = viewModel.recap else { return }

        let shareView = YearRecapShareView(
            recap: recap,
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

private struct YearStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MiniYearStat: View {
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

private struct MonthHighlightCard: View {
    let highlight: MonthHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(highlight.shortMonthName)
                .font(.subheadline)
                .fontWeight(.semibold)

            if let caption = highlight.caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if highlight.walkCount > 0 {
                    StatPill(count: highlight.walkCount, icon: "figure.walk")
                }
                if highlight.trainingCount > 0 {
                    StatPill(count: highlight.trainingCount, icon: "graduationcap")
                }
                if highlight.socialCount > 0 {
                    StatPill(count: highlight.socialCount, icon: "dog")
                }
            }
        }
        .padding(12)
        .frame(width: 140)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct StatPill: View {
    let count: Int
    let icon: String

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(count)")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }
}

private struct TopMomentRow: View {
    let moment: TopMoment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForCategory(moment.category))
                .font(.title3)
                .foregroundStyle(colorForCategory(moment.category))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(moment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let subtitle = moment.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func iconForCategory(_ category: TopMomentCategory) -> String {
        switch category {
        case .bestFriend: return "heart.fill"
        case .favoriteSpot: return "mappin.circle.fill"
        case .biggestMilestone: return "star.fill"
        case .mostActiveMonth: return "flame.fill"
        case .longestStreak: return "trophy.fill"
        }
    }

    private func colorForCategory(_ category: TopMomentCategory) -> Color {
        switch category {
        case .bestFriend: return .pink
        case .favoriteSpot: return .blue
        case .biggestMilestone: return .yellow
        case .mostActiveMonth: return .orange
        case .longestStreak: return .purple
        }
    }
}

private struct YearPhotoGridItem: View {
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

private struct WeightProgressChart: View {
    let weights: [MonthWeight]

    var body: some View {
        GeometryReader { geometry in
            let maxWeight = weights.map(\.weightKg).max() ?? 1
            let minWeight = weights.map(\.weightKg).min() ?? 0
            let range = max(maxWeight - minWeight, 1)

            ZStack(alignment: .topLeading) {
                // Grid lines
                VStack {
                    ForEach(0..<4) { _ in
                        Divider()
                        Spacer()
                    }
                    Divider()
                }

                // Weight line
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(max(weights.count - 1, 1))

                    for (index, weight) in weights.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = (weight.weightKg - minWeight) / range
                        let y = height - (CGFloat(normalized) * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.otisPurple, lineWidth: 2)

                // Weight points
                ForEach(Array(weights.enumerated()), id: \.element.id) { index, weight in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(max(weights.count - 1, 1))
                    let x = CGFloat(index) * stepX
                    let normalized = (weight.weightKg - minWeight) / range
                    let y = height - (CGFloat(normalized) * height)

                    Circle()
                        .fill(Color.otisPurple)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let weightStore = WeightStore()
    let viewModel = YearRecapViewModel(
        eventStore: eventStore,
        profileStore: profileStore,
        weightStore: weightStore
    )

    return YearRecapView(
        viewModel: viewModel,
        onDismiss: { print("Dismiss") }
    )
}
