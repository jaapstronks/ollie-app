//
//  StoreKitManager.swift
//  Ollie-app
//

import Combine
import OllieShared
import Foundation
import StoreKit

/// Manages in-app purchases using StoreKit 2
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    static let premiumProductID = "com.ollie.premium.perdog"

    @Published var premiumProduct: Product?
    @Published var isPurchasing = false
    @Published var purchaseError: Error?

    /// Set of profile IDs that have been unlocked via purchase
    private var unlockedProfileIDs: Set<UUID> = []

    /// UserDefaults key for storing unlocked profile IDs
    private let unlockedProfilesKey = "ollie.premium.unlockedProfiles"

    private var updateListenerTask: Task<Void, Error>?

    init() {
        loadUnlockedProfiles()
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load available products from the App Store
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            premiumProduct = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase Flow

    /// Purchase premium for a specific profile
    func purchase(for profileID: UUID) async throws {
        guard let product = premiumProduct else {
            throw StoreKitError.productNotFound
        }

        isPurchasing = true
        purchaseError = nil

        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await unlockProfile(profileID)
            await transaction.finish()

        case .userCancelled:
            throw StoreKitError.userCancelled

        case .pending:
            throw StoreKitError.purchasePending

        @unknown default:
            throw StoreKitError.unknown
        }
    }

    /// Restore previous purchases
    func restorePurchases() async {
        // Sync with App Store to get latest transaction history
        try? await AppStore.sync()

        // Check for existing transactions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.premiumProductID {
                    // Note: For restore, we don't have a specific profile ID
                    // The UI should handle associating restored purchases with profiles
                    print("Found existing premium purchase")
                }
            }
        }
    }

    /// Check if a specific profile has been unlocked
    func isPurchased(profileID: UUID) -> Bool {
        unlockedProfileIDs.contains(profileID)
    }

    // MARK: - Transaction Handling

    /// Listen for transaction updates (e.g., purchases made on another device)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    // Handle the updated transaction
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Verify a transaction is legitimate
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Local Storage

    /// Unlock a profile after successful purchase
    private func unlockProfile(_ profileID: UUID) async {
        unlockedProfileIDs.insert(profileID)
        saveUnlockedProfiles()
    }

    /// Load unlocked profile IDs from UserDefaults
    private func loadUnlockedProfiles() {
        if let data = UserDefaults.standard.data(forKey: unlockedProfilesKey),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            unlockedProfileIDs = ids
        }
    }

    /// Save unlocked profile IDs to UserDefaults
    private func saveUnlockedProfiles() {
        if let data = try? JSONEncoder().encode(unlockedProfileIDs) {
            UserDefaults.standard.set(data, forKey: unlockedProfilesKey)
        }
    }
}

// MARK: - Error Types

enum StoreKitError: LocalizedError {
    case productNotFound
    case userCancelled
    case purchasePending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .userCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Transaction verification failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
