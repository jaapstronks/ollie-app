//
//  DefaultMilestones.swift
//  OtisShared
//
//  Factory for creating default milestones based on puppy's birth date
//

import Foundation

/// Factory for creating default milestones based on puppy's birth date
public enum DefaultMilestones {

    /// Create default milestones for a new puppy
    public static func create() -> [Milestone] {
        var milestones: [Milestone] = []
        var sortOrder = 0

        // Health milestones - Dutch vaccination schedule
        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.firstDewormingBreeder",
            targetAgeWeeks: 6,
            isCompleted: true,  // Usually done by breeder
            icon: "pills.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.firstVaccination",
            detailKey: "milestone.firstVaccination.detail",
            targetAgeWeeks: 8,
            icon: "syringe.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.firstVetVisit",
            targetAgeWeeks: 9,
            icon: "cross.case.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.firstDewormingHome",
            targetAgeWeeks: 9,
            icon: "pills.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.secondVaccination",
            detailKey: "milestone.secondVaccination.detail",
            targetAgeWeeks: 12,
            icon: "syringe.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.thirdVaccination",
            detailKey: "milestone.thirdVaccination.detail",
            targetAgeWeeks: 16,
            icon: "syringe.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.neuteredDiscussion",
            targetAgeMonths: 6,
            icon: "stethoscope",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.yearlyVaccination",
            targetAgeMonths: 12,
            isRecurring: true,
            recurrenceMonths: 12,
            icon: "syringe.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        // Developmental milestones
        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.socializationStart",
            detailKey: "milestone.socializationStart.detail",
            targetAgeWeeks: 8,
            icon: "person.3.fill",
            isActionable: false,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.socializationPeak",
            detailKey: "milestone.socializationPeak.detail",
            targetAgeWeeks: 12,
            icon: "sparkles",
            isActionable: false,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.socializationEnd",
            detailKey: "milestone.socializationEnd.detail",
            targetAgeWeeks: 16,
            icon: "clock.badge.checkmark.fill",
            isActionable: false,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.fearPeriod1",
            detailKey: "milestone.fearPeriod1.detail",
            targetAgeWeeks: 8,
            icon: "exclamationmark.triangle.fill",
            isActionable: false,
            isUserDismissable: true,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.fearPeriod2",
            detailKey: "milestone.fearPeriod2.detail",
            targetAgeMonths: 6,
            icon: "exclamationmark.triangle.fill",
            isActionable: false,
            isUserDismissable: true,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        // Administrative milestones
        milestones.append(Milestone(
            category: .administrative,
            labelKey: "milestone.microchipRegistration",
            targetAgeWeeks: 8,
            icon: "wave.3.right.circle.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .administrative,
            labelKey: "milestone.insuranceSetup",
            detailKey: "milestone.insuranceSetup.detail",
            targetAgeWeeks: 8,
            icon: "shield.checkered",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .administrative,
            labelKey: "milestone.dogLicense",
            detailKey: "milestone.dogLicense.detail",
            targetAgeWeeks: 12,
            icon: "doc.badge.plus",
            isUserDismissable: true,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        return milestones
    }
}
