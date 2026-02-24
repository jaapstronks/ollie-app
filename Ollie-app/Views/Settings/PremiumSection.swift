//
//  PremiumSection.swift
//  Ollie-app
//
//  Ollie+ subscription section for SettingsView

import StoreKit
import SwiftUI
import OllieShared

/// Ollie+ subscription status and management section
struct PremiumSection: View {
    let profile: PuppyProfile
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @Binding var showingOlliePlusSheet: Bool
    @Binding var showingSubscriptionSuccess: Bool

    var body: some View {
        Section(Strings.OlliePlus.settingsTitle) {
            // Status row
            HStack {
                Text(Strings.OlliePlus.settingsStatus)
                Spacer()
                Text(subscriptionManager.subscriptionStatus.displayLabel)
                    .foregroundColor(statusColor)
            }

            // Action buttons based on status
            switch subscriptionManager.subscriptionStatus {
            case .free, .expired:
                // Upgrade button
                Button {
                    showingOlliePlusSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.ollieAccent)
                        Text(Strings.OlliePlus.tryOlliePlus)
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
                    Text(Strings.OlliePlus.restorePurchases)
                }

            case .trial, .active:
                // Manage subscription
                Button {
                    Task {
                        await subscriptionManager.manageSubscription()
                    }
                } label: {
                    HStack {
                        Text(Strings.OlliePlus.manageSubscription)
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
                        .foregroundStyle(Color.ollieSuccess)
                    Text(Strings.Premium.premium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingOlliePlusSheet) {
            OlliePlusSheet(
                onDismiss: {
                    showingOlliePlusSheet = false
                },
                onSubscribed: {
                    showingOlliePlusSheet = false
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
        switch subscriptionManager.subscriptionStatus {
        case .free:
            return Color.secondary
        case .trial:
            return Color.ollieAccent
        case .active, .legacy:
            return Color.ollieSuccess
        case .expired:
            return Color.ollieWarning
        }
    }
}

#Preview {
    Form {
        PremiumSection(
            profile: PuppyProfile.defaultProfile(
                name: "Ollie",
                birthDate: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                homeDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                size: .medium
            ),
            showingOlliePlusSheet: .constant(false),
            showingSubscriptionSuccess: .constant(false)
        )
    }
}
