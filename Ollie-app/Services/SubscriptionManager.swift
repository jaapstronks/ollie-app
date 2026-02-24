//
//  SubscriptionManager.swift
//  Ollie-app
//
//  Manages Ollie+ subscription using StoreKit 2

import Combine
import Foundation
import StoreKit
import UIKit
import os

/// Manages Ollie+ subscription state and purchases
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Product IDs

    static let monthlyProductID = "com.ollie.plus.monthly"
    static let yearlyProductID = "com.ollie.plus.yearly"
    static let legacyProductID = "com.ollie.premium.perdog"  // For migration

    // MARK: - Cache Keys

    private static let cachedStatusKey = "ollie.subscription.cachedStatus"

    // MARK: - Published State

    @Published var products: [Product] = []
    @Published var subscriptionStatus: OlliePlusStatus = .free {
        didSet {
            cacheSubscriptionStatus()
        }
    }
    @Published var isPurchasing = false
    @Published var purchaseError: Error?
    @Published var isTrialEligible = false

    private let logger = Logger(subsystem: "nl.jaapstronks.Ollie", category: "SubscriptionManager")

    // MARK: - Private

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    init() {
        // Load cached status immediately for offline support
        loadCachedSubscriptionStatus()
        updateListenerTask = listenForTransactions()
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
                        if transaction.offerType == .introductory {
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
                    if transaction.offerType == .introductory {
                        subscriptionStatus = .trial(until: expirationDate)
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
        subscriptionStatus.hasOlliePlus
    }

    /// Check if user can access a training skill at the given index
    /// First N skills are free, rest require Ollie+
    func canAccessSkill(at index: Int) -> Bool {
        index < freeTrainingSkillCount || subscriptionStatus.hasOlliePlus
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
                    if transaction.offerType == .introductory {
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
        if let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                logger.error("Failed to show manage subscriptions: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Offline Caching

    /// Cache subscription status to UserDefaults for offline access
    private func cacheSubscriptionStatus() {
        do {
            let data = try JSONEncoder().encode(subscriptionStatus)
            UserDefaults.standard.set(data, forKey: Self.cachedStatusKey)
        } catch {
            logger.error("Failed to cache subscription status: \(error.localizedDescription)")
        }
    }

    /// Load cached subscription status from UserDefaults
    private func loadCachedSubscriptionStatus() {
        guard let data = UserDefaults.standard.data(forKey: Self.cachedStatusKey) else {
            return
        }

        do {
            let cachedStatus = try JSONDecoder().decode(OlliePlusStatus.self, from: data)

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
        } catch {
            logger.error("Failed to load cached subscription status: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Types

enum SubscriptionError: LocalizedError {
    case productNotFound
    case userCancelled
    case purchasePending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return Strings.OlliePlus.errorProductNotFound
        case .userCancelled:
            return Strings.OlliePlus.errorCancelled
        case .purchasePending:
            return Strings.OlliePlus.errorPending
        case .verificationFailed:
            return Strings.OlliePlus.errorVerification
        case .unknown:
            return Strings.OlliePlus.errorUnknown
        }
    }
}
