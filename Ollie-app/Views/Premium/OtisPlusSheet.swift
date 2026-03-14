//
//  OtisPlusSheet.swift
//  Otis-app
//
//  Full-screen subscription sheet for Otis+ promotion

import OtisShared
import StoreKit
import SwiftUI

/// Full-screen sheet promoting Otis+ subscription
struct OtisPlusSheet: View {
    let onDismiss: () -> Void
    let onSubscribed: () -> Void

    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var trialManager = TrialManager.shared
    var profileStore = ProfileStore.shared
    @Environment(\.colorScheme) private var colorScheme

    private var dogName: String {
        profileStore.profile?.name ?? Strings.Health.yourPuppy
    }

    /// Determines the context for showing the paywall
    private enum PaywallContext {
        case normal           // Standard upsell
        case inTrial(daysLeft: Int)  // User is in local trial
        case expired          // Trial has expired
    }

    private var paywallContext: PaywallContext {
        if trialManager.isTrialExpired && !subscriptionManager.subscriptionStatus.hasOtisPlus {
            return .expired
        } else if trialManager.isTrialActive {
            return .inTrial(daysLeft: trialManager.daysRemaining)
        }
        return .normal
    }

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
            .navigationTitle(Strings.OtisPlus.title)
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
        .onAppear {
            Analytics.track(.premiumUpsellShown)
        }
        .alert(
            Strings.OtisPlus.purchaseErrorTitle,
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
            // Icon based on context
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: heroGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)

                Image(systemName: heroIcon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(heroTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(heroSubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }

    private var heroIcon: String {
        switch paywallContext {
        case .expired:
            return "clock.badge.exclamationmark"
        case .inTrial:
            return "sparkles"
        case .normal:
            return "plus"
        }
    }

    private var heroGradientColors: [Color] {
        switch paywallContext {
        case .expired:
            return [.otisWarning, .otisWarning.opacity(0.7)]
        case .inTrial:
            return [.otisAccent, .otisAccent.opacity(0.7)]
        case .normal:
            return [.otisAccent, .otisAccent.opacity(0.7)]
        }
    }

    private var heroTitle: String {
        switch paywallContext {
        case .expired:
            return Strings.OtisPlus.expiredHeroTitle
        case .inTrial:
            return Strings.OtisPlus.trialHeroTitle(dogName: dogName)
        case .normal:
            return Strings.OtisPlus.heroTitle
        }
    }

    private var heroSubtitle: String {
        switch paywallContext {
        case .expired:
            return Strings.OtisPlus.expiredHeroSubtitle(dogName: dogName)
        case .inTrial(let daysLeft):
            return Strings.OtisPlus.trialHeroSubtitle(dogName: dogName, daysLeft: daysLeft)
        case .normal:
            return Strings.OtisPlus.heroSubtitle
        }
    }

    // MARK: - Feature Comparison

    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.OtisPlus.whatsIncluded)
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
                .foregroundStyle(Color.otisAccent)
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
                .foregroundStyle(Color.otisSuccess)
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
                        Analytics.track(.premiumUpsellTapped, properties: [
                            "product": "yearly",
                            "trial_eligible": subscriptionManager.isTrialEligible
                        ])
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
                        Analytics.track(.premiumUpsellTapped, properties: [
                            "product": "monthly",
                            "trial_eligible": subscriptionManager.isTrialEligible
                        ])
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
                Text(Strings.OtisPlus.restorePurchases)
                    .font(.subheadline)
                    .foregroundStyle(Color.otisAccent)
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
                .foregroundStyle(Color.otisAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.OtisPlus.trialTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(Strings.OtisPlus.trialSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.otisAccent.opacity(0.1))
        )
    }

    // MARK: - Terms Footer

    private var termsFooter: some View {
        VStack(spacing: 8) {
            Text(Strings.OtisPlus.subscriptionTerms)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                if let termsURL = URL(string: "https://otis.pet/terms") {
                    Link(Strings.OtisPlus.termsOfService, destination: termsURL)
                        .font(.caption2)
                }

                if let privacyURL = URL(string: "https://otis.pet/privacy") {
                    Link(Strings.OtisPlus.privacyPolicy, destination: privacyURL)
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
                            Text(Strings.OtisPlus.freeTrialIncluded)
                                .font(.caption)
                                .foregroundStyle(Color.otisAccent)
                        }
                    }

                    Spacer()

                    if isRecommended, let savings = savingsPercentage {
                        Text(Strings.OtisPlus.saveBadge(savings))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.otisSuccess))
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
                            .stroke(isRecommended ? Color.otisAccent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    private var periodLabel: String {
        if product.id == SubscriptionManager.yearlyProductID {
            return Strings.OtisPlus.yearly
        }
        return Strings.OtisPlus.monthly
    }

    private var periodSuffix: String {
        if product.id == SubscriptionManager.yearlyProductID {
            return Strings.OtisPlus.perYear
        }
        return Strings.OtisPlus.perMonth
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
                    .fill(Color.otisSuccess.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.otisSuccess)
            }

            Text(Strings.OtisPlus.welcomeTitle)
                .font(.title2)
                .fontWeight(.bold)

            Text(Strings.OtisPlus.welcomeMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Feature highlights
            VStack(spacing: 12) {
                successFeatureRow(icon: "wand.and.stars", text: Strings.OtisPlus.featurePottyPredictions)
                successFeatureRow(icon: "chart.xyaxis.line", text: Strings.OtisPlus.featureAdvancedAnalytics)
                successFeatureRow(icon: "graduationcap.fill", text: Strings.OtisPlus.featureFullTraining)
            }
            .padding(.vertical)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text(Strings.OtisPlus.getStarted)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.otisAccent)
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
                .foregroundStyle(Color.otisAccent)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()

            Image(systemName: "checkmark")
                .foregroundStyle(Color.otisSuccess)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Previews

#Preview("Otis+ Sheet") {
    OtisPlusSheet(
        onDismiss: {},
        onSubscribed: {}
    )
}

#Preview("Subscription Success") {
    SubscriptionSuccessView(onDismiss: {})
}
