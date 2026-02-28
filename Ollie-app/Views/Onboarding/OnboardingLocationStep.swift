//
//  OnboardingLocationStep.swift
//  Ollie-app
//
//  Pre-permission screen for location during onboarding
//

import SwiftUI
import CoreLocation

/// Pre-permission screen explaining location benefits before requesting
struct OnboardingLocationStep: View {
    @EnvironmentObject var locationManager: LocationManager
    let onComplete: () -> Void

    @State private var showingCheckmark = false
    @State private var permissionHandled = false
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Location icon
            Image(systemName: "location.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.ollieAccent)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(hasAppeared ? 1.0 : 0.8)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 20)

            Text(Strings.Permissions.locationTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 8)

            Text(Strings.Permissions.locationSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 28)

            // Benefits list
            VStack(alignment: .leading, spacing: 14) {
                LocationBenefitRow(icon: "mappin.and.ellipse", text: Strings.Permissions.locationBenefit1)
                LocationBenefitRow(icon: "cloud.sun.fill", text: Strings.Permissions.locationBenefit2)
                LocationBenefitRow(icon: "figure.walk", text: Strings.Permissions.locationBenefit3)
            }
            .padding(.horizontal, 32)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()

            // Success checkmark overlay
            if showingCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }

            // Action buttons
            VStack(spacing: 12) {
                if permissionHandled {
                    // Show "Let's Go!" after permission is handled
                    Button {
                        onComplete()
                    } label: {
                        Text(Strings.Permissions.letsGo)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.ollieAccent)
                            )
                            .foregroundStyle(.white)
                    }
                } else {
                    // Initial state - show Enable/Not Now
                    Button {
                        requestLocationPermission()
                    } label: {
                        Text(Strings.Permissions.enableLocation)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.ollieAccent)
                            )
                            .foregroundStyle(.white)
                    }

                    Button {
                        // Skip without prompting - go directly to completion
                        onComplete()
                    } label: {
                        Text(Strings.Permissions.notNow)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .onAppear {
            // Auto-skip if already authorized
            if locationManager.isAuthorized {
                onComplete()
            }
            // Animate content in
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            // Handle authorization change after user responds to iOS dialog
            if newStatus != .notDetermined && !permissionHandled {
                handlePermissionResult(newStatus)
            }
        }
    }

    private func requestLocationPermission() {
        locationManager.requestAuthorization()
        // The onChange handler will catch the authorization status change
    }

    private func handlePermissionResult(_ status: CLAuthorizationStatus) {
        let granted = status == .authorizedWhenInUse || status == .authorizedAlways

        if granted {
            // Show checkmark animation then mark as handled
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingCheckmark = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                permissionHandled = true
            }
        } else {
            // Permission denied - just show Let's Go button
            permissionHandled = true
        }
    }
}

/// Row showing a benefit with icon for location permission screen
private struct LocationBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.ollieAccent)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    OnboardingLocationStep(onComplete: {})
        .environmentObject(LocationManager())
}
