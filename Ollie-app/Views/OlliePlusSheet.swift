//
//  OlliePlusSheet.swift
//  Ollie-app
//
//  Full-screen subscription sheet for Ollie+ promotion

import StoreKit
import SwiftUI

/// Full-screen sheet promoting Ollie+ subscription
struct OlliePlusSheet: View {
    let onDismiss: () -> Void
    let onSubscribed: () -> Void

    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    heroSection

                    // Feature comparison
                    featureComparisonSection

                    // Pricing cards
                    pricingSection

                    // Trial eligibility
                    if subscriptionManager.isTrialEligible {
                        trialCallout
                    }

                    // Terms footer
                    termsFooter
                }
                .padding()
            }
            .navigationTitle(Strings.OlliePlus.title)
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
            await subscriptionManager.loadProducts()
        }
        .alert(
            Strings.OlliePlus.purchaseErrorTitle,
            isPresented: .init(
                get: { subscriptionManager.purchaseError != nil },
                set: { if !$0 { subscriptionManager.purchaseError = nil } }
            )
        ) {
            Button(Strings.Common.ok, role: .cancel) {
                subscriptionManager.purchaseError = nil
            }
        } message: {
            if let error = subscriptionManager.purchaseError {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Plus badge
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.ollieAccent, .ollieAccent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)

                Image(systemName: "plus")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(Strings.OlliePlus.heroTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(Strings.OlliePlus.heroSubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }

    // MARK: - Feature Comparison

    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.OlliePlus.whatsIncluded)
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    featureRow(feature)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
        }
    }

    private func featureRow(_ feature: PremiumFeature) -> some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.body)
                .foregroundStyle(Color.ollieAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.ollieSuccess)
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 12) {
            // Yearly (best value)
            if let yearly = subscriptionManager.yearlyProduct {
                PricingCard(
                    product: yearly,
                    isRecommended: true,
                    savingsPercentage: calculateSavings(),
                    isTrialEligible: subscriptionManager.isTrialEligible,
                    isPurchasing: subscriptionManager.isPurchasing,
                    onPurchase: {
                        Task {
                            do {
                                try await subscriptionManager.purchase(yearly)
                                onSubscribed()
                            } catch SubscriptionError.userCancelled {
                                // User cancelled - no error to show
                            } catch {
                                // Error is already stored in subscriptionManager.purchaseError
                            }
                        }
                    }
                )
            }

            // Monthly
            if let monthly = subscriptionManager.monthlyProduct {
                PricingCard(
                    product: monthly,
                    isRecommended: false,
                    savingsPercentage: nil,
                    isTrialEligible: subscriptionManager.isTrialEligible,
                    isPurchasing: subscriptionManager.isPurchasing,
                    onPurchase: {
                        Task {
                            do {
                                try await subscriptionManager.purchase(monthly)
                                onSubscribed()
                            } catch SubscriptionError.userCancelled {
                                // User cancelled - no error to show
                            } catch {
                                // Error is already stored in subscriptionManager.purchaseError
                            }
                        }
                    }
                )
            }

            // Restore purchases
            Button {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            } label: {
                Text(Strings.OlliePlus.restorePurchases)
                    .font(.subheadline)
                    .foregroundStyle(Color.ollieAccent)
            }
            .padding(.top, 8)
        }
    }

    private func calculateSavings() -> Int? {
        guard let monthly = subscriptionManager.monthlyProduct,
              let yearly = subscriptionManager.yearlyProduct else {
            return nil
        }

        let monthlyYearCost = NSDecimalNumber(decimal: monthly.price * 12).doubleValue
        let yearlyCost = NSDecimalNumber(decimal: yearly.price).doubleValue
        let savings = ((monthlyYearCost - yearlyCost) / monthlyYearCost) * 100

        return Int(savings.rounded())
    }

    // MARK: - Trial Callout

    private var trialCallout: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundStyle(Color.ollieAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.OlliePlus.trialTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(Strings.OlliePlus.trialSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ollieAccent.opacity(0.1))
        )
    }

    // MARK: - Terms Footer

    private var termsFooter: some View {
        VStack(spacing: 8) {
            Text(Strings.OlliePlus.subscriptionTerms)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                if let termsURL = URL(string: "https://ollie.app/terms") {
                    Link(Strings.OlliePlus.termsOfService, destination: termsURL)
                        .font(.caption2)
                }

                if let privacyURL = URL(string: "https://ollie.app/privacy") {
                    Link(Strings.OlliePlus.privacyPolicy, destination: privacyURL)
                        .font(.caption2)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let isRecommended: Bool
    let savingsPercentage: Int?
    let isTrialEligible: Bool
    let isPurchasing: Bool
    let onPurchase: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onPurchase) {
            VStack(spacing: 12) {
                // Header with badge
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(periodLabel)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if isTrialEligible {
                            Text(Strings.OlliePlus.freeTrialIncluded)
                                .font(.caption)
                                .foregroundStyle(Color.ollieAccent)
                        }
                    }

                    Spacer()

                    if isRecommended, let savings = savingsPercentage {
                        Text(Strings.OlliePlus.saveBadge(savings))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.ollieSuccess))
                    }
                }

                // Price
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(periodSuffix)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if isPurchasing {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isRecommended ? Color.ollieAccent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    private var periodLabel: String {
        if product.id == SubscriptionManager.yearlyProductID {
            return Strings.OlliePlus.yearly
        }
        return Strings.OlliePlus.monthly
    }

    private var periodSuffix: String {
        if product.id == SubscriptionManager.yearlyProductID {
            return Strings.OlliePlus.perYear
        }
        return Strings.OlliePlus.perMonth
    }
}

// MARK: - Subscription Success View

struct SubscriptionSuccessView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(Color.ollieSuccess.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.ollieSuccess)
            }

            Text(Strings.OlliePlus.welcomeTitle)
                .font(.title2)
                .fontWeight(.bold)

            Text(Strings.OlliePlus.welcomeMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Feature highlights
            VStack(spacing: 12) {
                successFeatureRow(icon: "wand.and.stars", text: Strings.OlliePlus.featurePottyPredictions)
                successFeatureRow(icon: "chart.xyaxis.line", text: Strings.OlliePlus.featureAdvancedAnalytics)
                successFeatureRow(icon: "graduationcap.fill", text: Strings.OlliePlus.featureFullTraining)
            }
            .padding(.vertical)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text(Strings.OlliePlus.getStarted)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.ollieAccent)
                    .foregroundStyle(.white)
                    .cornerRadius(LayoutConstants.cornerRadiusM)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func successFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.ollieAccent)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()

            Image(systemName: "checkmark")
                .foregroundStyle(Color.ollieSuccess)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Previews

#Preview("Ollie+ Sheet") {
    OlliePlusSheet(
        onDismiss: {},
        onSubscribed: {}
    )
}

#Preview("Subscription Success") {
    SubscriptionSuccessView(onDismiss: {})
}
