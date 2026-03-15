//
//  SentimentCheckInContainer.swift
//  Ollie-app
//
//  Container that shows the appropriate sentiment check-in card
//  based on the current state and scheduling logic.
//

import SwiftUI
import OtisShared

/// Container that manages sentiment check-in display on TodayView.
/// Shows either onboarding (multiple questions) or single daily check-in.
struct SentimentCheckInContainer: View {
    var sentimentStore: SentimentStore
    let profile: PuppyProfile
    let events: [PuppyEvent]

    @State private var showOnboarding = false
    @State private var isDismissed = false
    @AppStorage("lastSentimentCheckInDate") private var lastCheckInDateString: String = ""
    @AppStorage("shareAcceptedDate") private var shareAcceptedDateString: String = ""

    /// Delay before showing sentiment onboarding to new share participants (24 hours)
    private let shareGracePeriodHours: Double = 24

    /// Category to ask about today, if any
    private var categoryToAsk: SentimentCategory? {
        guard !isDismissed else { return nil }
        guard !isAlreadyAskedToday else { return nil }
        guard !isRecentShareParticipant else { return nil }
        // Don't ask on Day 0 (first day after onboarding)
        guard FirstWeekExperienceService.shared.shouldShowSentimentCheckIn else { return nil }
        return sentimentStore.nextQuestionToAsk(profile: profile)
    }

    /// Whether we've already asked a question today
    private var isAlreadyAskedToday: Bool {
        guard !lastCheckInDateString.isEmpty else { return false }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let lastDate = dateFormatter.date(from: lastCheckInDateString) else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    /// Whether user joined via share invite recently (within grace period)
    /// Give them time to explore the app before asking questions
    private var isRecentShareParticipant: Bool {
        guard !shareAcceptedDateString.isEmpty else { return false }
        let dateFormatter = ISO8601DateFormatter()
        guard let acceptedDate = dateFormatter.date(from: shareAcceptedDateString) else { return false }
        let hoursSinceAccepted = Date().timeIntervalSince(acceptedDate) / 3600
        return hoursSinceAccepted < shareGracePeriodHours
    }

    /// Whether to show onboarding (skip for recent share participants)
    private var shouldShowOnboarding: Bool {
        !isDismissed && sentimentStore.needsOnboarding && !isRecentShareParticipant
    }

    var body: some View {
        Group {
            // Show onboarding flow if needed (first time or many missing)
            // Skip for users who just joined via share invite
            if shouldShowOnboarding {
                onboardingPromptCard
            }
            // Otherwise show single check-in card if there's a question
            else if let category = categoryToAsk {
                singleCheckInCard(for: category)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            SentimentOnboardingSheet(
                sentimentStore: sentimentStore,
                profile: profile,
                events: events
            )
        }
    }

    // MARK: - Onboarding Prompt Card

    @ViewBuilder
    private var onboardingPromptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .foregroundStyle(.purple)
                Text(Strings.Sentiment.onboardingTitle)
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation {
                        isDismissed = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }

            Text(Strings.Sentiment.onboardingSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showOnboarding = true
            } label: {
                Text(Strings.Common.start)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Single Check-In Card

    @ViewBuilder
    private func singleCheckInCard(for category: SentimentCategory) -> some View {
        let context = SentimentContextBuilder.buildContext(
            for: category,
            events: events,
            profile: profile
        )

        SentimentCheckInCard(
            category: category,
            contextSummary: context,
            onSubmit: { score in
                sentimentStore.recordCheckIn(
                    category: category,
                    score: score,
                    contextSummary: context
                )
                markAskedToday()
                withAnimation {
                    isDismissed = true
                }
            },
            onDismiss: {
                markAskedToday()
                withAnimation {
                    isDismissed = true
                }
            }
        )
    }

    private func markAskedToday() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        lastCheckInDateString = dateFormatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    VStack {
        // Preview requires a real SentimentStore which is MainActor-isolated
        Text("Preview requires app context")
            .foregroundStyle(.secondary)
        Spacer()
    }
}
