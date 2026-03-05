//
//  CalendarContextHeader.swift
//  Ollie-app
//
//  Header showing puppy age and developmental context for the calendar view
//

import SwiftUI
import OtisShared

/// Header displaying age, developmental stage, and socialization status
struct CalendarContextHeader: View {
    let profile: PuppyProfile
    let forDate: Date
    let onDevelopmentTap: (() -> Void)?
    let onSocializationTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        let ageWeeks = ageInWeeks(birthDate: profile.birthDate, atDate: forDate)

        VStack(spacing: 8) {
            // Age row
            HStack(spacing: 12) {
                // Age badge
                HStack(spacing: 6) {
                    Text("\(ageWeeks)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.otisAccent)
                    Text(Strings.Common.weeks)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Developmental stage (tappable to open Development Journey)
                Button {
                    onDevelopmentTap?()
                } label: {
                    HStack(spacing: 4) {
                        Text(ageStageLabel(weeks: ageWeeks))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)

                        if onDevelopmentTap != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ageStageColor(weeks: ageWeeks))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(onDevelopmentTap == nil)
            }

            // Socialization banner (if in window)
            if SocializationWindow.isInWindow(ageWeeks: ageWeeks) {
                Button(action: onSocializationTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color.otisAccent)

                        Text(socializationBannerText(ageWeeks: ageWeeks))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        // Weeks remaining
                        let remaining = SocializationWindow.weeksRemaining(ageWeeks: ageWeeks)
                        if remaining <= 4 && remaining > 0 {
                            Text(Strings.Socialization.weeksRemaining(remaining))
                                .font(.caption2)
                                .foregroundStyle(remaining <= 2 ? Color.otisWarning : .secondary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.otisAccent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    /// Calculate age in weeks at a specific date
    private func ageInWeeks(birthDate: Date, atDate date: Date) -> Int {
        let components = calendar.dateComponents([.day], from: birthDate, to: date)
        let days = components.day ?? 0
        return max(0, days / 7)
    }

    private func socializationBannerText(ageWeeks: Int) -> String {
        let weekInWindow = ageWeeks - SocializationWindow.startWeek + 1
        let totalWeeks = SocializationWindow.endWeek - SocializationWindow.startWeek + 1
        return Strings.Calendar.socializationWeek(weekInWindow, of: totalWeeks)
    }

    private func ageStageLabel(weeks: Int) -> String {
        // Use canonical DevelopmentStage for consistent labeling
        let stage = DevelopmentStage.stage(for: weeks)
        return stage.title
    }

    private func ageStageColor(weeks: Int) -> Color {
        // Use canonical DevelopmentStage for consistent coloring
        let stage = DevelopmentStage.stage(for: weeks)
        return stage.color
    }
}

#Preview {
    let profileStore = ProfileStore()
    if let profile = profileStore.profile {
        CalendarContextHeader(
            profile: profile,
            forDate: Date(),
            onDevelopmentTap: { },
            onSocializationTap: { }
        )
        .padding()
    } else {
        Text("No profile available")
    }
}
