//
//  GrowthStoryCard.swift
//  Ollie-app
//
//  Main growth story card showing visual weight journey
//

import SwiftUI
import OllieShared

/// Main card displaying the puppy's growth story with visual elements
struct GrowthStoryCard: View {
    let growthStory: GrowthStory?
    let latestWeight: (weight: Double, date: Date)?
    let firstWeight: (weight: Double, date: Date)?
    let weightDelta: (delta: Double, previousDate: Date)?
    let weighReminder: WeighReminder?
    let puppyName: String
    let sizeCategory: PuppyProfile.SizeCategory
    @Binding var showWeightSheet: Bool

    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnitRaw = WeightUnit.kg.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InsightsSectionHeader(
                title: Strings.Growth.growthStory,
                icon: "chart.line.uptrend.xyaxis",
                tint: .ollieAccent
            )

            VStack(spacing: 16) {
                // Current weight hero (always shown if we have weight data)
                if let latest = latestWeight {
                    currentWeightHero(weight: latest.weight, date: latest.date)
                }

                // Weigh reminder banner (if due)
                if let reminder = weighReminder {
                    weighReminderBanner(reminder: reminder)
                }

                // Growth story or journey begins
                if let story = growthStory, story.isSignificant {
                    // Full growth story view
                    fullGrowthStoryView(story: story)
                } else if latestWeight == nil {
                    // Empty state (no weights)
                    emptyStateView
                }

                // Log weight button
                logWeightButton
            }
            .padding()
            .glassCard(tint: .accent)
        }
    }

    // MARK: - Current Weight Hero

    @ViewBuilder
    private func currentWeightHero(weight: Double, date: Date) -> some View {
        VStack(spacing: 8) {
            // Big weight number
            Text(weightUnit.format(weight))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Weight change badge (if available)
            if let delta = weightDelta {
                HStack(spacing: 4) {
                    Image(systemName: delta.delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(Strings.Growth.weightChange(weightUnit.formatDelta(delta.delta)))
                        .font(.caption)
                }
                .foregroundStyle(delta.delta >= 0 ? Color.ollieSuccess : Color.ollieWarning)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (delta.delta >= 0 ? Color.ollieSuccess : Color.ollieWarning)
                        .opacity(colorScheme == .dark ? 0.2 : 0.1)
                )
                .clipShape(Capsule())
            }

            // Date of last measurement
            Text(formattedDate(date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Weigh Reminder Banner

    @ViewBuilder
    private func weighReminderBanner(reminder: WeighReminder) -> some View {
        let isHighUrgency = reminder.urgency == .high
        let tintColor = isHighUrgency ? Color.ollieWarning : Color.ollieAccent

        HStack(spacing: 12) {
            Image(systemName: "scalemass.fill")
                .font(.title3)
                .foregroundStyle(tintColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Growth.timeToWeigh)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let days = reminder.daysSinceLastWeigh {
                    Text(Strings.Growth.lastWeighed(days))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(Strings.Growth.neverWeighed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                showWeightSheet = true
            } label: {
                Text(Strings.Growth.weighNow)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tintColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(tintColor.opacity(colorScheme == .dark ? 0.15 : 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Full Growth Story View

    @ViewBuilder
    private func fullGrowthStoryView(story: GrowthStory) -> some View {
        VStack(spacing: 16) {
            // Silhouette comparison
            GrowthSilhouetteView(
                firstWeight: story.firstWeight,
                currentWeight: story.currentWeight,
                weightUnit: weightUnit,
                animated: true
            )

            // Growth message
            Text(growthMessage(for: story))
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            // Timeline context
            Text(timelineContext(for: story))
                .font(.caption)
                .foregroundStyle(.secondary)

            // Progress arc to adult weight
            GrowthProgressArc(
                startWeight: story.firstWeight,
                currentWeight: story.currentWeight,
                estimatedAdultWeight: story.estimatedAdultWeight,
                weightUnit: weightUnit,
                animated: true
            )
            .padding(.top, 4)

            // Percent to adult badge
            percentToAdultBadge(percent: Int(story.percentToAdult))
        }
    }

    // MARK: - Journey Begins View

    @ViewBuilder
    private func journeyBeginsView(firstWeight: (weight: Double, date: Date)) -> some View {
        VStack(spacing: 12) {
            // Single dog icon
            Image(systemName: "dog.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.ollieAccent)

            Text(Strings.Growth.journeyBegins)
                .font(.headline)
                .fontWeight(.semibold)

            Text(weightUnit.format(firstWeight.weight))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(Strings.Growth.logSecondWeight)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State View

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dog")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(Strings.Health.noWeightData)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Strings.Growth.logFirstWeight)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Log Weight Button

    @ViewBuilder
    private var logWeightButton: some View {
        Button {
            showWeightSheet = true
        } label: {
            Label(Strings.Growth.logWeight, systemImage: "plus.circle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
        .cornerRadius(8)
    }

    // MARK: - Percent to Adult Badge

    @ViewBuilder
    private func percentToAdultBadge(percent: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.forward")
                .font(.caption2)
            Text(Strings.Growth.percentOfAdult(percent))
                .font(.caption)
        }
        .foregroundStyle(Color.ollieAccent)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
        .clipShape(Capsule())
    }

    // MARK: - Helper Methods

    private func growthMessage(for story: GrowthStory) -> String {
        let ratio = story.growthRatio

        if ratio >= 2.95 {
            return Strings.Growth.tripledWeight(name: puppyName)
        } else if ratio >= 1.95 {
            return Strings.Growth.doubledWeight(name: puppyName)
        } else if ratio >= 1.45 {
            return Strings.Growth.grewOneAndHalf(name: puppyName)
        } else {
            let percentGrowth = Int((ratio - 1.0) * 100)
            return Strings.Growth.grewBy(name: puppyName, percent: percentGrowth)
        }
    }

    private func timelineContext(for story: GrowthStory) -> String {
        let days = story.daysSinceFirst

        if days < 14 {
            return Strings.Growth.inDays(days)
        } else {
            let weeks = days / 7
            return Strings.Growth.inWeeks(weeks)
        }
    }
}

// MARK: - Preview

#Preview("Full Growth Story") {
    let story = GrowthStory(
        firstWeight: 4.0,
        firstWeightDate: Date().addingTimeInterval(-60 * 24 * 3600),
        currentWeight: 8.1,
        currentWeightDate: Date(),
        growthRatio: 2.025,
        estimatedAdultWeight: 27.0,
        percentToAdult: 30.0,
        daysSinceFirst: 60
    )

    ScrollView {
        GrowthStoryCard(
            growthStory: story,
            latestWeight: (8.1, Date()),
            firstWeight: (4.0, Date().addingTimeInterval(-60 * 24 * 3600)),
            weightDelta: (0.8, Date().addingTimeInterval(-7 * 24 * 3600)),
            weighReminder: nil,
            puppyName: "Ollie",
            sizeCategory: .large,
            showWeightSheet: .constant(false)
        )
        .padding()
    }
}

#Preview("With Weigh Reminder") {
    ScrollView {
        GrowthStoryCard(
            growthStory: nil,
            latestWeight: (7.5, Date().addingTimeInterval(-14 * 24 * 3600)),
            firstWeight: (4.5, Date().addingTimeInterval(-30 * 24 * 3600)),
            weightDelta: (1.2, Date().addingTimeInterval(-21 * 24 * 3600)),
            weighReminder: WeighReminder(urgency: .medium, daysSinceLastWeigh: 14, recommendedIntervalDays: 7),
            puppyName: "Ollie",
            sizeCategory: .large,
            showWeightSheet: .constant(false)
        )
        .padding()
    }
}

#Preview("Journey Begins") {
    ScrollView {
        GrowthStoryCard(
            growthStory: nil,
            latestWeight: (4.5, Date()),
            firstWeight: (4.5, Date()),
            weightDelta: nil,
            weighReminder: nil,
            puppyName: "Ollie",
            sizeCategory: .large,
            showWeightSheet: .constant(false)
        )
        .padding()
    }
}

#Preview("Empty State") {
    ScrollView {
        GrowthStoryCard(
            growthStory: nil,
            latestWeight: nil,
            firstWeight: nil,
            weightDelta: nil,
            weighReminder: WeighReminder(urgency: .high, daysSinceLastWeigh: nil, recommendedIntervalDays: 7),
            puppyName: "Ollie",
            sizeCategory: .large,
            showWeightSheet: .constant(false)
        )
        .padding()
    }
}
