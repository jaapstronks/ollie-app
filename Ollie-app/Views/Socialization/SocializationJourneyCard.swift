//
//  SocializationJourneyCard.swift
//  Otis-app
//
//  Journey-focused card for Train tab showing current phase and next focus

import SwiftUI
import OtisShared

/// Card showing current socialization phase and next focus item for Train tab
struct SocializationJourneyCard: View {
    @EnvironmentObject var socializationStore: SocializationStore
    @EnvironmentObject var profileStore: ProfileStore

    @Environment(\.colorScheme) private var colorScheme

    @State private var showInfoSheet = false

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var currentPhase: SocializationPhase {
        socializationStore.currentPhase
    }

    private var daysHome: Int {
        profile?.daysHome ?? 0
    }

    private var puppyName: String {
        profile?.name ?? "Puppy"
    }

    /// Current age in weeks (uses PuppyProfile's computed property)
    private var ageInWeeks: Int {
        profile?.ageInWeeks ?? 0
    }

    /// Weeks remaining in socialization window (ends at 16 weeks)
    private var weeksRemaining: Int {
        max(0, 16 - ageInWeeks)
    }

    /// Whether puppy is in the socialization window (3-16 weeks)
    private var isInSocializationWindow: Bool {
        ageInWeeks >= 3 && ageInWeeks <= 16
    }

    /// Total weeks in socialization window
    private let socializationWindowEnd = 16

    /// Determine if user has started socialization
    private var hasStartedSocialization: Bool {
        socializationStore.totalComfortable > 0
    }

    var body: some View {
        NavigationLink {
            SocializationJourneyView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header with description
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .foregroundStyle(Color.otisAccent)
                            .accessibilityHidden(true)
                        Text(Strings.Socialization.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()

                        // Info button (opens What is Socialization sheet)
                        Button {
                            showInfoSheet = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Strings.Socialization.infoTitle)
                    }

                    Text(Strings.Socialization.socializationDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Phase header with clearer progress indicator
                phaseHeader

                // Content based on phase
                if currentPhase == .settlingIn {
                    earlyMilestonesContent
                } else {
                    progressContent
                }

                // Actionable link at the bottom
                Divider()

                HStack(spacing: 12) {
                    Image(systemName: hasStartedSocialization ? "arrow.right.circle.fill" : "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.otisAccent)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.otisAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        )

                    Text(hasStartedSocialization ? Strings.Socialization.continueSocialization : Strings.Socialization.startSocialization)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.otisAccent)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .padding()
            .glassCard(tint: .accent)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showInfoSheet) {
            WhatIsSocializationSheet()
        }
    }

    // MARK: - Phase Header

    @ViewBuilder
    private var phaseHeader: some View {
        HStack {
            // Phase name only (no confusing week counting)
            VStack(alignment: .leading, spacing: 2) {
                Text(currentPhase.localizedName)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(currentPhase.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Socialization window progress - show weeks remaining
            if isInSocializationWindow && weeksRemaining > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Strings.Socialization.ageWeeksRemaining(remaining: weeksRemaining))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(weeksRemaining <= 4 ? Color.otisWarning : Color.otisAccent)

                    // Mini progress bar showing how much of window is used
                    let windowProgress = CGFloat(ageInWeeks - 3) / CGFloat(socializationWindowEnd - 3)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                            Capsule()
                                .fill(weeksRemaining <= 4 ? Color.otisWarning : Color.otisAccent)
                                .frame(width: geo.size.width * windowProgress)
                        }
                    }
                    .frame(width: 60, height: 4)
                }
            } else if !isInSocializationWindow && ageInWeeks > 16 {
                // Past the window - show progress ring instead
                progressRing
            }
        }
    }

    // MARK: - Early Milestones Content (Settling In phase)

    @ViewBuilder
    private var earlyMilestonesContent: some View {
        VStack(alignment: .leading, spacing: 8) {
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

    // MARK: - Progress Content (After settling in)

    @ViewBuilder
    private var progressContent: some View {
        let progress = socializationStore.currentPhaseProgress
        let nextItems = socializationStore.nextFocusItems

        VStack(alignment: .leading, spacing: 8) {
            // Phase progress
            HStack {
                Text(Strings.Socialization.phaseProgress(comfortable: progress.comfortable, total: progress.total))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                // Progress ring for phase
                ProgressRing(
                    completed: progress.comfortable,
                    total: progress.total,
                    size: .compact
                )
            }

            // Next focus item (non-tappable preview)
            if let nextItem = nextItems.first {
                HStack(spacing: 8) {
                    Text(Strings.Socialization.nextUp)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    Text(nextItem.localizedDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Progress Ring

    @ViewBuilder
    private var progressRing: some View {
        let progress = socializationStore.currentPhaseProgress

        ProgressRing(
            completed: progress.comfortable,
            total: progress.total,
            size: .standard
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Socialization.phaseProgress(comfortable: progress.comfortable, total: progress.total))
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
        .environmentObject(SocializationStore())
        .environmentObject(ProfileStore())
        .padding()
}
