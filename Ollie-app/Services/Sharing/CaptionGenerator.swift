//
//  CaptionGenerator.swift
//  Otis-app
//
//  Generates captions and hashtags for shared content
//

import Foundation
import OtisShared

/// Generates captions and hashtags for shareable content
struct CaptionGenerator {

    // MARK: - Caption Generation

    /// Generate a complete caption for a card and platform
    /// - Parameters:
    ///   - card: The shareable card
    ///   - platform: The target platform
    /// - Returns: The complete caption including hashtags
    func generate<Card: ShareableCard>(
        for card: Card,
        platform: SharePlatform
    ) -> String {
        var caption = card.caption(for: platform)

        // Add hashtags based on platform preference
        let hashtags = generateHashtags(for: card, style: platform.hashtagStyle)
        if !hashtags.isEmpty {
            caption += "\n\n" + hashtags.joined(separator: " ")
        }

        return caption
    }

    /// Generate a simple caption with dog name and message
    func generateSimple(
        puppyName: String,
        message: String,
        platform: SharePlatform
    ) -> String {
        var caption = "\(puppyName) \(message)"

        let hashtags = generateDefaultHashtags(style: platform.hashtagStyle)
        if !hashtags.isEmpty {
            caption += "\n\n" + hashtags.joined(separator: " ")
        }

        return caption
    }

    // MARK: - Hashtag Generation

    private func generateHashtags<Card: ShareableCard>(
        for card: Card,
        style: SharePlatform.HashtagStyle
    ) -> [String] {
        var tags: [String] = []

        switch style {
        case .many:
            tags = buildManyHashtags(card: card)
        case .few:
            tags = buildFewHashtags(card: card)
        case .minimal:
            tags = ["#OllieApp"]
        }

        return tags
    }

    private func generateDefaultHashtags(
        style: SharePlatform.HashtagStyle
    ) -> [String] {
        switch style {
        case .many:
            return [
                "#OllieApp",
                "#PuppyLife",
                "#DogMom",
                "#PuppyLove",
                "#DogsOfInstagram"
            ]
        case .few:
            return ["#OllieApp", "#PuppyLife"]
        case .minimal:
            return ["#OllieApp"]
        }
    }

    private func buildManyHashtags<Card: ShareableCard>(card: Card) -> [String] {
        var tags = ["#OllieApp", "#PuppyLife"]

        // Add breed hashtag if available
        if let breed = card.profile.breed {
            let breedTag = "#" + breed.replacingOccurrences(of: " ", with: "")
            tags.append(breedTag)
        }

        // Add type-specific tags
        switch card.type {
        case .weeklyRecap, .monthlyRecap, .yearRecap:
            tags.append("#PuppyProgress")
        case .achievement:
            tags.append("#PuppyAchievement")
        case .thenVsNow, .monthlyGrowth, .growthChart:
            tags.append("#PuppyGrowth")
            tags.append("#ThenAndNow")
        case .milestone:
            tags.append("#PuppyMilestone")
        case .training:
            tags.append("#DogTraining")
            tags.append("#PuppyTraining")
        }

        // Add general dog tags
        tags += ["#PuppyLove", "#DogsOfInstagram"]

        // Limit to 10 hashtags
        return Array(tags.prefix(10))
    }

    private func buildFewHashtags<Card: ShareableCard>(card: Card) -> [String] {
        var tags = ["#OllieApp"]

        switch card.type {
        case .training:
            tags.append("#PuppyTraining")
        case .thenVsNow, .monthlyGrowth, .growthChart:
            tags.append("#PuppyGrowth")
        default:
            tags.append("#PuppyLife")
        }

        return tags
    }
}
