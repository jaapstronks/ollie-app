//
//  Strings+OtisPlus.swift
//  Otis-app
//
//  Localized strings for Otis+ subscription

import Foundation

private let table = "OtisPlus"

extension Strings {

    // MARK: - Otis+ Subscription

    enum OtisPlus {
        // Title and branding
        static let title = String(localized: "Otis+", table: table)
        static let plusBadge = String(localized: "Otis+", table: table)

        // Hero section
        static let heroTitle = String(localized: "Unlock the full Otis experience", table: table)
        static let heroSubtitle = String(localized: "Get AI-powered insights, unlimited training, and premium features to help your puppy thrive.", table: table)

        // What's included
        static let whatsIncluded = String(localized: "What's included", table: table)

        // Feature names
        static let featureMultiPuppy = String(localized: "Multiple Dogs", table: table)
        static let featurePottyPredictions = String(localized: "Potty Predictions", table: table)
        static let featureAdvancedAnalytics = String(localized: "Advanced Analytics", table: table)
        static let featureSleepInsights = String(localized: "Sleep Insights", table: table)
        static let featureWeekInReview = String(localized: "Week in Review", table: table)
        static let featureFullTraining = String(localized: "Full Training Library", table: table)
        static let featureSocialization = String(localized: "Socialization Progress", table: table)
        static let featurePhotoVideo = String(localized: "Photo & Video Attachments", table: table)
        static let featureUnlimitedSharing = String(localized: "Partner Sharing", table: table)
        static let featureExportPDF = String(localized: "Export to PDF", table: table)
        static let featureCalendarIntegration = String(localized: "Calendar Integration", table: table)
        static let featureCustomMilestones = String(localized: "Custom Milestones", table: table)
        static let featureMilestoneNotes = String(localized: "Milestone Notes & Photos", table: table)
        static let featureAINudges = String(localized: "Smart AI Nudges", table: table)

        // Feature descriptions
        static let featureMultiPuppyDesc = String(localized: "Track up to 5 dogs with separate profiles and data", table: table)
        static let featurePottyPredictionsDesc = String(localized: "AI predicts when your puppy needs to go based on patterns", table: table)
        static let featureAdvancedAnalyticsDesc = String(localized: "Deep insights into behavior, health, and routines", table: table)
        static let featureSleepInsightsDesc = String(localized: "Track sleep quality and optimize rest schedules", table: table)
        static let featureWeekInReviewDesc = String(localized: "Weekly summaries with progress highlights", table: table)
        static let featureFullTrainingDesc = String(localized: "Access all training skills and exercises", table: table)
        static let featureSocializationDesc = String(localized: "Track socialization experiences and progress", table: table)
        static let featurePhotoVideoDesc = String(localized: "Attach photos and videos to any event", table: table)
        static let featureUnlimitedSharingDesc = String(localized: "Share your puppy's data with family and caregivers", table: table)
        static let featureExportPDFDesc = String(localized: "Export logs and reports for your vet", table: table)
        static let featureCalendarIntegrationDesc = String(localized: "Add milestones to your calendar with reminders", table: table)
        static let featureCustomMilestonesDesc = String(localized: "Create your own custom milestones and events", table: table)
        static let featureMilestoneNotesDesc = String(localized: "Add notes and photos when completing milestones", table: table)
        static let featureAINudgesDesc = String(localized: "Subtle AI tuning for daily status text, walk suggestion order, and reminder timing", table: table)

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
        static let trialSubtitle = String(localized: "Try all Otis+ features risk-free. Cancel anytime.", table: table)

        // Actions
        static let subscribe = String(localized: "Subscribe", table: table)
        static let restorePurchases = String(localized: "Restore Purchases", table: table)
        static let manageSubscription = String(localized: "Manage Subscription", table: table)
        static let unlockWithPlus = String(localized: "Unlock with Otis+", table: table)
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
        static let welcomeTitle = String(localized: "Welcome to Otis+!", table: table)
        static let welcomeMessage = String(localized: "You now have access to all premium features. Let's make the most of your puppy's journey together.", table: table)

        // Errors (nonisolated for use in LocalizedError conformance - hardcoded table name)
        static let purchaseErrorTitle = String(localized: "Purchase Failed", table: table)
        nonisolated static let errorProductNotFound = String(localized: "Products not available", table: "OtisPlus")
        nonisolated static let errorCancelled = String(localized: "Purchase was cancelled", table: "OtisPlus")
        nonisolated static let errorPending = String(localized: "Purchase is pending approval", table: "OtisPlus")
        nonisolated static let errorVerification = String(localized: "Could not verify purchase", table: "OtisPlus")
        nonisolated static let errorUnknown = String(localized: "An error occurred", table: "OtisPlus")

        // Locked feature cards
        static let lockedPatterns = String(localized: "Pattern Analysis", table: table)
        static let lockedPatternsDesc = String(localized: "Discover behavioral patterns with Otis+", table: table)
        static let lockedSleepInsights = String(localized: "Sleep Insights", table: table)
        static let lockedSleepInsightsDesc = String(localized: "Get detailed sleep analysis with Otis+", table: table)
        static let lockedTraining = String(localized: "More Training Skills", table: table)
        static let lockedTrainingDesc = String(localized: "Unlock all training skills with Otis+", table: table)

        // Partner sharing (Otis+ only)
        static let sharingRequiresPlus = String(localized: "Share your puppy's data with family members and caregivers with Otis+.", table: table)

        // Banner
        static let tryOtisPlus = String(localized: "Try Otis+", table: table)
        static let discoverPremium = String(localized: "Discover premium features", table: table)

        // Settings section
        static let settingsTitle = String(localized: "Otis+", table: table)
        static let settingsStatus = String(localized: "Status", table: table)

        // Trial-aware paywall messaging
        static func trialHeroTitle(dogName: String) -> String {
            String(localized: "You and \(dogName) are loving Otis+", table: table)
        }
        static func trialHeroSubtitle(dogName: String, daysLeft: Int) -> String {
            if daysLeft == 1 {
                return String(localized: "Your trial ends tomorrow. Subscribe now to keep \(dogName)'s personalized insights.", table: table)
            }
            return String(localized: "Your trial ends in \(daysLeft) days. Subscribe to keep \(dogName)'s insights.", table: table)
        }
        static let expiredHeroTitle = String(localized: "Your Trial Has Ended", table: table)
        static func expiredHeroSubtitle(dogName: String) -> String {
            String(localized: "Subscribe now to restore \(dogName)'s AI-powered insights and predictions.", table: table)
        }
    }
}
