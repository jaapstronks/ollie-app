//
//  SocializationWindowSheet.swift
//  Otis-app
//
//  Comprehensive sheet for the socialization window - single source of truth
//  Merges content from WhatIsSocializationSheet and adds progress tracking
//

import SwiftUI
import OtisShared

/// Comprehensive sheet showing socialization window status, progress, and guidance
struct SocializationWindowSheet: View {
    @Environment(SocializationStore.self) var socializationStore
    @Environment(ProfileStore.self) var profileStore

    var onNavigateToDevelopment: (() -> Void)?
    var onLogExposure: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var ageInWeeks: Int {
        profile?.ageInWeeks ?? 0
    }

    private var windowStatus: SocializationWindowStatus {
        SocializationWindowStatus(ageInWeeks: ageInWeeks)
    }

    private var weeksRemaining: Int? {
        SocializationWindowStatus.weeksRemaining(ageInWeeks: ageInWeeks)
    }

    private var windowProgress: Double {
        SocializationWindowStatus.progressPercentage(ageInWeeks: ageInWeeks)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero window status card
                    windowStatusCard

                    // Week timeline
                    if windowStatus.isOpen || windowStatus == .justClosed {
                        weekTimelineSection
                    }

                    // Category progress breakdown
                    categoryProgressSection

                    // Current phase info
                    currentPhaseSection

                    // Focus suggestions
                    if !socializationStore.nextFocusItems.isEmpty {
                        focusSuggestionsSection
                    }

                    // Educational content (collapsed by default)
                    educationalSection

                    // Cross-links
                    crossLinksSection
                }
                .padding()
            }
            .navigationTitle(Strings.Socialization.socializationWindowTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Window Status Card

    @ViewBuilder
    private var windowStatusCard: some View {
        VStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: statusIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(statusColor)
            }

            // Status text
            VStack(spacing: 4) {
                Text(windowStatus.message)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)

                if let weeks = weeksRemaining, weeks > 0 {
                    Text(Strings.Socialization.weeksRemaining(weeks))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            if windowStatus.isOpen {
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor)
                                .frame(width: geometry.size.width * windowProgress)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text(Strings.Socialization.weekNumber(SocializationWindow.startWeek))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text(Strings.Socialization.weekNumber(SocializationWindow.endWeek))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: 200)
            }

            // Overall progress
            HStack(spacing: 20) {
                progressStat(
                    value: "\(socializationStore.totalComfortable)",
                    label: Strings.Socialization.comfortable,
                    icon: "checkmark.circle.fill",
                    color: .otisSuccess
                )

                progressStat(
                    value: "\(socializationStore.allExposures.count)",
                    label: Strings.Socialization.exposureCount(socializationStore.allExposures.count),
                    icon: "eye.fill",
                    color: .otisAccent
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(statusColor.opacity(colorScheme == .dark ? 0.1 : 0.05))
        )
    }

    @ViewBuilder
    private func progressStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Week Timeline Section

    @ViewBuilder
    private var weekTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Socialization.socializationWindowTitle)
                .font(.headline)
                .fontWeight(.semibold)

            // Simplified week indicators
            HStack(spacing: 4) {
                ForEach(SocializationWindow.allWeeks, id: \.self) { week in
                    weekIndicator(week: week)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func weekIndicator(week: Int) -> some View {
        let isCurrent = week == ageInWeeks
        let isPast = week < ageInWeeks
        let isPeak = week <= SocializationWindowStatus.peakEndWeek

        VStack(spacing: 4) {
            Text("\(week)")
                .font(.caption2)
                .fontWeight(isCurrent ? .bold : .regular)
                .foregroundStyle(isCurrent ? .primary : .secondary)

            Circle()
                .fill(indicatorColor(isCurrent: isCurrent, isPast: isPast, isPeak: isPeak))
                .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
                .overlay {
                    if isCurrent {
                        Circle()
                            .stroke(statusColor, lineWidth: 2)
                            .frame(width: 16, height: 16)
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func indicatorColor(isCurrent: Bool, isPast: Bool, isPeak: Bool) -> Color {
        if isCurrent {
            return statusColor
        } else if isPast {
            return isPeak ? .otisSuccess.opacity(0.6) : .otisAccent.opacity(0.5)
        } else {
            return .secondary.opacity(0.3)
        }
    }

    // MARK: - Category Progress Section

    @ViewBuilder
    private var categoryProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Socialization.categories)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(socializationStore.categories, id: \.id) { category in
                    let comfortable = category.items.filter { socializationStore.isComfortable(itemId: $0.id) }.count
                    let total = category.items.count

                    HStack {
                        Image(systemName: category.icon)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        Text(category.localizedName)
                            .font(.subheadline)

                        Spacer()

                        Text(Strings.Socialization.categoryProgress(completed: comfortable, total: total))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Mini progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.2))
                                Capsule()
                                    .fill(comfortable == total ? Color.otisSuccess : Color.otisAccent)
                                    .frame(width: geo.size.width * CGFloat(comfortable) / CGFloat(max(1, total)))
                            }
                        }
                        .frame(width: 60, height: 6)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Current Phase Section

    @ViewBuilder
    private var currentPhaseSection: some View {
        let phase = socializationStore.currentPhase
        let progress = socializationStore.currentPhaseProgress

        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Socialization.current)
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                Image(systemName: phase.icon)
                    .font(.title2)
                    .foregroundStyle(Color.otisAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.otisAccent.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.localizedName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(phase.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(Strings.Socialization.phaseProgress(comfortable: progress.comfortable, total: progress.total))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Focus Suggestions Section

    @ViewBuilder
    private var focusSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Socialization.nextUp)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(socializationStore.nextFocusItems, id: \.id) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.otisAccent.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.otisAccent)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.localizedDisplayName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if let description = item.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Log exposure action
            if let onLog = onLogExposure {
                Button(action: {
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.3))
                        onLog()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(Strings.Socialization.logExposure)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Educational Section

    @State private var showEducation = false

    @ViewBuilder
    private var educationalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showEducation.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(Color.otisAccent)
                    Text(Strings.Socialization.infoTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showEducation ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showEducation {
                VStack(alignment: .leading, spacing: 16) {
                    educationItem(
                        icon: "target",
                        title: Strings.Socialization.infoGoalTitle,
                        body: Strings.Socialization.infoGoalBody,
                        color: .otisAccent
                    )

                    educationItem(
                        icon: "checkmark.circle",
                        title: Strings.Socialization.infoPositiveTitle,
                        body: Strings.Socialization.infoPositiveBody,
                        color: .otisSuccess
                    )

                    educationItem(
                        icon: "ruler",
                        title: Strings.Socialization.infoDistanceTitle,
                        body: Strings.Socialization.infoDistanceBody,
                        color: .otisInfo
                    )

                    Text(Strings.Socialization.infoSummary)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.otisAccent)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.otisAccent.opacity(colorScheme == .dark ? 0.15 : 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func educationItem(icon: String, title: String, body: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(body)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Cross-links Section

    @ViewBuilder
    private var crossLinksSection: some View {
        if let onNavigate = onNavigateToDevelopment {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Common.seeAlso)
                    .font(.headline)
                    .fontWeight(.semibold)

                Button {
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.3))
                        onNavigate()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.otisPurple.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.otisPurple)
                        }

                        Text(Strings.Development.roadmapTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch windowStatus {
        case .peak: return .otisSuccess
        case .closing: return .otisWarning
        case .justClosed: return .orange
        case .closed: return .secondary
        }
    }

    private var statusIcon: String {
        switch windowStatus {
        case .peak: return "star.fill"
        case .closing: return "exclamationmark.triangle.fill"
        case .justClosed: return "clock.arrow.circlepath"
        case .closed: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    SocializationWindowSheet(
        onNavigateToDevelopment: { print("Navigate to development") },
        onLogExposure: { print("Log exposure") }
    )
    .environment(SocializationStore())
    .environment(ProfileStore())
}
