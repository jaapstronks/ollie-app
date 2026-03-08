//
//  VetVisitTipGenerator.swift
//  Ollie-app
//
//  Generates contextual tips for upcoming vet visits based on
//  breed, age, conditions, and recent symptoms.
//

import Foundation
import OtisShared

/// Generates contextual tips for discussing with the vet during an upcoming visit.
class VetVisitTipGenerator {

    // MARK: - Main Generation

    /// Generate all relevant tips for an upcoming vet visit
    func generateTips(
        for profile: PuppyProfile,
        appointment: DogAppointment,
        recentSymptoms: [HealthSymptomLog],
        conditions: [HealthCondition]
    ) -> [VetVisitTip] {
        var tips: [VetVisitTip] = []

        // Age-related tips
        tips.append(contentsOf: ageTips(for: profile))

        // Breed-specific tips
        tips.append(contentsOf: breedTips(for: profile))

        // Condition-related tips
        tips.append(contentsOf: conditionTips(for: conditions))

        // Recent symptom tips
        tips.append(contentsOf: symptomTips(from: recentSymptoms))

        // Preventive care tips based on lifecycle
        tips.append(contentsOf: preventiveTips(for: profile))

        // Sort by priority (highest first)
        return tips.sortedByPriority()
    }

    // MARK: - Age-Based Tips

    private func ageTips(for profile: PuppyProfile) -> [VetVisitTip] {
        var tips: [VetVisitTip] = []
        let ageMonths = profile.ageInMonths

        // Puppy phase (0-12 months)
        if ageMonths < 12 {
            if ageMonths < 4 {
                tips.append(VetVisitTip(
                    category: .ageRelated,
                    title: Strings.VetVisit.Tips.puppyVaccinationTitle,
                    description: Strings.VetVisit.Tips.puppyVaccinationDescription,
                    source: .age(months: ageMonths),
                    priority: .high
                ))
            }

            tips.append(VetVisitTip(
                category: .ageRelated,
                title: Strings.VetVisit.Tips.pupDevelopmentTitle,
                description: Strings.VetVisit.Tips.pupDevelopmentDescription,
                source: .age(months: ageMonths),
                priority: .medium
            ))
        }

        // Young adult (1-2 years)
        if ageMonths >= 12 && ageMonths < 24 {
            tips.append(VetVisitTip(
                category: .ageRelated,
                title: Strings.VetVisit.Tips.youngAdultDentalTitle,
                description: Strings.VetVisit.Tips.youngAdultDentalDescription,
                source: .age(months: ageMonths),
                priority: .medium
            ))
        }

        // Approaching senior (within 12 months of senior threshold)
        let seniorThreshold = profile.seniorAgeMonths
        if ageMonths >= (seniorThreshold - 12) && ageMonths < seniorThreshold {
            tips.append(VetVisitTip(
                category: .ageRelated,
                title: Strings.VetVisit.Tips.approachingSeniorTitle,
                description: Strings.VetVisit.Tips.approachingSeniorDescription(
                    size: profile.sizeCategory.label
                ),
                source: .age(months: ageMonths),
                priority: .medium
            ))
        }

        // Senior phase
        if ageMonths >= seniorThreshold {
            tips.append(VetVisitTip(
                category: .ageRelated,
                title: Strings.VetVisit.Tips.seniorBloodworkTitle,
                description: Strings.VetVisit.Tips.seniorBloodworkDescription,
                source: .age(months: ageMonths),
                priority: .high
            ))

            tips.append(VetVisitTip(
                category: .ageRelated,
                title: Strings.VetVisit.Tips.seniorMobilityTitle,
                description: Strings.VetVisit.Tips.seniorMobilityDescription,
                source: .age(months: ageMonths),
                priority: .medium
            ))

            // Cognitive health for older seniors
            if ageMonths >= seniorThreshold + 24 {
                tips.append(VetVisitTip(
                    category: .ageRelated,
                    title: Strings.VetVisit.Tips.cognitiveHealthTitle,
                    description: Strings.VetVisit.Tips.cognitiveHealthDescription,
                    source: .age(months: ageMonths),
                    priority: .medium
                ))
            }
        }

        return tips
    }

    // MARK: - Breed-Based Tips

    private func breedTips(for profile: PuppyProfile) -> [VetVisitTip] {
        var tips: [VetVisitTip] = []

        guard let breed = profile.breed, !breed.isEmpty else { return tips }

        // Get breed-specific risks
        if let breedRisks = BreedHealthRisk.risks(for: breed) {
            for risk in breedRisks.risks.prefix(3) {  // Top 3 risks
                // Skip if already diagnosed
                if profile.healthConditions.contains(where: { $0.type == risk.conditionType }) {
                    continue
                }

                let priority: VetVisitTip.TipPriority = risk.riskLevel == .high || risk.riskLevel == .veryHigh ? .high : .medium

                // Check if screening is due
                if let screeningAge = risk.screeningRecommendedAgeMonths,
                   profile.ageInMonths >= screeningAge - 3 && profile.ageInMonths <= screeningAge + 3 {
                    tips.append(VetVisitTip(
                        category: .breedRisk,
                        title: Strings.VetVisit.Tips.screeningDueTitle(condition: risk.conditionType.label),
                        description: Strings.VetVisit.Tips.screeningDueDescription(
                            breed: breed,
                            condition: risk.conditionType.label
                        ),
                        source: .breed(breed),
                        priority: .high
                    ))
                } else if risk.riskLevel == .high || risk.riskLevel == .veryHigh {
                    tips.append(VetVisitTip(
                        category: .breedRisk,
                        title: Strings.VetVisit.Tips.breedRiskTitle(condition: risk.conditionType.label),
                        description: Strings.VetVisit.Tips.breedRiskDescription(
                            breed: breed,
                            warnings: risk.warningsToWatch.joined(separator: ", ")
                        ),
                        source: .breed(breed),
                        priority: priority
                    ))
                }
            }
        }

        // Add size-based risks
        let sizeRisks = BreedHealthRisk.sizeBasedRisks(for: profile.sizeCategory)
        for risk in sizeRisks.prefix(2) {
            if profile.healthConditions.contains(where: { $0.type == risk.conditionType }) {
                continue
            }

            tips.append(VetVisitTip(
                category: .breedRisk,
                title: Strings.VetVisit.Tips.sizeRiskTitle(
                    size: profile.sizeCategory.label,
                    condition: risk.conditionType.label
                ),
                description: risk.preventionTips.first ?? Strings.VetVisit.Tips.discussWithVet,
                source: .breed("\(profile.sizeCategory.label) breed"),
                priority: .low
            ))
        }

        return tips
    }

    // MARK: - Condition-Based Tips

    private func conditionTips(for conditions: [HealthCondition]) -> [VetVisitTip] {
        var tips: [VetVisitTip] = []

        let activeConditions = conditions.filter { $0.status == .active || $0.status == .monitoring }

        for condition in activeConditions {
            // Check for follow-ups due
            let followUps = ConditionFollowUp.followUps(for: condition)
            for followUp in followUps {
                let status = FollowUpStatus(followUp: followUp, lastCompleted: condition.lastReviewDate)

                if status.isOverdue {
                    tips.append(VetVisitTip(
                        category: .conditionRelated,
                        title: Strings.VetVisit.Tips.overdueFollowUpTitle(
                            type: followUp.followUpType.rawValue.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).lowercased()
                        ),
                        description: Strings.VetVisit.Tips.overdueFollowUpDescription(
                            condition: condition.displayName,
                            days: abs(status.daysUntilDue)
                        ),
                        source: .condition(condition.type),
                        priority: .high
                    ))
                } else if status.daysUntilDue <= 30 {
                    tips.append(VetVisitTip(
                        category: .conditionRelated,
                        title: Strings.VetVisit.Tips.upcomingFollowUpTitle(
                            type: followUp.followUpType.rawValue.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).lowercased()
                        ),
                        description: followUp.description,
                        source: .condition(condition.type),
                        priority: .medium
                    ))
                }
            }

            // Condition needs review
            if condition.needsReview {
                tips.append(VetVisitTip(
                    category: .conditionRelated,
                    title: Strings.VetVisit.Tips.conditionReviewTitle(condition: condition.displayName),
                    description: Strings.VetVisit.Tips.conditionReviewDescription(
                        frequency: condition.monitoringFrequency.label
                    ),
                    source: .condition(condition.type),
                    priority: .medium
                ))
            }

            // Medication review for conditions with medications
            if !condition.associatedMedicationIds.isEmpty {
                tips.append(VetVisitTip(
                    category: .conditionRelated,
                    title: Strings.VetVisit.Tips.medicationReviewTitle,
                    description: Strings.VetVisit.Tips.medicationReviewDescription(
                        condition: condition.displayName
                    ),
                    source: .condition(condition.type),
                    priority: .medium
                ))
            }
        }

        return tips
    }

    // MARK: - Symptom-Based Tips

    private func symptomTips(from symptoms: [HealthSymptomLog]) -> [VetVisitTip] {
        var tips: [VetVisitTip] = []

        // Only consider symptoms from last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentSymptoms = symptoms.filter { $0.createdAt >= thirtyDaysAgo }

        // Group by symptom type
        let grouped = Dictionary(grouping: recentSymptoms) { $0.symptomType }

        for (symptomType, occurrences) in grouped {
            let count = occurrences.count

            // Multiple occurrences deserve attention
            if count >= 2 {
                let priority: VetVisitTip.TipPriority = count >= 5 ? .high : .medium

                tips.append(VetVisitTip(
                    category: .recentSymptom,
                    title: Strings.VetVisit.Tips.recurringSymptomTitle(symptom: symptomType.label),
                    description: Strings.VetVisit.Tips.recurringSymptomDescription(
                        count: count,
                        days: 30
                    ),
                    source: .symptom(symptomType, count: count),
                    priority: priority
                ))
            }

            // High severity symptoms (4 or 5)
            let severe = occurrences.filter { $0.severity >= 4 }
            if !severe.isEmpty {
                tips.append(VetVisitTip(
                    category: .recentSymptom,
                    title: Strings.VetVisit.Tips.worseningSymptomTitle(symptom: symptomType.label),
                    description: Strings.VetVisit.Tips.worseningSymptomDescription,
                    source: .symptom(symptomType, count: severe.count),
                    priority: .high
                ))
            }
        }

        return tips
    }

    // MARK: - Preventive Tips

    private func preventiveTips(for profile: PuppyProfile) -> [VetVisitTip] {
        var tips: [VetVisitTip] = []

        // Dental health
        if profile.ageInMonths >= 24 {
            tips.append(VetVisitTip(
                category: .preventive,
                title: Strings.VetVisit.Tips.dentalCheckTitle,
                description: Strings.VetVisit.Tips.dentalCheckDescription,
                source: .preventive(Strings.VetVisit.Tips.annualCare),
                priority: .low
            ))
        }

        // Weight check
        tips.append(VetVisitTip(
            category: .preventive,
            title: Strings.VetVisit.Tips.weightCheckTitle,
            description: Strings.VetVisit.Tips.weightCheckDescription,
            source: .preventive(Strings.VetVisit.Tips.routineCare),
            priority: .low
        ))

        // Parasite prevention
        tips.append(VetVisitTip(
            category: .preventive,
            title: Strings.VetVisit.Tips.parasitePreventionTitle,
            description: Strings.VetVisit.Tips.parasitePreventionDescription,
            source: .preventive(Strings.VetVisit.Tips.preventiveCare),
            priority: .low
        ))

        return tips
    }
}
