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
    @Environment(ProfileStore.self) var profileStore
    @Environment(EventStore.self) var eventStore

    @State private var viewModel = MorningBriefingViewModel()
    @State private var isExpanded = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Invisible anchor to ensure task always runs
            Color.clear
                .frame(width: 0, height: 0)

            if viewModel.shouldShow {
                VStack(alignment: .leading, spacing: 0) {
                    // Main card content
                    mainContent

                    // Expandable details
                    if isExpanded, let briefing = viewModel.briefing {
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
        .task {
            await viewModel.loadBriefing(profile: profileStore.profile, eventStore: eventStore)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            MorningBriefingSkeleton()
        } else if let briefing = viewModel.briefing {
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
            .environment(ProfileStore())
            .environment(EventStore())
            .padding()

        Spacer()
    }
}
