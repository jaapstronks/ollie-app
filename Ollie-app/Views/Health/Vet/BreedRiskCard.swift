//
//  BreedRiskCard.swift
//  Ollie-app
//
//  Displays breed-specific health risks and screening recommendations.
//

import SwiftUI
import OtisShared

/// Card showing breed-specific health risks and screening status
struct BreedRiskCard: View {
    let breedRisks: BreedHealthRisk?
    let sizeRisks: [ConditionRisk]
    let existingConditions: [HealthCondition]
    let ageMonths: Int
    let onScheduleScreening: (ConditionRisk) -> Void

    @State private var isExpanded = false

    private var undiagnosedRisks: [ConditionRisk] {
        let diagnosedTypes = Set(existingConditions.map { $0.type })
        var risks: [ConditionRisk] = []

        if let breedRisks = breedRisks {
            risks.append(contentsOf: breedRisks.risks.filter { !diagnosedTypes.contains($0.conditionType) })
        }

        // Add size risks not in breed risks
        let breedRiskTypes = Set(risks.map { $0.conditionType })
        let filteredSizeRisks = sizeRisks.filter {
            !diagnosedTypes.contains($0.conditionType) && !breedRiskTypes.contains($0.conditionType)
        }
        risks.append(contentsOf: filteredSizeRisks)

        return risks.sorted { $0.riskLevel.rawValue > $1.riskLevel.rawValue }
    }

    private var screeningsDue: [ConditionRisk] {
        undiagnosedRisks.filter { risk in
            guard let screeningAge = risk.screeningRecommendedAgeMonths else { return false }
            return ageMonths >= screeningAge - 3 && ageMonths <= screeningAge + 6
        }
    }

    var body: some View {
        if !undiagnosedRisks.isEmpty || breedRisks != nil {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "pawprint.fill")
                            .font(.title2)
                            .foregroundStyle(Color.otisWarning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.VetVisit.BreedRisks.awareness)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            if let breedName = breedRisks?.breedName {
                                Text(breedName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Due screenings badge
                        if !screeningsDue.isEmpty {
                            Text("\(screeningsDue.count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.otisDanger)
                                .clipShape(Capsule())
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        // Due screenings (high priority)
                        if !screeningsDue.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(Strings.VetVisit.Milestones.breedScreenings)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.otisDanger)

                                ForEach(screeningsDue, id: \.conditionType) { risk in
                                    screeningDueRow(risk)
                                }
                            }
                            .padding()
                            .background(Color.otisDanger.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Other risks
                        let otherRisks = undiagnosedRisks.filter { !screeningsDue.contains($0) }
                        if !otherRisks.isEmpty {
                            ForEach(otherRisks.prefix(5), id: \.conditionType) { risk in
                                riskRow(risk)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Row Components

    private func screeningDueRow(_ risk: ConditionRisk) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: risk.conditionType.icon)
                    .foregroundStyle(Color.otisDanger)

                Text(risk.conditionType.label)
                    .font(.subheadline.weight(.medium))

                Spacer()

                riskBadge(risk.riskLevel)
            }

            if !risk.warningsToWatch.isEmpty {
                Text(risk.warningsToWatch.prefix(2).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                onScheduleScreening(risk)
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text(Strings.VetVisit.BreedRisks.scheduleScreening)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.otisAccent)
                .clipShape(Capsule())
            }
        }
    }

    private func riskRow(_ risk: ConditionRisk) -> some View {
        HStack(spacing: 12) {
            Image(systemName: risk.conditionType.icon)
                .font(.title3)
                .foregroundStyle(riskColor(risk.riskLevel))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(risk.conditionType.label)
                    .font(.subheadline)

                HStack(spacing: 8) {
                    riskBadge(risk.riskLevel)

                    if let onsetRange = risk.typicalOnsetAgeRange {
                        Text(onsetRange)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func riskBadge(_ level: RiskLevel) -> some View {
        Text(Strings.VetVisit.BreedRisks.riskLevel(level.rawValue.capitalized))
            .font(.caption2.weight(.medium))
            .foregroundStyle(riskColor(level))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(riskColor(level).opacity(0.15))
            .clipShape(Capsule())
    }

    private func riskColor(_ level: RiskLevel) -> Color {
        switch level {
        case .veryHigh: return Color.otisDanger
        case .high: return .orange
        case .moderate: return Color.otisWarning
        case .low: return Color.otisInfo
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        BreedRiskCard(
            breedRisks: BreedHealthRisk.risks(for: "Golden Retriever"),
            sizeRisks: BreedHealthRisk.sizeBasedRisks(for: .large),
            existingConditions: [],
            ageMonths: 24,
            onScheduleScreening: { _ in }
        )
        .padding()
    }
}
