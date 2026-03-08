//
//  MonthlyGridCardView.swift
//  Otis-app
//
//  Shareable monthly growth grid card (1080x1080 square)
//

import SwiftUI
import OtisShared

/// A shareable square card showing monthly growth in a grid layout
/// Designed for social media sharing at 1080x1080 resolution
struct MonthlyGridCardView: View {
    let puppyName: String
    let photos: [GrowthPhotoSelection]
    let growthSummary: String?  // e.g., "1.2 kg → 8.0 kg (6.7x)"
    let weightUnit: WeightUnit

    // Card dimensions (1:1 square for social media)
    private let cardSize = CGSize(width: 1080, height: 1080)

    /// Grid layout based on photo count
    private var gridColumns: [GridItem] {
        let photoCount = photos.count
        if photoCount <= 3 {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: photoCount)
        } else {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
        }
    }

    /// Photo size based on count
    private var photoSize: CGFloat {
        let photoCount = photos.count
        if photoCount <= 3 {
            return 280
        } else {
            return 260
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 32) {
                Spacer()

                // Title
                titleSection

                // Photo grid
                photoGrid

                // Growth summary
                if let summary = growthSummary {
                    summaryBadge(text: summary)
                }

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
                Color.otisAccent.opacity(0.25),
                Color.otisPurple.opacity(0.1),
                Color(UIColor.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Title Section

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(Strings.GrowthCards.firstMonthsTitle(name: puppyName, months: photos.count))
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                Text(Strings.GrowthCards.monthlyGrowth)
                    .font(.system(size: 22, weight: .medium))
            }
            .foregroundStyle(Color.otisPurple)
        }
    }

    // MARK: - Photo Grid

    @ViewBuilder
    private var photoGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(photos) { selection in
                photoCell(selection: selection)
            }
        }
    }

    @ViewBuilder
    private func photoCell(selection: GrowthPhotoSelection) -> some View {
        VStack(spacing: 8) {
            GrowthSharePhoto(event: selection.event)
                .frame(width: photoSize, height: photoSize)

            VStack(spacing: 2) {
                Text(Strings.GrowthCards.monthLabel(selection.ageMonths))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                if let weight = selection.weight {
                    Text(weightUnit.format(weight))
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Summary Badge

    @ViewBuilder
    private func summaryBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(Color.otisPurple)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.otisPurple.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Branding

    @ViewBuilder
    private var branding: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 18))
                Text("ollie.pet")
                    .font(.system(size: 20, weight: .medium))
            }
            .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Preview

#Preview("Monthly Grid - 6 Months") {
    let selections = (1...6).map { month in
        GrowthPhotoSelection(
            id: UUID(),
            event: PuppyEvent(time: Date(), type: .milestone),
            ageLabel: "\(month) months",
            ageWeeks: month * 4,
            ageMonths: month,
            weight: 1.5 + Double(month) * 1.2
        )
    }

    return MonthlyGridCardView(
        puppyName: "Max",
        photos: selections,
        growthSummary: "1.5 kg → 8.7 kg (5.8x)",
        weightUnit: .kg
    )
    .scaleEffect(0.35)
}

#Preview("Monthly Grid - 3 Months") {
    let selections = (1...3).map { month in
        GrowthPhotoSelection(
            id: UUID(),
            event: PuppyEvent(time: Date(), type: .milestone),
            ageLabel: "\(month) months",
            ageWeeks: month * 4,
            ageMonths: month,
            weight: 2.0 + Double(month) * 1.5
        )
    }

    return MonthlyGridCardView(
        puppyName: "Bella",
        photos: selections,
        growthSummary: "2.0 kg → 6.5 kg (3.3x)",
        weightUnit: .kg
    )
    .scaleEffect(0.35)
}
