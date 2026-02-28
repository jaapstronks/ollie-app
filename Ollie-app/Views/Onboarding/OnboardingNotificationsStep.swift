//
//  OnboardingNotificationsStep.swift
//  Ollie-app
//
//  Pre-permission screen for notifications during onboarding
//

import SwiftUI

/// Pre-permission screen explaining notification benefits before requesting
struct OnboardingNotificationsStep: View {
    @EnvironmentObject var notificationService: NotificationService
    let onNext: () -> Void

    @State private var showingCheckmark = false
    @State private var isRequestingPermission = false
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Bell icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.ollieAccent)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(hasAppeared ? 1.0 : 0.8)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 20)

            Text(Strings.Permissions.notificationsTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 8)

            Text(Strings.Permissions.notificationsSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 28)

            // Benefits list
            VStack(alignment: .leading, spacing: 14) {
                PermissionBenefitRow(icon: "drop.fill", text: Strings.Permissions.notificationsBenefit1)
                PermissionBenefitRow(icon: "fork.knife", text: Strings.Permissions.notificationsBenefit2)
                PermissionBenefitRow(icon: "moon.zzz.fill", text: Strings.Permissions.notificationsBenefit3)
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
                Button {
                    requestNotificationPermission()
                } label: {
                    Text(Strings.Permissions.enableNotifications)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.ollieAccent)
                        )
                        .foregroundStyle(.white)
                }
                .disabled(isRequestingPermission)

                Button {
                    onNext()
                } label: {
                    Text(Strings.Permissions.notNow)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
                .disabled(isRequestingPermission)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .onAppear {
            // Auto-skip if already authorized
            if notificationService.isAuthorized {
                onNext()
            }
            // Animate content in
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }

    private func requestNotificationPermission() {
        isRequestingPermission = true

        Task {
            let granted = await notificationService.requestAuthorization()

            await MainActor.run {
                isRequestingPermission = false

                if granted {
                    // Show checkmark animation then advance
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingCheckmark = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onNext()
                    }
                } else {
                    // Permission denied - advance without animation
                    onNext()
                }
            }
        }
    }
}

/// Row showing a benefit with icon for permission screens
private struct PermissionBenefitRow: View {
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
    OnboardingNotificationsStep(onNext: {})
        .environmentObject(NotificationService())
}
