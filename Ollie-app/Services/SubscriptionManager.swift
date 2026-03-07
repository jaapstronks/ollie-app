//
//  SubscriptionManager.swift
//  Otis-app
//
//  Manages Otis+ subscription using StoreKit 2

import Combine
import Foundation
import OtisShared
import StoreKit
import UIKit
import os

/// Manages Otis+ subscription state and purchases
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Product IDs

    static let monthlyProductID = "com.otis.plus.monthly"
    static let yearlyProductID = "com.otis.plus.yearly"
    static let legacyProductID = "com.otis.premium.perdog"  // For migration

    // MARK: - Cache Keys

    private static let cachedStatusKey = "otis.subscription.cachedStatus"

    // MARK: - Beta Override (DEBUG and TestFlight builds)

    /// When set, overrides the actual subscription status for testing
    /// Only available in beta builds (debug and TestFlight)
    /// Set to nil to use actual StoreKit status
    @Published var betaOverrideStatus: OtisPlusStatus? = nil {
        didSet {
            guard AppEnvironment.current.isBeta else { return }
            // Persist beta override across app launches
            if let status = betaOverrideStatus {
                UserDefaults.standard.set(try? JSONEncoder().encode(status), forKey: "beta.subscriptionOverride")
            } else {
                UserDefaults.standard.removeObject(forKey: "beta.subscriptionOverride")
            }
        }
    }

    /// The effective subscription status (respects beta override in non-production builds)
    /// Priority: beta override > StoreKit subscription > local trial > free
    var effectiveStatus: OtisPlusStatus {
        if AppEnvironment.current.isBeta, let override = betaOverrideStatus {
            return override
        }
        // If StoreKit shows active/trial/legacy, use that
        if subscriptionStatus.hasOtisPlus {
            return subscriptionStatus
        }
        // Check local 14-day trial
        if TrialManager.shared.isTrialActive, let endDate = TrialManager.shared.trialEndDate {
            return .trial(until: endDate)
        }
        // Check if local trial expired (but StoreKit never subscribed)
        if TrialManager.shared.isTrialExpired {
            return .expired
        }
        return subscriptionStatus
    }

    /// Whether the local trial has expired (for showing the expired sheet)
    var isLocalTrialExpired: Bool {
        // Only show expired sheet if:
        // 1. Local trial has expired
        // 2. User doesn't have an active StoreKit subscription
        TrialManager.shared.isTrialExpired && !subscriptionStatus.hasOtisPlus
    }

    // MARK: - Published State

    @Published var products: [Product] = []
    @Published var subscriptionStatus: OtisPlusStatus = .free {
        didSet {
            cacheSubscriptionStatus()
            handleAnalyticsTransition(from: oldValue, to: subscriptionStatus)
        }
    }
    @Published var isPurchasing = false
    @Published var purchaseError: Error?
    @Published var isTrialEligible = false

    private let logger = Logger.otis(category: "SubscriptionManager")

    // MARK: - Private

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    init() {
        // Load cached status immediately for offline support
        loadCachedSubscriptionStatus()
        updateListenerTask = listenForTransactions()

        // Load persisted beta override (only in beta builds)
        if AppEnvironment.current.isBeta,
           let data = UserDefaults.standard.data(forKey: "beta.subscriptionOverride"),
           let status = try? JSONDecoder().decode(OtisPlusStatus.self, from: data) {
            betaOverrideStatus = status
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load subscription products from App Store
    func loadProducts() async {
        do {
            let productIDs = [Self.monthlyProductID, Self.yearlyProductID]
            let loadedProducts = try await Product.products(for: productIDs)
            // Sort: yearly first (better value)
            products = loadedProducts.sorted { p1, _ in
                p1.id == Self.yearlyProductID
            }
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    /// Monthly subscription product
    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    /// Yearly subscription product
    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    // MARK: - Subscription Status

    /// Check current subscription status from App Store
    func checkSubscriptionStatus() async {
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            // Check for new subscription products
            if transaction.productID == Self.monthlyProductID ||
               transaction.productID == Self.yearlyProductID {
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        // Detect trial vs active subscription
                        if transaction.offer?.type == .introductory {
                            subscriptionStatus = .trial(until: expirationDate)
                        } else {
                            subscriptionStatus = .active(until: expirationDate)
                        }
                        await checkTrialEligibility()
                        return
                    }
                }
            }

            // Check for legacy one-time purchase (grandfathered)
            if transaction.productID == Self.legacyProductID {
                subscriptionStatus = .legacy
                return
            }
        }

        // No active subscription found
        subscriptionStatus = .free
        await checkTrialEligibility()
    }

    /// Check if user is eligible for free trial
    private func checkTrialEligibility() async {
        guard let product = yearlyProduct ?? monthlyProduct else {
            // Products haven't loaded yet - don't assume eligibility
            isTrialEligible = false
            return
        }

        isTrialEligible = await product.subscription?.isEligibleForIntroOffer ?? false
    }

    // MARK: - Purchasing

    /// Purchase a subscription product
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        purchaseError = nil

        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Update subscription status - detect trial vs active
                if let expirationDate = transaction.expirationDate {
                    if transaction.offer?.type == .introductory {
                        subscriptionStatus = .trial(until: expirationDate)
                        Analytics.trackTrialStarted(
                            transactionId: transaction.id,
                            productId: transaction.productID,
                            trialEndAt: expirationDate
                        )
                    } else {
                        subscriptionStatus = .active(until: expirationDate)
                    }
                }

                await transaction.finish()
                HapticFeedback.success()

            case .userCancelled:
                throw SubscriptionError.userCancelled

            case .pending:
                throw SubscriptionError.purchasePending

            @unknown default:
                throw SubscriptionError.unknown
            }
        } catch {
            purchaseError = error
            throw error
        }
    }

    /// Restore purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Feature Access

    /// Check if user has access to a specific feature
    func hasAccess(to feature: PremiumFeature) -> Bool {
        switch feature {
        case .multiPuppy,
             .pottyPredictions,
             .advancedAnalytics,
             .sleepInsights,
             .weekInReview,
             .fullTrainingLibrary,
             .socializationProgress,
             .photoVideoAttachments,
             .unlimitedPartnerSharing,
             .exportPDF,
             .calendarIntegration,
             .customMilestones,
             .milestoneNotes,
             .aiNudges:
            return effectiveStatus.hasOtisPlus
        }
    }

    /// Check if user can access a training skill at the given index
    /// First N skills are free, rest require Otis+
    func canAccessSkill(at index: Int) -> Bool {
        index < freeTrainingSkillCount || effectiveStatus.hasOtisPlus
    }

    /// Check if user can add more sharing partners
    /// Free users: limited to `freePartnerLimit` partners
    /// Otis+ users: unlimited
    func canAddMorePartners(currentPartnerCount: Int) -> Bool {
        effectiveStatus.hasOtisPlus || currentPartnerCount < freePartnerLimit
    }

    /// Check if user has reached the free partner sharing limit
    func hasReachedPartnerLimit(currentPartnerCount: Int) -> Bool {
        !effectiveStatus.hasOtisPlus && currentPartnerCount >= freePartnerLimit
    }

    // MARK: - Transaction Handling

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    // Only process and finish verified transactions
                    await self.handleTransactionUpdate(transaction)
                    await transaction.finish()
                case .unverified(let transaction, let error):
                    // Log but don't finish unverified transactions
                    // They will be retried on next app launch or sync
                    self.logger.error("Transaction verification failed for \(transaction.productID): \(error.localizedDescription)")
                    // Attempt to sync with App Store to retry verification
                    try? await AppStore.sync()
                }
            }
        }
    }

    /// Handle a transaction update
    private func handleTransactionUpdate(_ transaction: Transaction) async {
        if transaction.productID == Self.monthlyProductID ||
           transaction.productID == Self.yearlyProductID {
            if let expirationDate = transaction.expirationDate {
                if expirationDate > Date() {
                    // Detect trial vs active subscription
                    if transaction.offer?.type == .introductory {
                        subscriptionStatus = .trial(until: expirationDate)
                    } else {
                        subscriptionStatus = .active(until: expirationDate)
                    }
                } else {
                    subscriptionStatus = .expired
                }
            }
        }
    }

    private func handleAnalyticsTransition(from oldValue: OtisPlusStatus, to newValue: OtisPlusStatus) {
        guard oldValue != newValue else { return }
        if oldValue.isInTrial, case .active(let activeUntil) = newValue {
            Analytics.trackTrialConverted(activeUntil: activeUntil)
        }
    }

    /// Verify a transaction is legitimate
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Manage Subscription

    /// Open App Store subscription management
    @available(iOS 15.0, *)
    func manageSubscription() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                logger.error("Failed to show manage subscriptions: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Secure Caching (Keychain)

    /// Cache subscription status to Keychain for secure offline access
    /// Using Keychain prevents tampering to bypass the paywall
    private func cacheSubscriptionStatus() {
        do {
            try KeychainHelper.save(subscriptionStatus, for: KeychainHelper.Key.subscriptionStatus)
        } catch {
            logger.error("Failed to cache subscription status: \(error.localizedDescription)")
        }
    }

    /// Load cached subscription status from Keychain
    private func loadCachedSubscriptionStatus() {
        // Migrate from old UserDefaults storage if present
        migrateFromUserDefaultsIfNeeded()

        guard let cachedStatus = KeychainHelper.load(
            key: KeychainHelper.Key.subscriptionStatus,
            as: OtisPlusStatus.self
        ) else {
            return
        }

        // Check if cached status is still valid (not expired)
        switch cachedStatus {
        case .trial(let until), .active(let until):
            if until > Date() {
                // Still valid, use cached status
                // Set directly to avoid triggering didSet (which would re-cache)
                _subscriptionStatus = Published(initialValue: cachedStatus)
            } else {
                // Expired, set to expired state
                _subscriptionStatus = Published(initialValue: .expired)
            }
        case .free, .expired, .legacy:
            // These states don't expire
            _subscriptionStatus = Published(initialValue: cachedStatus)
        }
    }

    /// Migrate subscription cache from UserDefaults to Keychain (one-time)
    private func migrateFromUserDefaultsIfNeeded() {
        // Check if old data exists in UserDefaults
        guard let data = UserDefaults.standard.data(forKey: Self.cachedStatusKey) else {
            return
        }

        // Only migrate if Keychain doesn't have data yet
        guard !KeychainHelper.exists(key: KeychainHelper.Key.subscriptionStatus) else {
            // Clean up old UserDefaults data
            UserDefaults.standard.removeObject(forKey: Self.cachedStatusKey)
            return
        }

        // Migrate to Keychain
        if let status = try? JSONDecoder().decode(OtisPlusStatus.self, from: data) {
            try? KeychainHelper.save(status, for: KeychainHelper.Key.subscriptionStatus)
            logger.info("Migrated subscription status from UserDefaults to Keychain")
        }

        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: Self.cachedStatusKey)
    }
}

// MARK: - Error Types

enum SubscriptionError: LocalizedError {
    case productNotFound
    case userCancelled
    case purchasePending
    case verificationFailed
    case unknown

    nonisolated var errorDescription: String? {
        switch self {
        case .productNotFound:
            return Strings.OtisPlus.errorProductNotFound
        case .userCancelled:
            return Strings.OtisPlus.errorCancelled
        case .purchasePending:
            return Strings.OtisPlus.errorPending
        case .verificationFailed:
            return Strings.OtisPlus.errorVerification
        case .unknown:
            return Strings.OtisPlus.errorUnknown
        }
    }
}
