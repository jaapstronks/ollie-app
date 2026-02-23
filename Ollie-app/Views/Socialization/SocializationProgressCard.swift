//
//  SocializationProgressCard.swift
//  Ollie-app
//
//  Overall progress card for socialization checklist

import SwiftUI

/// Card showing overall socialization progress and window status
struct SocializationProgressCard: View {
    @EnvironmentObject var socializationStore: SocializationStore
    @EnvironmentObject var profileStore: ProfileStore

    @Environment(\.colorScheme) private var colorScheme

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var windowStatus: SocializationWindowStatus {
        guard let profile = profile else { return .closed }
        return SocializationWindowStatus(ageInWeeks: profile.ageInWeeks)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(Color.ollieAccent)
                Text(Strings.Socialization.sectionTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Strings.Socialization.progressLabel(
                        current: socializationStore.totalComfortable,
                        total: socializationStore.totalItems
                    ))
                    .font(.title2)
                    .fontWeight(.bold)

                    Spacer()

                    Text("\(Int(progressPercentage * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * progressPercentage, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Window status banner
            if windowStatus.showBanner {
                windowStatusBanner
            }
        }
        .padding()
        .glassCard(tint: .accent)
    }

    // MARK: - Computed Properties

    private var progressPercentage: Double {
        guard socializationStore.totalItems > 0 else { return 0 }
        return Double(socializationStore.totalComfortable) / Double(socializationStore.totalItems)
    }

    private var progressColor: Color {
        switch progressPercentage {
        case 0..<0.25: return .ollieWarning
        case 0.25..<0.5: return .orange
        case 0.5..<0.75: return .yellow
        default: return .ollieSuccess
        }
    }

    // MARK: - Window Status Banner

    @ViewBuilder
    private var windowStatusBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: windowStatusIcon)
                .font(.system(size: 14, weight: .semibold))

            Text(windowStatus.message)
                .font(.caption)
                .fontWeight(.medium)

            if let weeks = weeksRemaining {
                Spacer()
                Text(Strings.Socialization.weeksRemaining(weeks))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(windowStatusForeground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(windowStatusBackground)
        )
    }

    private var windowStatusIcon: String {
        switch windowStatus {
        case .peak: return "star.fill"
        case .open: return "clock.fill"
        case .closing: return "exclamationmark.triangle.fill"
        case .justClosed: return "clock.arrow.circlepath"
        case .closed: return "checkmark.circle.fill"
        }
    }

    private var windowStatusForeground: Color {
        switch windowStatus {
        case .peak: return .white
        case .open: return .white
        case .closing: return .black
        case .justClosed: return .black
        case .closed: return .secondary
        }
    }

    private var windowStatusBackground: Color {
        switch windowStatus {
        case .peak: return .green
        case .open: return .blue
        case .closing: return .orange
        case .justClosed: return .yellow
        case .closed: return .secondary.opacity(0.2)
        }
    }

    private var weeksRemaining: Int? {
        guard let profile = profile else { return nil }
        let targetWeek = 16
        let remaining = targetWeek - profile.ageInWeeks
        return remaining > 0 ? remaining : nil
    }
}

// MARK: - Preview

#Preview {
    SocializationProgressCard()
        .environmentObject(SocializationStore())
        .environmentObject(ProfileStore())
        .padding()
}
