//
//  ShareCardGenerator.swift
//  Ollie-app
//
//  Generates shareable images from achievements
//  Uses ImageRenderer to convert SwiftUI views to UIImage

import SwiftUI
import OllieShared
import os

/// Generates shareable images for achievements
@MainActor
final class ShareCardGenerator {

    private let logger = Logger.ollie(category: "ShareCardGenerator")

    // MARK: - Singleton

    static let shared = ShareCardGenerator()

    private init() {}

    // MARK: - Generation

    /// Generate a share card image for an achievement
    /// - Parameters:
    ///   - achievement: The achievement to generate a card for
    ///   - puppyName: The puppy's name
    ///   - puppyPhoto: Optional puppy photo
    ///   - achievementDate: The date of the achievement
    ///   - aspectRatio: The aspect ratio for the card
    /// - Returns: A UIImage of the share card, or nil if generation fails
    func generateCard(
        achievement: Achievement,
        puppyName: String,
        puppyPhoto: UIImage? = nil,
        achievementDate: Date = Date(),
        aspectRatio: ShareCardAspectRatio = .square
    ) -> UIImage? {
        let view = ShareCardView(
            achievement: achievement,
            puppyName: puppyName,
            puppyPhoto: puppyPhoto,
            achievementDate: achievementDate,
            aspectRatio: aspectRatio
        )

        let renderer = ImageRenderer(content: view)

        // Configure renderer for high quality output
        renderer.scale = 2.0  // 2x for retina
        renderer.isOpaque = true

        guard let image = renderer.uiImage else {
            logger.error("Failed to generate share card image")
            return nil
        }

        logger.debug("Generated share card: \(aspectRatio.rawValue) for \(achievement.id)")
        return image
    }

    /// Generate all aspect ratio variants for an achievement
    /// - Parameters:
    ///   - achievement: The achievement to generate cards for
    ///   - puppyName: The puppy's name
    ///   - puppyPhoto: Optional puppy photo
    ///   - achievementDate: The date of the achievement
    /// - Returns: Dictionary of aspect ratio to UIImage
    func generateAllCards(
        achievement: Achievement,
        puppyName: String,
        puppyPhoto: UIImage? = nil,
        achievementDate: Date = Date()
    ) -> [ShareCardAspectRatio: UIImage] {
        var cards: [ShareCardAspectRatio: UIImage] = [:]

        for aspectRatio in ShareCardAspectRatio.allCases {
            if let image = generateCard(
                achievement: achievement,
                puppyName: puppyName,
                puppyPhoto: puppyPhoto,
                achievementDate: achievementDate,
                aspectRatio: aspectRatio
            ) {
                cards[aspectRatio] = image
            }
        }

        return cards
    }

    // MARK: - Sharing

    /// Create a share sheet with the generated card
    /// - Parameters:
    ///   - achievement: The achievement to share
    ///   - puppyName: The puppy's name
    ///   - puppyPhoto: Optional puppy photo
    ///   - aspectRatio: The aspect ratio to use
    /// - Returns: A UIActivityViewController configured for sharing
    func createShareSheet(
        achievement: Achievement,
        puppyName: String,
        puppyPhoto: UIImage? = nil,
        aspectRatio: ShareCardAspectRatio = .square
    ) -> UIActivityViewController? {
        guard let image = generateCard(
            achievement: achievement,
            puppyName: puppyName,
            puppyPhoto: puppyPhoto,
            aspectRatio: aspectRatio
        ) else {
            return nil
        }

        let text = "\(puppyName) \(achievement.localizedLabel)! 🎉"

        let activityVC = UIActivityViewController(
            activityItems: [image, text],
            applicationActivities: nil
        )

        // Exclude some activities that don't make sense
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]

        return activityVC
    }
}

// MARK: - SwiftUI Share Sheet Helper

/// A view that presents a share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?

    init(
        activityItems: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) {
        self.activityItems = activityItems
        self.excludedActivityTypes = excludedActivityTypes
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View Extension for Easy Sharing

extension View {
    /// Present a share sheet for an achievement
    func shareSheet(
        isPresented: Binding<Bool>,
        achievement: Achievement,
        puppyName: String,
        puppyPhoto: UIImage? = nil
    ) -> some View {
        sheet(isPresented: isPresented) {
            if let image = ShareCardGenerator.shared.generateCard(
                achievement: achievement,
                puppyName: puppyName,
                puppyPhoto: puppyPhoto
            ) {
                let text = "\(puppyName) \(achievement.localizedLabel)! 🎉"
                ShareSheet(
                    activityItems: [image, text],
                    excludedActivityTypes: [.assignToContact, .addToReadingList]
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
}
