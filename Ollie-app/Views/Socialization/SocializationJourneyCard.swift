//
//  SocializationJourneyCard.swift
//  Otis-app
//
//  Action-focused card for Train tab - "What's next? Log it."

import SwiftUI
import OtisShared

/// Action-focused card for logging socialization exposures from Train tab
struct SocializationJourneyCard: View {
    @Environment(SocializationStore.self) var socializationStore
    @Environment(ProfileStore.self) var profileStore

    @Environment(\.colorScheme) private var colorScheme

    @State private var showInfoSheet = false
    @State private var showLogSheet = false

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var currentPhase: SocializationPhase {
        socializationStore.currentPhase
    }

    /// Total exposures logged
    private var totalExposures: Int {
        socializationStore.allExposures.count
    }

    /// Whether puppy is past the critical window
    private var isWindowClosed: Bool {
        let ageInWeeks = profile?.ageInWeeks ?? 0
        return ageInWeeks > SocializationWindowStatus.windowEndWeek
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(.pink)
                    .accessibilityHidden(true)
                Text(Strings.Socialization.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            // Content based on phase
            if currentPhase == .settlingIn {
                earlyMilestonesContent
            } else if isWindowClosed {
                windowClosedContent
            } else {
                actionContent
            }

            // Exposure count + link to sheet
            Divider()

            HStack {
                if totalExposures > 0 {
                    Text(Strings.Socialization.exposureCount(totalExposures))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showInfoSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text(Strings.Socialization.aboutSocializationWindow)
                            .font(.caption)
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.pink)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .glassCard(tint: .custom(.pink))
        .sheet(isPresented: $showInfoSheet) {
            SocializationWindowSheet()
        }
        .sheet(isPresented: $showLogSheet) {
            if let nextItem = socializationStore.nextFocusItems.first {
                LogExposureSheet(item: nextItem)
            }
        }
    }

    // MARK: - Early Milestones Content (Settling In phase)

    @ViewBuilder
    private var earlyMilestonesContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Socialization.gettingSettled)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            ForEach(socializationStore.milestoneDefinitions.prefix(3), id: \.id) { milestone in
                let isAchieved = socializationStore.isMilestoneAchieved(milestone.id)

                HStack(spacing: 10) {
                    Image(systemName: isAchieved ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isAchieved ? Color.otisSuccess : .secondary)
                        .font(.subheadline)

                    Text(localizedMilestoneName(milestone.id))
                        .font(.subheadline)
                        .foregroundStyle(isAchieved ? .secondary : .primary)
                        .strikethrough(isAchieved)

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        socializationStore.toggleMilestone(milestone.id)
                        HapticFeedback.selection()
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Action Content (During socialization window)

    @ViewBuilder
    private var actionContent: some View {
        let nextItems = socializationStore.nextFocusItems

        VStack(alignment: .leading, spacing: 12) {
            // Today's focus
            if let nextItem = nextItems.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Socialization.todaysFocus)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    Text(nextItem.localizedDisplayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                // Log Exposure - primary action
                Button {
                    showLogSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text(Strings.Socialization.logExposure)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // See All Items - secondary action
                NavigationLink {
                    SocializationJourneyView()
                } label: {
                    HStack(spacing: 6) {
                        Text(Strings.Socialization.seeAllItems)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.pink)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - Window Closed Content

    @ViewBuilder
    private var windowClosedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Socialization.greatWorkExposures(totalExposures))
                .font(.subheadline)

            Text(Strings.Socialization.keepBuildingPositive)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showLogSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text(Strings.Socialization.logExposure)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SocializationJourneyView()
                } label: {
                    Text(Strings.Socialization.viewHistory)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.pink)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private func localizedMilestoneName(_ id: String) -> String {
        switch id {
        case "first-night": return Strings.Socialization.milestoneFirstNight
        case "crate-intro": return Strings.Socialization.milestoneCrateIntro
        case "first-outdoor-potty": return Strings.Socialization.milestoneFirstOutdoorPotty
        case "eating-routine": return Strings.Socialization.milestoneEatingRoutine
        case "name-response": return Strings.Socialization.milestoneNameResponse
        case "settled-in": return Strings.Socialization.milestoneSettledIn
        default: return id
        }
    }
}

// MARK: - Preview

#Preview("Settling In") {
    SocializationJourneyCard()
        .environment(SocializationStore())
        .environment(ProfileStore())
        .padding()
}
