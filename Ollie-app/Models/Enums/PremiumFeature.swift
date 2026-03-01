//
//  PremiumFeature.swift
//  Otis-app
//
//  Defines features gated behind Otis+ subscription

import Foundation

/// Features that require Otis+ subscription
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

    /// Calendar integration for milestones
    case calendarIntegration

    /// Create custom milestones
    case customMilestones

    /// Notes and photos on milestone completions
    case milestoneNotes

    /// Display name for the feature
    var displayName: String {
        switch self {
        case .pottyPredictions:
            return Strings.OtisPlus.featurePottyPredictions
        case .advancedAnalytics:
            return Strings.OtisPlus.featureAdvancedAnalytics
        case .sleepInsights:
            return Strings.OtisPlus.featureSleepInsights
        case .weekInReview:
            return Strings.OtisPlus.featureWeekInReview
        case .fullTrainingLibrary:
            return Strings.OtisPlus.featureFullTraining
        case .socializationProgress:
            return Strings.OtisPlus.featureSocialization
        case .photoVideoAttachments:
            return Strings.OtisPlus.featurePhotoVideo
        case .unlimitedPartnerSharing:
            return Strings.OtisPlus.featureUnlimitedSharing
        case .exportPDF:
            return Strings.OtisPlus.featureExportPDF
        case .calendarIntegration:
            return Strings.OtisPlus.featureCalendarIntegration
        case .customMilestones:
            return Strings.OtisPlus.featureCustomMilestones
        case .milestoneNotes:
            return Strings.OtisPlus.featureMilestoneNotes
        }
    }

    /// Short description of the feature
    var description: String {
        switch self {
        case .pottyPredictions:
            return Strings.OtisPlus.featurePottyPredictionsDesc
        case .advancedAnalytics:
            return Strings.OtisPlus.featureAdvancedAnalyticsDesc
        case .sleepInsights:
            return Strings.OtisPlus.featureSleepInsightsDesc
        case .weekInReview:
            return Strings.OtisPlus.featureWeekInReviewDesc
        case .fullTrainingLibrary:
            return Strings.OtisPlus.featureFullTrainingDesc
        case .socializationProgress:
            return Strings.OtisPlus.featureSocializationDesc
        case .photoVideoAttachments:
            return Strings.OtisPlus.featurePhotoVideoDesc
        case .unlimitedPartnerSharing:
            return Strings.OtisPlus.featureUnlimitedSharingDesc
        case .exportPDF:
            return Strings.OtisPlus.featureExportPDFDesc
        case .calendarIntegration:
            return Strings.OtisPlus.featureCalendarIntegrationDesc
        case .customMilestones:
            return Strings.OtisPlus.featureCustomMilestonesDesc
        case .milestoneNotes:
            return Strings.OtisPlus.featureMilestoneNotesDesc
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
        case .calendarIntegration:
            return "calendar.badge.plus"
        case .customMilestones:
            return "plus.circle.fill"
        case .milestoneNotes:
            return "note.text"
        }
    }
}

/// Number of free training skills (first N skills are free)
let freeTrainingSkillCount = 10

/// Number of partners free users can share with (0 = sharing is Otis+ only)
let freePartnerLimit = 0
