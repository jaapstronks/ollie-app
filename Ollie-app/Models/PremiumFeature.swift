//
//  PremiumFeature.swift
//  Ollie-app
//
//  Defines features gated behind Ollie+ subscription

import Foundation

/// Features that require Ollie+ subscription
enum PremiumFeature: String, CaseIterable {
    /// AI-powered potty predictions based on patterns
    case pottyPredictions

    /// Advanced analytics with pattern recognition
    case advancedAnalytics

    /// Detailed sleep insights and trends
    case sleepInsights

    /// Weekly summary/review
    case weekInReview

    /// Full training library (free tier: 10 skills)
    case fullTrainingLibrary

    /// Socialization progress tracking
    case socializationProgress

    /// Photo/video attachments on events
    case photoVideoAttachments

    /// More than 1 partner for sharing
    case unlimitedPartnerSharing

    /// Export data to PDF
    case exportPDF

    /// Display name for the feature
    var displayName: String {
        switch self {
        case .pottyPredictions:
            return Strings.OlliePlus.featurePottyPredictions
        case .advancedAnalytics:
            return Strings.OlliePlus.featureAdvancedAnalytics
        case .sleepInsights:
            return Strings.OlliePlus.featureSleepInsights
        case .weekInReview:
            return Strings.OlliePlus.featureWeekInReview
        case .fullTrainingLibrary:
            return Strings.OlliePlus.featureFullTraining
        case .socializationProgress:
            return Strings.OlliePlus.featureSocialization
        case .photoVideoAttachments:
            return Strings.OlliePlus.featurePhotoVideo
        case .unlimitedPartnerSharing:
            return Strings.OlliePlus.featureUnlimitedSharing
        case .exportPDF:
            return Strings.OlliePlus.featureExportPDF
        }
    }

    /// Short description of the feature
    var description: String {
        switch self {
        case .pottyPredictions:
            return Strings.OlliePlus.featurePottyPredictionsDesc
        case .advancedAnalytics:
            return Strings.OlliePlus.featureAdvancedAnalyticsDesc
        case .sleepInsights:
            return Strings.OlliePlus.featureSleepInsightsDesc
        case .weekInReview:
            return Strings.OlliePlus.featureWeekInReviewDesc
        case .fullTrainingLibrary:
            return Strings.OlliePlus.featureFullTrainingDesc
        case .socializationProgress:
            return Strings.OlliePlus.featureSocializationDesc
        case .photoVideoAttachments:
            return Strings.OlliePlus.featurePhotoVideoDesc
        case .unlimitedPartnerSharing:
            return Strings.OlliePlus.featureUnlimitedSharingDesc
        case .exportPDF:
            return Strings.OlliePlus.featureExportPDFDesc
        }
    }

    /// SF Symbol icon for the feature
    var icon: String {
        switch self {
        case .pottyPredictions:
            return "wand.and.stars"
        case .advancedAnalytics:
            return "chart.xyaxis.line"
        case .sleepInsights:
            return "moon.stars.fill"
        case .weekInReview:
            return "calendar.badge.clock"
        case .fullTrainingLibrary:
            return "graduationcap.fill"
        case .socializationProgress:
            return "person.3.fill"
        case .photoVideoAttachments:
            return "camera.fill"
        case .unlimitedPartnerSharing:
            return "person.badge.plus"
        case .exportPDF:
            return "doc.richtext"
        }
    }
}

/// Number of free training skills (first N skills are free)
let freeTrainingSkillCount = 10
