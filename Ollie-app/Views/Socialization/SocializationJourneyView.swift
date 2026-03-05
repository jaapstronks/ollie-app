//
//  SocializationJourneyView.swift
//  Otis-app
//
//  Action-focused view for logging socialization exposures

import SwiftUI
import OtisShared

/// Pure action view: a checklist to work through, with logging
struct SocializationJourneyView: View {
    @EnvironmentObject var socializationStore: SocializationStore
    @EnvironmentObject var profileStore: ProfileStore

    @Environment(\.colorScheme) private var colorScheme

    @State private var isQuickCheckMode = false
    @State private var showingInfoSheet = false
    @State private var showingQuickInventory = false

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var currentPhase: SocializationPhase {
        socializationStore.currentPhase
    }

    private var isFirstVisit: Bool {
        !socializationStore.hasAnyExposures && !socializationStore.hasAnyComfortableItems
    }

    private var totalExposures: Int {
        socializationStore.allExposures.count
    }

    private var weeksRemaining: Int? {
        guard let ageInWeeks = profile?.ageInWeeks else { return nil }
        return SocializationWindowStatus.weeksRemaining(ageInWeeks: ageInWeeks)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Compact status header with link to sheet
                statusHeader
                    .padding(.horizontal)

                // First visit prompt
                if isFirstVisit && currentPhase != .settlingIn {
                    firstVisitCard
                }

                // Current phase content
                currentPhaseSection

                // Later phases (collapsed)
                laterPhasesSection
            }
            .padding(.vertical)
        }
        .navigationTitle(Strings.Socialization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    // Quick check toggle
                    if currentPhase != .settlingIn {
                        Button {
                            withAnimation {
                                isQuickCheckMode.toggle()
                            }
                            HapticFeedback.selection()
                        } label: {
                            Image(systemName: isQuickCheckMode ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundStyle(isQuickCheckMode ? Color.otisAccent : .secondary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingInfoSheet) {
            SocializationWindowSheet()
        }
        .sheet(isPresented: $showingQuickInventory) {
            QuickInventorySheet()
        }
    }

    // MARK: - Status Header

    @ViewBuilder
    private var statusHeader: some View {
        HStack {
            // Compact progress summary
            HStack(spacing: 8) {
                Text(Strings.Socialization.exposureCount(totalExposures))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let weeks = weeksRemaining, weeks > 0 {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(Strings.Socialization.weeksRemaining(weeks))
                        .font(.subheadline)
                        .foregroundStyle(weeks <= 4 ? Color.otisWarning : .secondary)
                }
            }

            Spacer()

            // Link to full progress sheet
            Button {
                showingInfoSheet = true
            } label: {
                HStack(spacing: 4) {
                    Text(Strings.Socialization.viewFullProgress)
                        .font(.subheadline)
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .foregroundStyle(Color.otisAccent)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - First Visit Card

    @ViewBuilder
    private var firstVisitCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.otisAccent)

            Text(Strings.Socialization.firstVisitTitle)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(Strings.Socialization.firstVisitSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingQuickInventory = true
            } label: {
                Text(Strings.Socialization.quickCheckButton)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

            Button {
                // Just dismiss the card by doing nothing
            } label: {
                Text(Strings.Socialization.startFresh)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Current Phase Section

    @ViewBuilder
    private var currentPhaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header - simplified, no phase description
            HStack {
                Image(systemName: currentPhase.icon)
                    .foregroundStyle(Color.otisAccent)
                Text(phaseName(for: currentPhase))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if currentPhase != .settlingIn {
                    let progress = socializationStore.currentPhaseProgress
                    Text(Strings.Socialization.phaseProgress(comfortable: progress.comfortable, total: progress.total))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Quick check mode indicator
            if isQuickCheckMode {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text(Strings.Socialization.quickCheckModeDesc)
                        .font(.caption)
                }
                .foregroundStyle(Color.otisAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.otisAccent.opacity(0.15))
                )
            }

            // Content based on phase
            if currentPhase == .settlingIn {
                earlyMilestonesSection
            } else {
                phaseItemsList(for: currentPhase)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Early Milestones Section

    @ViewBuilder
    private var earlyMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Socialization.earlyMilestonesTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            ForEach(socializationStore.milestoneDefinitions, id: \.id) { milestone in
                let isAchieved = socializationStore.isMilestoneAchieved(milestone.id)

                HStack(spacing: 12) {
                    Image(systemName: isAchieved ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isAchieved ? Color.otisSuccess : .secondary)

                    Text(localizedMilestoneName(milestone.id))
                        .font(.subheadline)
                        .foregroundStyle(isAchieved ? .secondary : .primary)
                        .strikethrough(isAchieved)

                    Spacer()

                    if isAchieved {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundStyle(Color.otisSuccess)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        socializationStore.toggleMilestone(milestone.id)
                        HapticFeedback.selection()
                    }
                }
            }
        }
    }

    // MARK: - Phase Items List

    @ViewBuilder
    private func phaseItemsList(for phase: SocializationPhase) -> some View {
        let items = socializationStore.items(for: phase)
        let sortedItems = items.sorted { item1, item2 in
            // Sort: in progress > not comfortable > comfortable
            let comfortable1 = socializationStore.isComfortable(itemId: item1.id)
            let comfortable2 = socializationStore.isComfortable(itemId: item2.id)
            let progress1 = socializationStore.progressFraction(for: item1.id)
            let progress2 = socializationStore.progressFraction(for: item2.id)

            if comfortable1 != comfortable2 {
                return !comfortable1 // Not comfortable first
            }
            if progress1 > 0 && progress2 == 0 { return true } // In progress first
            if progress2 > 0 && progress1 == 0 { return false }
            return item1.priority > item2.priority // Then by priority
        }

        LazyVStack(spacing: 8) {
            ForEach(sortedItems, id: \.id) { item in
                PhaseItemRow(
                    item: item,
                    isQuickCheckMode: isQuickCheckMode
                )
            }
        }
    }

    // MARK: - Later Phases Section

    @ViewBuilder
    private var laterPhasesSection: some View {
        let laterPhases = SocializationPhase.allCases.filter { $0.sortOrder > currentPhase.sortOrder }

        if !laterPhases.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Socialization.laterPhases)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                ForEach(laterPhases, id: \.rawValue) { phase in
                    DisclosureGroup {
                        phaseItemsList(for: phase)
                            .padding(.top, 8)
                    } label: {
                        HStack {
                            Image(systemName: phase.icon)
                                .foregroundStyle(.secondary)
                            Text(phaseName(for: phase))
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            let items = socializationStore.items(for: phase)
                            let comfortable = items.filter { socializationStore.isComfortable(itemId: $0.id) }.count
                            Text("\(comfortable)/\(items.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helpers

    private func phaseName(for phase: SocializationPhase) -> String {
        switch phase {
        case .settlingIn: return Strings.Socialization.phaseSettlingIn
        case .firstSteps: return Strings.Socialization.phaseFirstSteps
        case .buildingConfidence: return Strings.Socialization.phaseBuildingConfidence
        case .peakWindow: return Strings.Socialization.phasePeakWindow
        case .maintenance: return Strings.Socialization.phaseMaintenance
        }
    }

    private func phaseDescription(for phase: SocializationPhase) -> String {
        switch phase {
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

// MARK: - Phase Item Row

private struct PhaseItemRow: View {
    let item: SocializationItem
    let isQuickCheckMode: Bool

    @EnvironmentObject var socializationStore: SocializationStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingLogSheet = false

    private var isComfortable: Bool {
        socializationStore.isComfortable(itemId: item.id)
    }

    private var progressFraction: Double {
        socializationStore.progressFraction(for: item.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            if isQuickCheckMode {
                Image(systemName: isComfortable ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isComfortable ? Color.otisSuccess : .secondary)
                    .font(.title3)
            } else {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 28, height: 28)
            }

            // Item name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.localizedDisplayName)
                    .font(.subheadline)
                    .foregroundStyle(isComfortable ? .secondary : .primary)
                    .strikethrough(isComfortable && isQuickCheckMode)

                if let description = item.description, !isQuickCheckMode {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Exposures count (non-quick mode)
            if !isQuickCheckMode && !isComfortable {
                let exposures = socializationStore.getExposures(for: item.id)
                let positiveCount = exposures.filter { $0.reaction.isPositive }.count
                Text("\(positiveCount)/\(item.targetExposures)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Comfortable badge
            if isComfortable && !isQuickCheckMode {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.otisSuccess)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isQuickCheckMode {
                withAnimation(.easeInOut(duration: 0.2)) {
                    socializationStore.toggleComfortable(item.id)
                    HapticFeedback.selection()
                }
            } else {
                showingLogSheet = true
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            LogExposureSheet(item: item)
        }
    }

    private var progressColor: Color {
        if isComfortable {
            return .otisSuccess
        } else if progressFraction > 0 {
            return .otisAccent
        }
        return .secondary
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SocializationJourneyView()
            .environmentObject(SocializationStore())
            .environmentObject(ProfileStore())
    }
}
