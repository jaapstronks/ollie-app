//
//  ExpiredTrialSheet.swift
//  Otis-app
//
//  Full-screen sheet shown when the 14-day trial expires

import SwiftUI

/// Full-screen sheet displayed when the trial expires
/// Shows what the user built during trial and prompts for subscription
struct ExpiredTrialSheet: View {
    let puppyName: String
    let eventCount: Int
    let trainingSessionCount: Int
    let daysTracking: Int
    let monthlyPrice: String?
    let onSubscribe: () -> Void
    let onDismiss: () -> Void

    @State private var showNotNowButton = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Close button (appears after delay)
            HStack {
                Spacer()
                if showNotNowButton {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .transition(.opacity)
                }
            }
            .frame(height: 44)

            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.otisWarning)
                            .symbolRenderingMode(.hierarchical)

                        Text(Strings.Trial.expiredTitle)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(Strings.Trial.expiredSubtitle(name: puppyName))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    // What you've built
                    if eventCount > 0 || trainingSessionCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(Strings.Trial.whatYouBuilt)
                                .font(.headline)

                            HStack(spacing: 16) {
                                if eventCount > 0 {
                                    StatBubble(
                                        icon: "list.bullet",
                                        value: "\(eventCount)",
                                        label: Strings.Trial.eventsLogged(eventCount)
                                    )
                                }

                                if trainingSessionCount > 0 {
                                    StatBubble(
                                        icon: "graduationcap.fill",
                                        value: "\(trainingSessionCount)",
                                        label: Strings.Trial.trainingSessions(trainingSessionCount)
                                    )
                                }

                                if daysTracking > 0 {
                                    StatBubble(
                                        icon: "calendar",
                                        value: "\(daysTracking)",
                                        label: Strings.Trial.daysTracking(daysTracking)
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    }

                    // What you'll lose
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Strings.Trial.whatYouLose)
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 10) {
                            LossRow(icon: "wand.and.stars", text: Strings.Trial.losePredictions)
                            LossRow(icon: "lightbulb.fill", text: Strings.Trial.loseInsights)
                            LossRow(icon: "graduationcap.fill", text: Strings.Trial.loseTraining)
                            LossRow(icon: "chart.xyaxis.line", text: Strings.Trial.loseAnalytics)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 20)
                }
            }

            // Bottom CTA
            VStack(spacing: 12) {
                Button {
                    HapticFeedback.success()
                    onSubscribe()
                } label: {
                    VStack(spacing: 4) {
                        Text(Strings.Trial.subscribeNow)
                            .font(.headline)

                        if let price = monthlyPrice {
                            Text(Strings.Trial.pricePerMonth(price))
                                .font(.caption)
                                .opacity(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.otisAccent)
                    )
                    .foregroundStyle(.white)
                }

                if showNotNowButton {
                    Button {
                        onDismiss()
                    } label: {
                        Text(Strings.Trial.notNow)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .padding(.top, 8)
            .background(
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            )
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .onAppear {
            // Track that expired sheet was shown
            Analytics.track(.trialExpiredShown, properties: [
                "events_logged": eventCount,
                "training_sessions": trainingSessionCount,
                "days_tracking": daysTracking
            ])
            // Show "Not now" button after 3 seconds
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                withAnimation {
                    showNotNowButton = true
                }
            }
        }
        .interactiveDismissDisabled(!showNotNowButton)
    }
}

/// Bubble showing a stat from the trial period
private struct StatBubble: View {
    let icon: String
    let value: String
    let label: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.otisAccent)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
        )
    }
}

/// Row showing what the user will lose
private struct LossRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Image(systemName: "xmark")
                .font(.caption)
                .foregroundStyle(Color.otisWarning)
        }
    }
}

#Preview {
    ExpiredTrialSheet(
        puppyName: "Luna",
        eventCount: 127,
        trainingSessionCount: 8,
        daysTracking: 14,
        monthlyPrice: "€5.99",
        onSubscribe: {},
        onDismiss: {}
    )
}
