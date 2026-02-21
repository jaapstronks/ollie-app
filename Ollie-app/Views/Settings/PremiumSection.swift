//
//  PremiumSection.swift
//  Ollie-app
//
//  Premium/monetization section for SettingsView

import StoreKit
import SwiftUI

/// Premium status and purchase section
struct PremiumSection: View {
    let profile: PuppyProfile
    @ObservedObject var storeKit: StoreKitManager
    @Binding var showingUpgradePrompt: Bool
    @Binding var showingPurchaseSuccess: Bool
    var onPurchase: () async -> Void

    var body: some View {
        Section(Strings.Premium.title) {
            // Status row
            HStack {
                Text(Strings.Premium.status)
                Spacer()
                Text(premiumStatusText)
                    .foregroundColor(premiumStatusColor)
            }

            // Purchase button (if not premium)
            if !profile.isPremiumUnlocked {
                Button {
                    showingUpgradePrompt = true
                } label: {
                    HStack {
                        if storeKit.isPurchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(purchaseButtonText)
                    }
                }
                .disabled(storeKit.isPurchasing)

                // Restore purchases
                Button {
                    Task {
                        await storeKit.restorePurchases()
                    }
                } label: {
                    Text(Strings.Premium.restorePurchases)
                }
                .disabled(storeKit.isPurchasing)
            }
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            UpgradePromptView(
                puppyName: profile.name,
                onPurchase: {
                    Task {
                        await onPurchase()
                    }
                },
                onRestore: {
                    Task {
                        await storeKit.restorePurchases()
                    }
                },
                onDismiss: {
                    showingUpgradePrompt = false
                }
            )
        }
        .sheet(isPresented: $showingPurchaseSuccess) {
            PurchaseSuccessView(
                puppyName: profile.name,
                onDismiss: {
                    showingPurchaseSuccess = false
                }
            )
        }
        .task {
            await storeKit.loadProducts()
        }
    }

    private var premiumStatusText: String {
        if profile.isPremiumUnlocked {
            return Strings.Premium.premium
        } else if profile.isFreePeriodExpired {
            return Strings.Premium.expired
        } else {
            return Strings.Premium.freeDaysLeft(profile.freeDaysRemaining)
        }
    }

    private var premiumStatusColor: Color {
        if profile.isPremiumUnlocked {
            return .ollieSuccess
        } else if profile.isFreePeriodExpired {
            return .ollieWarning
        } else {
            return .secondary
        }
    }

    private var purchaseButtonText: String {
        if let product = storeKit.premiumProduct {
            return Strings.Premium.continueWithOlliePrice(product.displayPrice)
        }
        return Strings.Premium.continueWithOlliePrice(Strings.Premium.price)
    }
}
