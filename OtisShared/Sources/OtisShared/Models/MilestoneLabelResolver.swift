//
//  MilestoneLabelResolver.swift
//  OtisShared
//
//  Resolves milestone label keys to localized strings
//

import Foundation

/// Resolves milestone label keys to localized strings
public enum MilestoneLabelResolver {

    private static let table = "Milestones"

    /// Resolve a label key to its localized string
    public static func resolve(_ key: String) -> String {
        switch key {
        // Health milestones
        case "milestone.firstDewormingBreeder":
            return String(localized: "First deworming (breeder)", table: table, bundle: Strings.bundle)
        case "milestone.firstVaccination":
            return String(localized: "First vaccination (DHP + Lepto)", table: table, bundle: Strings.bundle)
        case "milestone.firstVaccination.detail":
            return String(localized: "Core vaccination at 8 weeks", table: table, bundle: Strings.bundle)
        case "milestone.firstVetVisit":
            return String(localized: "First vet visit", table: table, bundle: Strings.bundle)
        case "milestone.firstDewormingHome":
            return String(localized: "First deworming (home)", table: table, bundle: Strings.bundle)
        case "milestone.secondVaccination":
            return String(localized: "Second vaccination (DHP + Lepto + Rabies)", table: table, bundle: Strings.bundle)
        case "milestone.secondVaccination.detail":
            return String(localized: "Booster vaccination at 12 weeks", table: table, bundle: Strings.bundle)
        case "milestone.thirdVaccination":
            return String(localized: "Third vaccination (cocktail)", table: table, bundle: Strings.bundle)
        case "milestone.thirdVaccination.detail":
            return String(localized: "Final puppy vaccination at 16 weeks", table: table, bundle: Strings.bundle)
        case "milestone.neuteredDiscussion":
            return String(localized: "Spay/neuter discussion with vet", table: table, bundle: Strings.bundle)
        case "milestone.yearlyVaccination":
            return String(localized: "Yearly vaccination", table: table, bundle: Strings.bundle)

        // Developmental milestones
        case "milestone.socializationStart":
            return String(localized: "Socialization window begins", table: table, bundle: Strings.bundle)
        case "milestone.socializationStart.detail":
            return String(localized: "Critical period for positive experiences starts now", table: table, bundle: Strings.bundle)
        case "milestone.socializationPeak":
            return String(localized: "Peak socialization period", table: table, bundle: Strings.bundle)
        case "milestone.socializationPeak.detail":
            return String(localized: "Most receptive time for new experiences", table: table, bundle: Strings.bundle)
        case "milestone.socializationEnd":
            return String(localized: "Socialization window closing", table: table, bundle: Strings.bundle)
        case "milestone.socializationEnd.detail":
            return String(localized: "Window is narrowing - focus on remaining exposures", table: table, bundle: Strings.bundle)
        case "milestone.fearPeriod1":
            return String(localized: "First fear period", table: table, bundle: Strings.bundle)
        case "milestone.fearPeriod1.detail":
            return String(localized: "Be extra gentle with new experiences", table: table, bundle: Strings.bundle)
        case "milestone.fearPeriod2":
            return String(localized: "Second fear period", table: table, bundle: Strings.bundle)
        case "milestone.fearPeriod2.detail":
            return String(localized: "Temporary increase in fearfulness - stay patient", table: table, bundle: Strings.bundle)

        // Administrative milestones
        case "milestone.microchipRegistration":
            return String(localized: "Microchip registration", table: table, bundle: Strings.bundle)
        case "milestone.insuranceSetup":
            return String(localized: "Pet insurance setup", table: table, bundle: Strings.bundle)
        case "milestone.insuranceSetup.detail":
            return String(localized: "Consider health insurance coverage", table: table, bundle: Strings.bundle)
        case "milestone.dogLicense":
            return String(localized: "Dog license", table: table, bundle: Strings.bundle)
        case "milestone.dogLicense.detail":
            return String(localized: "Register with your municipality if required", table: table, bundle: Strings.bundle)

        // Age-based health milestones
        case "milestone.dentalBaseline":
            return String(localized: "Dental baseline check", table: table, bundle: Strings.bundle)
        case "milestone.dentalBaseline.detail":
            return String(localized: "Establish dental health baseline at 2 years", table: table, bundle: Strings.bundle)
        case "milestone.annualWellness":
            return String(localized: "Annual wellness exam", table: table, bundle: Strings.bundle)
        case "milestone.annualWellness.detail":
            return String(localized: "Yearly comprehensive health checkup", table: table, bundle: Strings.bundle)
        case "milestone.seniorScreening":
            return String(localized: "Senior wellness screening", table: table, bundle: Strings.bundle)
        case "milestone.seniorScreening.detail":
            return String(localized: "Comprehensive bloodwork and organ function tests", table: table, bundle: Strings.bundle)
        case "milestone.semiAnnualSenior":
            return String(localized: "Semi-annual senior checkup", table: table, bundle: Strings.bundle)
        case "milestone.semiAnnualSenior.detail":
            return String(localized: "More frequent monitoring for senior dogs", table: table, bundle: Strings.bundle)

        // Breed-specific screening milestones
        case "milestone.hipScreening":
            return String(localized: "Hip screening", table: table, bundle: Strings.bundle)
        case "milestone.hipScreening.detail":
            return String(localized: "X-ray evaluation for hip dysplasia", table: table, bundle: Strings.bundle)
        case "milestone.elbowScreening":
            return String(localized: "Elbow screening", table: table, bundle: Strings.bundle)
        case "milestone.elbowScreening.detail":
            return String(localized: "X-ray evaluation for elbow dysplasia", table: table, bundle: Strings.bundle)
        case "milestone.heartScreening":
            return String(localized: "Heart screening", table: table, bundle: Strings.bundle)
        case "milestone.heartScreening.detail":
            return String(localized: "Cardiac auscultation and evaluation", table: table, bundle: Strings.bundle)
        case "milestone.eyeScreening":
            return String(localized: "Eye screening", table: table, bundle: Strings.bundle)
        case "milestone.eyeScreening.detail":
            return String(localized: "CERF/OFA eye examination", table: table, bundle: Strings.bundle)

        default:
            // For custom milestones, the key is the user-entered title
            return key
        }
    }
}
