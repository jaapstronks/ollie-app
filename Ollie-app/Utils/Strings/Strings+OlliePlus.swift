//
//  Strings+OlliePlus.swift
//  Ollie-app
//
//  Localized strings for Ollie+ subscription

import Foundation

extension Strings {

    // MARK: - Ollie+ Subscription

    enum OlliePlus {
        // Title and branding
        static let title = String(localized: "Ollie+")
        static let plusBadge = String(localized: "Ollie+")

        // Hero section
        static let heroTitle = String(localized: "Unlock the full Ollie experience")
        static let heroSubtitle = String(localized: "Get AI-powered insights, unlimited training, and premium features to help your puppy thrive.")

        // What's included
        static let whatsIncluded = String(localized: "What's included")

        // Feature names
        static let featurePottyPredictions = String(localized: "Potty Predictions")
        static let featureAdvancedAnalytics = String(localized: "Advanced Analytics")
        static let featureSleepInsights = String(localized: "Sleep Insights")
        static let featureWeekInReview = String(localized: "Week in Review")
        static let featureFullTraining = String(localized: "Full Training Library")
        static let featureSocialization = String(localized: "Socialization Progress")
        static let featurePhotoVideo = String(localized: "Photo & Video Attachments")
        static let featureUnlimitedSharing = String(localized: "Unlimited Partner Sharing")
        static let featureExportPDF = String(localized: "Export to PDF")

        // Feature descriptions
        static let featurePottyPredictionsDesc = String(localized: "AI predicts when your puppy needs to go based on patterns")
        static let featureAdvancedAnalyticsDesc = String(localized: "Deep insights into behavior, health, and routines")
        static let featureSleepInsightsDesc = String(localized: "Track sleep quality and optimize rest schedules")
        static let featureWeekInReviewDesc = String(localized: "Weekly summaries with progress highlights")
        static let featureFullTrainingDesc = String(localized: "Access all training skills and exercises")
        static let featureSocializationDesc = String(localized: "Track socialization experiences and progress")
        static let featurePhotoVideoDesc = String(localized: "Attach photos and videos to any event")
        static let featureUnlimitedSharingDesc = String(localized: "Share with your whole family, not just one partner")
        static let featureExportPDFDesc = String(localized: "Export logs and reports for your vet")

        // Pricing
        static let yearly = String(localized: "Yearly")
        static let monthly = String(localized: "Monthly")
        static let perYear = String(localized: "/year")
        static let perMonth = String(localized: "/month")
        static let freeTrialIncluded = String(localized: "7 days free")

        static func saveBadge(_ percent: Int) -> String {
            String(localized: "Save \(percent)%")
        }

        // Trial
        static let trialTitle = String(localized: "7 days free")
        static let trialSubtitle = String(localized: "Try all Ollie+ features risk-free. Cancel anytime.")

        // Actions
        static let subscribe = String(localized: "Subscribe")
        static let restorePurchases = String(localized: "Restore Purchases")
        static let manageSubscription = String(localized: "Manage Subscription")
        static let unlockWithPlus = String(localized: "Unlock with Ollie+")
        static let getStarted = String(localized: "Get Started")

        // Terms
        static let subscriptionTerms = String(localized: "Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Payment will be charged to your Apple ID account. Manage your subscriptions in Settings.")
        static let termsOfService = String(localized: "Terms of Service")
        static let privacyPolicy = String(localized: "Privacy Policy")

        // Status labels
        static let statusFree = String(localized: "Free")
        static let statusExpired = String(localized: "Expired")
        static let statusLegacy = String(localized: "Premium (Lifetime)")

        static func statusTrial(daysLeft: Int) -> String {
            String(localized: "Trial (\(daysLeft) days left)")
        }

        static func statusActive(renewDate: String) -> String {
            String(localized: "Active (renews \(renewDate))")
        }

        // Success
        static let welcomeTitle = String(localized: "Welcome to Ollie+!")
        static let welcomeMessage = String(localized: "You now have access to all premium features. Let's make the most of your puppy's journey together.")

        // Errors
        static let purchaseErrorTitle = String(localized: "Purchase Failed")
        static let errorProductNotFound = String(localized: "Products not available")
        static let errorCancelled = String(localized: "Purchase was cancelled")
        static let errorPending = String(localized: "Purchase is pending approval")
        static let errorVerification = String(localized: "Could not verify purchase")
        static let errorUnknown = String(localized: "An error occurred")

        // Locked feature cards
        static let lockedPatterns = String(localized: "Pattern Analysis")
        static let lockedPatternsDesc = String(localized: "Discover behavioral patterns with Ollie+")
        static let lockedSleepInsights = String(localized: "Sleep Insights")
        static let lockedSleepInsightsDesc = String(localized: "Get detailed sleep analysis with Ollie+")
        static let lockedTraining = String(localized: "More Training Skills")
        static let lockedTrainingDesc = String(localized: "Unlock all training skills with Ollie+")

        // Banner
        static let tryOlliePlus = String(localized: "Try Ollie+")
        static let discoverPremium = String(localized: "Discover premium features")

        // Settings section
        static let settingsTitle = String(localized: "Ollie+")
        static let settingsStatus = String(localized: "Status")
    }
}
