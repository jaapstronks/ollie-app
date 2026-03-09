//
//  MorningBriefingCard.swift
//  Ollie-app
//
//  Card displaying AI-powered morning briefing with daily priorities.
//

import SwiftUI
import OtisShared

/// Card displaying synthesized morning briefing from multiple AI sources.
struct MorningBriefingCard: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore

    @State private var briefing: MorningBriefingResponse?
    @State private var isLoading = false
    @State private var isExpanded = false

    @Environment(\.colorScheme) private var colorScheme

    /// Whether the card should be visible
    private var shouldShow: Bool {
        isLoading || briefing != nil
    }

    var body: some View {
        let _ = print("[MorningBriefingCard] body evaluated, shouldShow=\(shouldShow), profile=\(profileStore.profile?.name ?? "nil")")
        content
            .task {
                print("[MorningBriefingCard] task started, profileId=\(profileStore.profile?.id.uuidString ?? "nil")")
                await loadBriefing()
            }
    }

    @ViewBuilder
    private var content: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 0) {
                // Main card content
                mainContent

                // Expandable details
                if isExpanded, let briefing = briefing {
                    expandedContent(briefing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBackground(.card)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if isLoading {
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                Text(Strings.AINudges.loadingBriefing)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if let briefing = briefing {
            VStack(alignment: .leading, spacing: 10) {
                // Headline with icon
                HStack(spacing: 8) {
                    focusIcon(for: briefing.focusType)
                        .font(.title3)
                        .foregroundStyle(focusColor(for: briefing.focusType))

                    Text(briefing.headline)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Focus message
                Text(briefing.focusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Urgencies (always visible if present)
                if let urgencies = briefing.urgencies, !urgencies.isEmpty {
                    ForEach(urgencies, id: \.type) { urgency in
                        urgencyRow(urgency)
                    }
                }
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private func expandedContent(_ briefing: MorningBriefingResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.vertical, 4)

            // Yesterday summary
            if let yesterday = briefing.yesterdaySummary {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(yesterday)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Looking ahead
            if let lookingAhead = briefing.lookingAhead {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(lookingAhead)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Quick wins
            if let quickWins = briefing.quickWins, !quickWins.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Strings.AINudges.quickWins)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    ForEach(quickWins, id: \.self) { win in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(win)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }

            // Encouragement
            if let encouragement = briefing.encouragement {
                Text(encouragement)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Urgency Row

    @ViewBuilder
    private func urgencyRow(_ urgency: MorningBriefingResponse.Urgency) -> some View {
        HStack(spacing: 8) {
            Image(systemName: urgencyIcon(for: urgency.type))
                .font(.caption)
                .foregroundStyle(urgencyColor(for: urgency.type))

            Text(urgency.message)
                .font(.caption)
                .foregroundStyle(.primary)

            if let days = urgency.daysRemaining, days <= 14 {
                Text("(\(days)d)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(days <= 7 ? .orange : .secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(urgencyColor(for: urgency.type).opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }

    // MARK: - Data Loading

    private func loadBriefing() async {
        // Check first-week experience gate
        guard FirstWeekExperienceService.shared.shouldShowAIInsights else {
            print("[MorningBriefing] First week experience: not showing AI insights yet")
            return
        }

        guard let profile = profileStore.profile else {
            print("[MorningBriefing] No profile available yet")
            return
        }

        // Check if AI is available
        guard AI.isAvailable(for: profile) else {
            print("[MorningBriefing] AI not available for profile")
            return
        }

        // Check for cached result first
        if let cached = AI.cachedMorningBriefing(profileId: profile.id) {
            print("[MorningBriefing] Using cached briefing")
            self.briefing = cached
            return
        }

        print("[MorningBriefing] Loading fresh briefing...")
        isLoading = true
        defer { isLoading = false }

        // Morning briefing needs recent history for context
        let recentEvents = eventStore.getEvents(from: Date.daysAgo(14), to: Date())
        print("[MorningBriefing] Got \(recentEvents.count) events from last 14 days")

        let result = await AI.requestMorningBriefing(
            profile: profile,
            events: recentEvents
        )

        switch result {
        case .success(let response):
            print("[MorningBriefing] Success: \(response.headline)")
            self.briefing = response

        case .shadow(let response):
            print("[MorningBriefing] Shadow mode: \(response.headline)")
            self.briefing = response

        case .fallback(let reason):
            print("[MorningBriefing] Fallback: \(reason)")
        }
    }

    // MARK: - Helpers

    private func focusIcon(for focusType: String) -> Image {
        switch focusType {
        case "socialization_urgency":
            return Image(systemName: "person.3.fill")
        case "training_progress":
            return Image(systemName: "star.fill")
        case "health_reminder":
            return Image(systemName: "heart.fill")
        case "celebration":
            return Image(systemName: "party.popper.fill")
        case "encouragement":
            return Image(systemName: "hand.thumbsup.fill")
        default:
            return Image(systemName: "sun.max.fill")
        }
    }

    private func focusColor(for focusType: String) -> Color {
        switch focusType {
        case "socialization_urgency":
            return .pink
        case "training_progress":
            return .purple
        case "health_reminder":
            return .red
        case "celebration":
            return .yellow
        case "encouragement":
            return .green
        default:
            return .orange
        }
    }

    private func urgencyIcon(for type: String) -> String {
        switch type {
        case "socialization_window":
            return "clock.badge.exclamationmark"
        case "health_milestone":
            return "calendar.badge.exclamationmark"
        case "training_regression":
            return "arrow.uturn.down"
        case "vaccination_due":
            return "syringe"
        default:
            return "exclamationmark.triangle"
        }
    }

    private func urgencyColor(for type: String) -> Color {
        switch type {
        case "socialization_window":
            return .orange
        case "health_milestone":
            return .blue
        case "training_regression":
            return .purple
        case "vaccination_due":
            return .red
        default:
            return .yellow
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        MorningBriefingCard()
            .environmentObject(ProfileStore())
            .environmentObject(EventStore())
            .padding()

        Spacer()
    }
}
