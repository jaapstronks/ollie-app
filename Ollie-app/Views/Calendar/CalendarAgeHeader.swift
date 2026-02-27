//
//  CalendarAgeHeader.swift
//  Ollie-app
//
//  Age header component showing weeks old, days home, and age stage badge

import SwiftUI
import OllieShared

/// Displays puppy age information with weeks old, days home, and developmental stage
struct CalendarAgeHeader: View {
    let profile: PuppyProfile

    var body: some View {
        VStack(spacing: 8) {
            // Puppy name and age
            HStack(spacing: 16) {
                // Weeks old
                VStack(spacing: 2) {
                    Text("\(profile.ageInWeeks)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ollieAccent)
                    Text(Strings.Common.weeks)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 36)

                // Days home
                VStack(spacing: 2) {
                    Text("\(profile.daysHome)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ollieSuccess)
                    Text(Strings.Common.days)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Age stage badge
                Text(ageStageLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ageStageColor)
                    .clipShape(Capsule())
            }

            // Readable age text
            Text(ageDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(tint: .accent)
    }

    // MARK: - Computed Properties

    private var ageDescription: String {
        let months = profile.ageInWeeks / 4
        if months >= 2 {
            return Strings.PlanTab.monthsOld(months)
        } else {
            return Strings.PlanTab.weeksOld(profile.ageInWeeks)
        }
    }

    private var ageStageLabel: String {
        let weeks = profile.ageInWeeks
        if weeks < 8 {
            return Strings.PlanTab.ageStageNewborn
        } else if weeks <= 16 {
            return Strings.PlanTab.ageStageSocialization
        } else if weeks <= 26 {
            return Strings.PlanTab.ageStageJuvenile
        } else if weeks <= 52 {
            return Strings.PlanTab.ageStageAdolescent
        } else {
            return Strings.PlanTab.ageStageAdult
        }
    }

    private var ageStageColor: Color {
        let weeks = profile.ageInWeeks
        if weeks < 8 {
            return .ollieSleep
        } else if weeks <= 16 {
            return .ollieAccent
        } else if weeks <= 26 {
            return .ollieInfo
        } else if weeks <= 52 {
            return .ollieSuccess
        } else {
            return .secondary
        }
    }
}

#Preview {
    let profileStore = ProfileStore()

    // Preview with a sample profile when available
    if let profile = profileStore.profile {
        CalendarAgeHeader(profile: profile)
            .padding()
    } else {
        Text("No profile available")
            .padding()
    }
}
