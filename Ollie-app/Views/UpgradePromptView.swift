//
//  UpgradePromptView.swift
//  Ollie-app
//

import StoreKit
import SwiftUI

/// Full-screen overlay prompting users to upgrade when free period expires
struct UpgradePromptView: View {
    let puppyName: String
    let onPurchase: () -> Void
    let onRestore: () -> Void
    let onDismiss: () -> Void

    @ObservedObject var storeKit = StoreKitManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero illustration
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.ollieAccent)
                        .padding(.top, 40)

                    // Title
                    Text(Strings.Premium.freeTrialEndedTitle(name: puppyName))
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Message
                    VStack(spacing: 16) {
                        Text(Strings.Premium.firstWeeksMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Text(Strings.Premium.unlockFeatures)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 32)

                    // Purchase button
                    VStack(spacing: 12) {
                        Button {
                            onPurchase()
                        } label: {
                            HStack {
                                if storeKit.isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(priceButtonText)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.ollieAccent)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .disabled(storeKit.isPurchasing)

                        Text(Strings.Premium.oneTimePurchase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)

                    // Restore button
                    Button {
                        onRestore()
                    } label: {
                        Text(Strings.Premium.restorePurchases)
                            .font(.subheadline)
                            .foregroundStyle(Color.ollieAccent)
                    }
                    .disabled(storeKit.isPurchasing)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            await storeKit.loadProducts()
        }
    }

    private var priceButtonText: String {
        if let product = storeKit.premiumProduct {
            return Strings.Premium.continueWithOlliePrice(product.displayPrice)
        }
        return Strings.Premium.continueWithOlliePrice(Strings.Premium.price)
    }
}

/// Compact trial banner shown during last 7 days of free period
struct TrialBanner: View {
    let daysRemaining: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(bannerColor)

                Text(Strings.Premium.trialDaysLeft(daysRemaining))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(Strings.Premium.tapToUpgrade)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(bannerBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private var bannerColor: Color {
        if daysRemaining <= 3 {
            return .ollieWarning
        }
        return .ollieAccent
    }

    private var bannerBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
        return AnyShapeStyle(Color.black.opacity(0.04))
    }
}

/// Success toast shown after purchase completes
struct PurchaseSuccessView: View {
    let puppyName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text(Strings.Premium.purchaseSuccessTitle)
                .font(.title2)
                .fontWeight(.bold)

            Text(Strings.Premium.purchaseSuccessMessage(name: puppyName))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text(Strings.Common.done)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.ollieAccent)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

#Preview("Upgrade Prompt") {
    UpgradePromptView(
        puppyName: "Ollie",
        onPurchase: {},
        onRestore: {},
        onDismiss: {}
    )
}

#Preview("Trial Banner") {
    VStack {
        TrialBanner(daysRemaining: 7, onTap: {})
        TrialBanner(daysRemaining: 3, onTap: {})
        TrialBanner(daysRemaining: 1, onTap: {})
    }
}

#Preview("Purchase Success") {
    PurchaseSuccessView(puppyName: "Ollie", onDismiss: {})
}
