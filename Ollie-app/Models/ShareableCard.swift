//
//  ShareableCard.swift
//  Otis-app
//
//  Protocol and types for shareable content cards
//

import SwiftUI
import OtisShared

// MARK: - Shareable Card Protocol

/// Protocol for content that can be rendered and shared as an image
protocol ShareableCard {
    associatedtype CardView: View

    var id: String { get }
    var type: ShareableCardType { get }
    var profile: PuppyProfile { get }
    var generatedDate: Date { get }

    /// Generate the card view for a specific format
    func cardView(for format: ShareFormat) -> CardView

    /// Generate a caption for a specific platform
    func caption(for platform: SharePlatform) -> String
}

// MARK: - Shareable Card Types

enum ShareableCardType: String, CaseIterable {
    case weeklyRecap
    case monthlyRecap
    case yearRecap
    case achievement
    case thenVsNow
    case monthlyGrowth
    case growthChart
    case milestone
    case training

    var analyticsName: String {
        rawValue
    }
}

// MARK: - Share Format

/// Defines the aspect ratio and size for rendered share cards
enum ShareFormat: String, CaseIterable, Identifiable {
    /// 9:16 aspect ratio (1080x1920) - Instagram/Facebook Stories
    case story

    /// 1:1 aspect ratio (1080x1080) - Instagram/Facebook feed
    case squarePost

    /// 4:5 aspect ratio (1080x1350) - Instagram feed optimal
    case portrait

    /// 16:9 aspect ratio (1920x1080) - Twitter/general
    case landscape

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .story:
            return CGSize(width: 1080, height: 1920)
        case .squarePost:
            return CGSize(width: 1080, height: 1080)
        case .portrait:
            return CGSize(width: 1080, height: 1350)
        case .landscape:
            return CGSize(width: 1920, height: 1080)
        }
    }

    var displayName: String {
        switch self {
        case .story:
            return String(localized: "Story (9:16)", table: "Sharing")
        case .squarePost:
            return String(localized: "Square (1:1)", table: "Sharing")
        case .portrait:
            return String(localized: "Portrait (4:5)", table: "Sharing")
        case .landscape:
            return String(localized: "Landscape (16:9)", table: "Sharing")
        }
    }

    /// Scale factor based on device screen
    var renderScale: CGFloat { 2.0 }
}

// MARK: - Share Platform

/// Represents sharing destinations with platform-specific behaviors
enum SharePlatform: String, CaseIterable {
    case instagram
    case facebook
    case twitter
    case whatsapp
    case general

    var hashtagStyle: HashtagStyle {
        switch self {
        case .instagram:
            return .many      // Instagram loves hashtags
        case .twitter:
            return .few       // Twitter: 1-2 hashtags max
        case .facebook, .whatsapp, .general:
            return .minimal
        }
    }

    var displayName: String {
        switch self {
        case .instagram:
            return "Instagram"
        case .facebook:
            return "Facebook"
        case .twitter:
            return "X"
        case .whatsapp:
            return "WhatsApp"
        case .general:
            return String(localized: "Other", table: "Sharing")
        }
    }

    var icon: String {
        switch self {
        case .instagram:
            return "camera.fill"
        case .facebook:
            return "book.fill"
        case .twitter:
            return "at"
        case .whatsapp:
            return "message.fill"
        case .general:
            return "square.and.arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .instagram:
            return .purple
        case .facebook:
            return .blue
        case .twitter:
            return .primary
        case .whatsapp:
            return .green
        case .general:
            return .secondary
        }
    }

    enum HashtagStyle {
        /// Up to 5-10 hashtags
        case many
        /// 1-2 hashtags
        case few
        /// 0-1 hashtags
        case minimal
    }
}

// MARK: - Share Error

enum ShareError: LocalizedError {
    case renderFailed
    case platformNotAvailable
    case photoLibraryDenied
    case photoLibraryRestricted
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return String(localized: "Unable to create shareable image", table: "Sharing")
        case .platformNotAvailable:
            return String(localized: "This app is not installed", table: "Sharing")
        case .photoLibraryDenied:
            return String(localized: "Photo library access is required to save", table: "Sharing")
        case .photoLibraryRestricted:
            return String(localized: "Photo library access is restricted", table: "Sharing")
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
