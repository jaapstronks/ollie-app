//
//  GrowthCardCreatorSheet.swift
//  Otis-app
//
//  Sheet for creating and sharing growth comparison cards
//

import SwiftUI
import OtisShared

/// Card type selection for growth cards
enum GrowthCardType: String, CaseIterable, Identifiable {
    case thenVsNow
    case monthlyGrid
    case weightChart

    var id: String { rawValue }

    var label: String {
        switch self {
        case .thenVsNow: return Strings.GrowthCards.thenVsNow
        case .monthlyGrid: return Strings.GrowthCards.monthlyGrowth
        case .weightChart: return Strings.GrowthCards.growthChart
        }
    }

    var icon: String {
        switch self {
        case .thenVsNow: return "arrow.left.and.right.square"
        case .monthlyGrid: return "square.grid.2x2"
        case .weightChart: return "chart.line.uptrend.xyaxis"
        }
    }
}

/// Sheet for creating growth shareable cards
struct GrowthCardCreatorSheet: View {
    @Environment(WeightStore.self) var weightStore
    @Environment(EventStore.self) var eventStore
    @Environment(ProfileStore.self) var profileStore

    @Environment(\.dismiss) private var dismiss

    @State private var cardType: GrowthCardType = .thenVsNow
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    @State private var isRendering = false

    /// PERFORMANCE: Cached photo events loaded asynchronously
    @State private var allPhotosCache: [PuppyEvent] = []
    @State private var isLoadingPhotos = true

    // Photo selector
    private let photoSelector = GrowthPhotoSelector()

    @EnvironmentObject var unitPreferences: UnitPreferences

    private var weightUnit: WeightUnit {
        unitPreferences.weightUnit
    }

    private var profile: PuppyProfile? {
        profileStore.activeProfile
    }

    // MARK: - Computed Properties

    /// PERFORMANCE: Use cached photos instead of synchronous Core Data fetch
    private var allPhotos: [PuppyEvent] {
        allPhotosCache
    }

    private var thenNowPair: (then: GrowthPhotoSelection, now: GrowthPhotoSelection)? {
        guard let birthDate = profile?.birthDate else { return nil }
        return photoSelector.findThenNowPair(
            from: allPhotos,
            birthDate: birthDate,
            measurements: weightStore.measurements
        )
    }

    private var monthlyPhotos: [GrowthPhotoSelection] {
        guard let birthDate = profile?.birthDate else { return [] }
        return photoSelector.findMonthlyPhotos(
            from: allPhotos,
            birthDate: birthDate,
            measurements: weightStore.measurements,
            maxMonths: 6
        )
    }

    private var chartPoints: [WeightChartPoint] {
        guard let birthDate = profile?.birthDate else { return [] }
        return weightStore.chartPoints(birthDate: birthDate)
    }

    private var growthStory: GrowthStory? {
        guard let profile = profile else { return nil }
        return weightStore.growthStory(
            homeDate: profile.homeDate,
            sizeCategory: profile.sizeCategory
        )
    }

    private var canCreateSelectedCard: Bool {
        // Don't show empty state while still loading
        if isLoadingPhotos && (cardType == .thenVsNow || cardType == .monthlyGrid) {
            return true // Will show loading state instead
        }
        switch cardType {
        case .thenVsNow:
            return thenNowPair != nil
        case .monthlyGrid:
            return monthlyPhotos.count >= 2
        case .weightChart:
            return chartPoints.count >= 2
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Card type picker
                cardTypePicker
                    .padding()

                Divider()

                // Preview or empty state
                ScrollView {
                    if canCreateSelectedCard {
                        previewSection
                    } else {
                        emptyStateView
                    }
                }

                Divider()

                // Share button
                shareButton
                    .padding()
            }
            .navigationTitle(Strings.GrowthCards.createGrowthCard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = renderedImage {
                ShareSheet(activityItems: [image])
            }
        }
        .task {
            // PERFORMANCE: Load photos asynchronously to avoid blocking main thread
            isLoadingPhotos = true
            let endDate = Date()
            let startDate = profile?.homeDate ?? Calendar.current.date(byAdding: .year, value: -2, to: endDate)!
            allPhotosCache = await eventStore.getEventsWithMediaAsync(from: startDate, to: endDate)
            isLoadingPhotos = false
        }
    }

    // MARK: - Card Type Picker

    @ViewBuilder
    private var cardTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.GrowthCards.cardType)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(Strings.GrowthCards.cardType, selection: $cardType) {
                ForEach(GrowthCardType.allCases) { type in
                    Label(type.label, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text(Strings.GrowthCards.shareGrowth)
                .font(.headline)
                .padding(.top)

            // Scaled preview of the card
            Group {
                switch cardType {
                case .thenVsNow:
                    if let pair = thenNowPair {
                        ThenNowCardView(
                            puppyName: profile?.name ?? "",
                            thenPhoto: pair.then,
                            nowPhoto: pair.now,
                            growthMultiplier: growthStory?.formattedMultiplier,
                            weightUnit: weightUnit
                        )
                        .scaleEffect(0.32)
                        .frame(width: 345, height: 345)
                    }

                case .monthlyGrid:
                    let summary = makeSummary()
                    MonthlyGridCardView(
                        puppyName: profile?.name ?? "",
                        photos: monthlyPhotos,
                        growthSummary: summary,
                        weightUnit: weightUnit
                    )
                    .scaleEffect(0.32)
                    .frame(width: 345, height: 345)

                case .weightChart:
                    if let story = growthStory {
                        GrowthChartCardView(
                            puppyName: profile?.name ?? "",
                            chartPoints: chartPoints,
                            startWeight: story.firstWeight,
                            currentWeight: story.currentWeight,
                            growthMultiplier: story.formattedMultiplier,
                            weightUnit: weightUnit
                        )
                        .scaleEffect(0.25)
                        .frame(width: 270, height: 338)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: cardType.icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var emptyStateMessage: String {
        switch cardType {
        case .thenVsNow:
            return Strings.GrowthCards.needMorePhotos
        case .monthlyGrid:
            return Strings.GrowthCards.needMorePhotos
        case .weightChart:
            return Strings.GrowthCards.noWeightData
        }
    }

    // MARK: - Share Button

    @ViewBuilder
    private var shareButton: some View {
        Button {
            generateAndShare()
        } label: {
            HStack {
                if isRendering {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(Strings.GrowthCards.share)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canCreateSelectedCard ? Color.otisAccent : Color.gray)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(!canCreateSelectedCard || isRendering)
    }

    // MARK: - Helper Methods

    private func makeSummary() -> String? {
        guard let story = growthStory else { return nil }
        let startFormatted = weightUnit.format(story.firstWeight)
        let currentFormatted = weightUnit.format(story.currentWeight)
        let gain = weightUnit.format(story.currentWeight - story.firstWeight)
        return Strings.GrowthCards.weightGain(
            startWeight: startFormatted,
            currentWeight: currentFormatted,
            gain: gain
        )
    }

    private func generateAndShare() {
        isRendering = true

        // Create the card view for rendering
        let cardView: AnyView

        switch cardType {
        case .thenVsNow:
            guard let pair = thenNowPair else { return }
            cardView = AnyView(
                ThenNowCardView(
                    puppyName: profile?.name ?? "",
                    thenPhoto: pair.then,
                    nowPhoto: pair.now,
                    growthMultiplier: growthStory?.formattedMultiplier,
                    weightUnit: weightUnit
                )
            )

        case .monthlyGrid:
            cardView = AnyView(
                MonthlyGridCardView(
                    puppyName: profile?.name ?? "",
                    photos: monthlyPhotos,
                    growthSummary: makeSummary(),
                    weightUnit: weightUnit
                )
            )

        case .weightChart:
            guard let story = growthStory else { return }
            cardView = AnyView(
                GrowthChartCardView(
                    puppyName: profile?.name ?? "",
                    chartPoints: chartPoints,
                    startWeight: story.firstWeight,
                    currentWeight: story.currentWeight,
                    growthMultiplier: story.formattedMultiplier,
                    weightUnit: weightUnit
                )
            )
        }

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
            showShareSheet = true
        }

        isRendering = false
    }
}

// MARK: - Preview

#Preview {
    GrowthCardCreatorSheet()
        .environment(WeightStore())
        .environment(EventStore())
        .environment(ProfileStore())
}
