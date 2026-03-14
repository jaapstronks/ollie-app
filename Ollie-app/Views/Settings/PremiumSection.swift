//
//  PremiumSection.swift
//  Otis-app
//
//  Otis+ subscription section for SettingsView

import StoreKit
import SwiftUI
import OtisShared

/// Otis+ subscription status and management section
struct PremiumSection: View {
    let profile: PuppyProfile
    var subscriptionManager = SubscriptionManager.shared
    @Binding var showingOtisPlusSheet: Bool
    @Binding var showingSubscriptionSuccess: Bool

    var body: some View {
        Section(Strings.OtisPlus.settingsTitle) {
            // Status row
            HStack {
                Text(Strings.OtisPlus.settingsStatus)
                Spacer()
                Text(subscriptionManager.effectiveStatus.displayLabel)
                    .foregroundStyle(statusColor)
            }

            // Action buttons based on status
            switch subscriptionManager.effectiveStatus {
            case .free, .expired:
                // Upgrade button
                Button {
                    showingOtisPlusSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.otisAccent)
                        Text(Strings.OtisPlus.tryOtisPlus)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Restore purchases
                Button {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                } label: {
                    Text(Strings.OtisPlus.restorePurchases)
                }

            case .trial, .active:
                // Manage subscription
                Button {
                    Task {
                        await subscriptionManager.manageSubscription()
                    }
                } label: {
                    HStack {
                        Text(Strings.OtisPlus.manageSubscription)
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            case .legacy:
                // Legacy purchasers - just show status, no action needed
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.otisSuccess)
                    Text(Strings.Premium.premium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingOtisPlusSheet) {
            OtisPlusSheet(
                onDismiss: {
                    showingOtisPlusSheet = false
                },
                onSubscribed: {
                    showingOtisPlusSheet = false
                    showingSubscriptionSuccess = true
                }
            )
        }
        .sheet(isPresented: $showingSubscriptionSuccess) {
            SubscriptionSuccessView(
                onDismiss: {
                    showingSubscriptionSuccess = false
                }
            )
        }
        .task {
            // Only refresh if status is expired or unknown
            // (App launch already checks status, and transaction listener updates in real-time)
            // Note: Check actual subscriptionStatus, not effectiveStatus (debug override)
            if case .expired = subscriptionManager.subscriptionStatus {
                await subscriptionManager.checkSubscriptionStatus()
            }
            // Load products if not already loaded (needed for pricing display)
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
        }
    }

    private var statusColor: Color {
        switch subscriptionManager.effectiveStatus {
        case .free:
            return Color.secondary
        case .trial:
            return Color.otisAccent
        case .active, .legacy:
            return Color.otisSuccess
        case .expired:
            return Color.otisWarning
        }
    }
}

#Preview {
    Form {
        PremiumSection(
            profile: PuppyProfile.defaultProfile(
                name: "Max",
                birthDate: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                homeDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                size: .medium
            ),
            showingOtisPlusSheet: .constant(false),
            showingSubscriptionSuccess: .constant(false)
        )
    }
}
