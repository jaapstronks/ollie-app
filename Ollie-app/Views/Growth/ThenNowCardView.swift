//
//  ThenNowCardView.swift
//  Otis-app
//
//  Shareable "Then vs Now" growth comparison card (1080x1080 square)
//

import SwiftUI
import OtisShared

/// A shareable square card comparing early and current photos
/// Designed for social media sharing at 1080x1080 resolution
struct ThenNowCardView: View {
    let puppyName: String
    let thenPhoto: GrowthPhotoSelection
    let nowPhoto: GrowthPhotoSelection
    let growthMultiplier: String?  // e.g., "2x", "3x"
    let weightUnit: WeightUnit

    // Card dimensions (1:1 square for social media)
    private let cardSize = CGSize(width: 1080, height: 1080)

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 40) {
                Spacer()

                // Title
                titleSection

                // Photo comparison
                photoComparison

                // Growth multiplier badge
                if let multiplier = growthMultiplier {
                    growthBadge(multiplier: multiplier)
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
                Color.otisAccent.opacity(0.3),
                Color.otisPurple.opacity(0.15),
                Color(UIColor.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Title Section

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(Strings.GrowthCards.growthStoryTitle(name: puppyName))
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                Text(Strings.GrowthCards.thenVsNow)
                    .font(.system(size: 24, weight: .medium))
            }
            .foregroundStyle(Color.otisPurple)
        }
    }

    // MARK: - Photo Comparison

    @ViewBuilder
    private var photoComparison: some View {
        HStack(spacing: 32) {
            // Then photo
            photoColumn(selection: thenPhoto, label: Strings.GrowthCards.then)

            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.otisPurple)

            // Now photo
            photoColumn(selection: nowPhoto, label: Strings.GrowthCards.now)
        }
    }

    @ViewBuilder
    private func photoColumn(selection: GrowthPhotoSelection, label: String) -> some View {
        VStack(spacing: 12) {
            GrowthSharePhoto(event: selection.event)
                .frame(width: 320, height: 320)

            Text(selection.ageLabel)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)

            if let weight = selection.weight {
                Text(weightUnit.format(weight))
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Growth Badge

    @ViewBuilder
    private func growthBadge(multiplier: String) -> some View {
        HStack(spacing: 8) {
            Text("✨")
                .font(.system(size: 32))
            Text(Strings.GrowthCards.growthCaption(multiplier: multiplier))
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.otisPurple, .otisAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("✨")
                .font(.system(size: 32))
        }
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

// MARK: - Growth Share Photo

struct GrowthSharePhoto: View {
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
        .cornerRadius(24)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.otisPurple.opacity(0.3), lineWidth: 4)
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

// MARK: - Preview

#Preview("Then vs Now") {
    let thenEvent = PuppyEvent(
        time: Date().addingTimeInterval(-90 * 24 * 3600),
        type: .milestone,
        photo: nil
    )
    let nowEvent = PuppyEvent(
        time: Date(),
        type: .milestone,
        photo: nil
    )

    let thenSelection = GrowthPhotoSelection(
        id: UUID(),
        event: thenEvent,
        ageLabel: "8 weeks",
        ageWeeks: 8,
        ageMonths: 2,
        weight: 2.5
    )

    let nowSelection = GrowthPhotoSelection(
        id: UUID(),
        event: nowEvent,
        ageLabel: "5 months",
        ageWeeks: 20,
        ageMonths: 5,
        weight: 8.5
    )

    return ThenNowCardView(
        puppyName: "Max",
        thenPhoto: thenSelection,
        nowPhoto: nowSelection,
        growthMultiplier: "3.4x",
        weightUnit: .kg
    )
    .scaleEffect(0.35)
}
