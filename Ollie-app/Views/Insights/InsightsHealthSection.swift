//
//  InsightsHealthSection.swift
//  Ollie-app
//
//  Health section with weight tracking
//

import SwiftUI
import OllieShared

/// Health section showing weight tracking
struct InsightsHealthSection: View {
    let latestWeight: (weight: Double, date: Date)?
    let weightDelta: (delta: Double, previousDate: Date)?
    @ObservedObject var viewModel: TimelineViewModel
    @Binding var showWeightSheet: Bool
    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnitRaw = WeightUnit.kg.rawValue

    @Environment(\.colorScheme) private var colorScheme

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InsightsSectionHeader(
                title: Strings.Health.weight,
                icon: "scalemass.fill",
                tint: .ollieAccent
            )

            // Weight summary card
            VStack(spacing: 12) {
                if let latest = latestWeight {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.Health.weight)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(weightUnit.format(latest.weight))
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        // Delta badge
                        if let delta = weightDelta {
                            HStack(spacing: 4) {
                                Image(systemName: delta.delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption)
                                    .accessibilityHidden(true)
                                Text(weightUnit.formatDelta(delta.delta))
                                    .font(.caption)
                            }
                            .foregroundStyle(delta.delta >= 0 ? Color.ollieSuccess : Color.ollieWarning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (delta.delta >= 0 ? Color.ollieSuccess : Color.ollieWarning)
                                    .opacity(colorScheme == .dark ? 0.2 : 0.1)
                            )
                            .clipShape(Capsule())
                            .accessibilityLabel(delta.delta >= 0 ? Strings.Health.weightIncreased(weightUnit.formatDelta(delta.delta)) : Strings.Health.weightDecreased(weightUnit.formatDelta(abs(delta.delta))))
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Strings.Health.currentWeight(weightUnit.format(latest.weight)))

                    // Log weight button
                    Button {
                        showWeightSheet = true
                    } label: {
                        Label(Strings.Health.logWeight, systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .cornerRadius(8)
                } else {
                    // Empty state
                    VStack(spacing: 8) {
                        Text(Strings.Health.noWeightData)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            showWeightSheet = true
                        } label: {
                            Label(Strings.Health.logWeight, systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.glassPill(tint: .accent))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding()
            .glassCard(tint: .accent)
        }
    }
}
