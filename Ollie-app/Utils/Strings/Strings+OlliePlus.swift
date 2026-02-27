//
//  Strings+OlliePlus.swift
//  Ollie-app
//
//  Localized strings for Ollie+ subscription

import Foundation

private let table = "OlliePlus"

extension Strings {

    // MARK: - Ollie+ Subscription

    enum OlliePlus {
        // Title and branding
        static let title = String(localized: "Ollie+", table: table)
        static let plusBadge = String(localized: "Ollie+", table: table)

        // Hero section
        static let heroTitle = String(localized: "Unlock the full Ollie experience", table: table)
        static let heroSubtitle = String(localized: "Get AI-powered insights, unlimited training, and premium features to help your puppy thrive.", table: table)

        // What's included
        static let whatsIncluded = String(localized: "What's included", table: table)

        // Feature names
        static let featurePottyPredictions = String(localized: "Potty Predictions", table: table)
        static let featureAdvancedAnalytics = String(localized: "Advanced Analytics", table: table)
        static let featureSleepInsights = String(localized: "Sleep Insights", table: table)
        static let featureWeekInReview = String(localized: "Week in Review", table: table)
        static let featureFullTraining = String(localized: "Full Training Library", table: table)
        static let featureSocialization = String(localized: "Socialization Progress", table: table)
        static let featurePhotoVideo = String(localized: "Photo & Video Attachments", table: table)
        static let featureUnlimitedSharing = String(localized: "Unlimited Partner Sharing", table: table)
        static let featureExportPDF = String(localized: "Export to PDF", table: table)
        static let featureCalendarIntegration = String(localized: "Calendar Integration", table: table)
        static let featureCustomMilestones = String(localized: "Custom Milestones", table: table)
        static let featureMilestoneNotes = String(localized: "Milestone Notes & Photos", table: table)

        // Feature descriptions
        static let featurePottyPredictionsDesc = String(localized: "AI predicts when your puppy needs to go based on patterns", table: table)
        static let featureAdvancedAnalyticsDesc = String(localized: "Deep insights into behavior, health, and routines", table: table)
        static let featureSleepInsightsDesc = String(localized: "Track sleep quality and optimize rest schedules", table: table)
        static let featureWeekInReviewDesc = String(localized: "Weekly summaries with progress highlights", table: table)
        static let featureFullTrainingDesc = String(localized: "Access all training skills and exercises", table: table)
        static let featureSocializationDesc = String(localized: "Track socialization experiences and progress", table: table)
        static let featurePhotoVideoDesc = String(localized: "Attach photos and videos to any event", table: table)
        static let featureUnlimitedSharingDesc = String(localized: "Share with your whole family, not just one partner", table: table)
        static let featureExportPDFDesc = String(localized: "Export logs and reports for your vet", table: table)
        static let featureCalendarIntegrationDesc = String(localized: "Add milestones to your calendar with reminders", table: table)
        static let featureCustomMilestonesDesc = String(localized: "Create your own custom milestones and events", table: table)
        static let featureMilestoneNotesDesc = String(localized: "Add notes and photos when completing milestones", table: table)

        // Pricing
        static let yearly = String(localized: "Yearly", table: table)
        static let monthly = String(localized: "Monthly", table: table)
        static let perYear = String(localized: "/year", table: table)
        static let perMonth = String(localized: "/month", table: table)
        static let freeTrialIncluded = String(localized: "7 days free", table: table)

        static func saveBadge(_ percent: Int) -> String {
            String(localized: "Save \(percent)%", table: table)
        }

        // Trial
        static let trialTitle = String(localized: "7 days free", table: table)
        static let trialSubtitle = String(localized: "Try all Ollie+ features risk-free. Cancel anytime.", table: table)

        // Actions
        static let subscribe = String(localized: "Subscribe", table: table)
        static let restorePurchases = String(localized: "Restore Purchases", table: table)
        static let manageSubscription = String(localized: "Manage Subscription", table: table)
        static let unlockWithPlus = String(localized: "Unlock with Ollie+", table: table)
        static let getStarted = String(localized: "Get Started", table: table)

        // Terms
        static let subscriptionTerms = String(localized: "Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Payment will be charged to your Apple ID account. Manage your subscriptions in Settings.", table: table)
        static let termsOfService = String(localized: "Terms of Service", table: table)
        static let privacyPolicy = String(localized: "Privacy Policy", table: table)

        // Status labels
        static let statusFree = String(localized: "Free", table: table)
        static let statusExpired = String(localized: "Expired", table: table)
        static let statusLegacy = String(localized: "Premium (Lifetime)", table: table)

        static func statusTrial(daysLeft: Int) -> String {
            String(localized: "Trial (\(daysLeft) days left)", table: table)
        }

        static func statusActive(renewDate: String) -> String {
            String(localized: "Active (renews \(renewDate))", table: table)
        }

        // Success
        static let welcomeTitle = String(localized: "Welcome to Ollie+!", table: table)
        static let welcomeMessage = String(localized: "You now have access to all premium features. Let's make the most of your puppy's journey together.", table: table)

        // Errors
        static let purchaseErrorTitle = String(localized: "Purchase Failed", table: table)
        static let errorProductNotFound = String(localized: "Products not available", table: table)
        static let errorCancelled = String(localized: "Purchase was cancelled", table: table)
        static let errorPending = String(localized: "Purchase is pending approval", table: table)
        static let errorVerification = String(localized: "Could not verify purchase", table: table)
        static let errorUnknown = String(localized: "An error occurred", table: table)

        // Locked feature cards
        static let lockedPatterns = String(localized: "Pattern Analysis", table: table)
        static let lockedPatternsDesc = String(localized: "Discover behavioral patterns with Ollie+", table: table)
        static let lockedSleepInsights = String(localized: "Sleep Insights", table: table)
        static let lockedSleepInsightsDesc = String(localized: "Get detailed sleep analysis with Ollie+", table: table)
        static let lockedTraining = String(localized: "More Training Skills", table: table)
        static let lockedTrainingDesc = String(localized: "Unlock all training skills with Ollie+", table: table)

        // Banner
        static let tryOlliePlus = String(localized: "Try Ollie+", table: table)
        static let discoverPremium = String(localized: "Discover premium features", table: table)

        // Settings section
        static let settingsTitle = String(localized: "Ollie+", table: table)
        static let settingsStatus = String(localized: "Status", table: table)
    }
}
