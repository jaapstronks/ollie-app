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

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var currentPhase: SocializationPhase {
        socializationStore.currentPhase
    }

    private var daysHome: Int {
        profile?.daysHome ?? 0
    }

    var body: some View {
        NavigationLink {
            SocializationJourneyView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(Color.otisAccent)
                        .accessibilityHidden(true)
                    Text(Strings.Socialization.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()

                    // Info button (opens What is Socialization sheet)
                    Button {
                        // This will be handled by sheet modifier on parent
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Strings.Socialization.infoTitle)
                }

                // Phase header with day/week and phase name
                phaseHeader

                // Content based on phase
                if currentPhase == .settlingIn {
                    earlyMilestonesContent
                } else {
                    progressContent
                }

                // See journey link
                Divider()

                HStack {
                    Text(Strings.Socialization.seeYourJourney)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.otisAccent)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .glassCard(tint: .accent)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Phase Header

    @ViewBuilder
    private var phaseHeader: some View {
        HStack {
            // Day/Week indicator
            VStack(alignment: .leading, spacing: 2) {
                if daysHome <= 14 {
                    Text(Strings.Socialization.dayNumber(daysHome))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                } else {
                    let weeks = (daysHome / 7) + 1
                    Text(Strings.Socialization.weekNumber(weeks))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Text(phaseName)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Progress ring (not for settling in)
            if currentPhase != .settlingIn {
                progressRing
            }
        }

        // Phase description
        Text(phaseDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
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
            // Progress text
            Text(Strings.Socialization.phaseProgress(comfortable: progress.comfortable, total: progress.total))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Next focus item
            if let nextItem = nextItems.first {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(Color.otisAccent)
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Socialization.nextUp)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)

                        Text(nextItem.localizedDisplayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.otisAccent.opacity(colorScheme == .dark ? 0.15 : 0.08))
                )
            }
        }
    }

    // MARK: - Progress Ring

    @ViewBuilder
    private var progressRing: some View {
        let progress = socializationStore.currentPhaseProgress
        let fraction = progress.total > 0 ? CGFloat(progress.comfortable) / CGFloat(progress.total) : 0

        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.otisAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(progress.comfortable)/\(progress.total)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 48, height: 48)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Socialization.phaseProgress(comfortable: progress.comfortable, total: progress.total))
    }

    // MARK: - Helpers

    private var phaseName: String {
        switch currentPhase {
        case .settlingIn: return Strings.Socialization.phaseSettlingIn
        case .firstSteps: return Strings.Socialization.phaseFirstSteps
        case .buildingConfidence: return Strings.Socialization.phaseBuildingConfidence
        case .peakWindow: return Strings.Socialization.phasePeakWindow
        case .maintenance: return Strings.Socialization.phaseMaintenance
        }
    }

    private var phaseDescription: String {
        switch currentPhase {
        case .settlingIn: return Strings.Socialization.phaseSettlingInDesc
        case .firstSteps: return Strings.Socialization.phaseFirstStepsDesc
        case .buildingConfidence: return Strings.Socialization.phaseBuildingConfidenceDesc
        case .peakWindow: return Strings.Socialization.phasePeakWindowDesc
        case .maintenance: return Strings.Socialization.phaseMaintenanceDesc
        }
    }

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
