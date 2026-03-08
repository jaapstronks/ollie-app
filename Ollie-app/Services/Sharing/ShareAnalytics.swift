//
//  ShareAnalytics.swift
//  Otis-app
//
//  Analytics tracking for sharing behavior
//

import Foundation

/// Tracks sharing behavior for analytics
struct ShareAnalytics {

    // MARK: - Event Tracking

    /// Track when user attempts to share
    static func trackShareAttempt(
        cardType: ShareableCardType,
        platform: SharePlatform,
        format: ShareFormat
    ) {
        Analytics.track(.shareAttempted, properties: [
            "card_type": cardType.analyticsName,
            "platform": platform.rawValue,
            "format": format.rawValue
        ])
    }

    /// Track when share is successfully completed
    static func trackShareCompleted(
        cardType: ShareableCardType,
        platform: SharePlatform,
        format: ShareFormat
    ) {
        Analytics.track(.shareCompleted, properties: [
            "card_type": cardType.analyticsName,
            "platform": platform.rawValue,
            "format": format.rawValue
        ])
    }

    /// Track when user saves to photos
    static func trackSaveToPhotos(
        cardType: ShareableCardType,
        format: ShareFormat
    ) {
        Analytics.track(.shareSavedToPhotos, properties: [
            "card_type": cardType.analyticsName,
            "format": format.rawValue
        ])
    }

    /// Track when share sheet is opened
    static func trackShareSheetOpened(
        cardType: ShareableCardType
    ) {
        Analytics.track(.shareSheetOpened, properties: [
            "card_type": cardType.analyticsName
        ])
    }

    /// Track when share sheet is dismissed without sharing
    static func trackShareSheetDismissed(
        cardType: ShareableCardType
    ) {
        Analytics.track(.shareSheetDismissed, properties: [
            "card_type": cardType.analyticsName
        ])
    }

    /// Track share error
    static func trackShareError(
        cardType: ShareableCardType,
        platform: SharePlatform?,
        error: ShareError
    ) {
        var props: [String: Any] = [
            "card_type": cardType.analyticsName,
            "error": error.errorDescription ?? "unknown"
        ]
        if let platform = platform {
            props["platform"] = platform.rawValue
        }

        Analytics.track(.shareError, properties: props)
    }

    /// Track format selection change
    static func trackFormatSelected(
        format: ShareFormat,
        cardType: ShareableCardType
    ) {
        Analytics.track(.shareFormatSelected, properties: [
            "format": format.rawValue,
            "card_type": cardType.analyticsName
        ])
    }
}
