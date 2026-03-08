//
//  Strings+VetVisit.swift
//  Ollie-app
//
//  Localized strings for vet visit features.
//

import Foundation

extension Strings {

    // MARK: - Vet Visit

    enum VetVisit {
        private static let table = "VetVisit"

        // General
        static let title = String(localized: "Vet Visit", table: table)
        static let upcomingVisit = String(localized: "Upcoming Vet Visit", table: table)
        static let prepareVisit = String(localized: "Prepare for Visit", table: table)
        static let visitTips = String(localized: "Visit Tips", table: table)
        static let questionsToConsider = String(localized: "Questions to consider asking", table: table)
        static let noUpcomingVisits = String(localized: "No upcoming vet visits", table: table)

        // Visit status
        static func visitInDays(_ days: Int) -> String {
            String(localized: "Visit in \(days) day\(days == 1 ? "" : "s")", table: table)
        }
        static let visitToday = String(localized: "Visit Today", table: table)
        static let visitTomorrow = String(localized: "Visit Tomorrow", table: table)

        // Actions
        static let viewTips = String(localized: "View Tips", table: table)
        static let prepareSummary = String(localized: "Prepare Visit Summary", table: table)
        static let shareAsText = String(localized: "Share as Text", table: table)
        static let shareAsPDF = String(localized: "Share as PDF", table: table)
        static let copyToClipboard = String(localized: "Copy to Clipboard", table: table)
        static let copiedToClipboard = String(localized: "Copied to clipboard", table: table)
        static let scheduleAppointment = String(localized: "Schedule Appointment", table: table)

        // MARK: - Tips

        enum Tips {
            private static let table = "VetVisit"

            // Age-related tips
            static let puppyVaccinationTitle = String(localized: "Complete puppy vaccinations", table: table)
            static let puppyVaccinationDescription = String(localized: "Ensure core vaccinations are on schedule for protection against distemper, parvo, and rabies.", table: table)

            static let pupDevelopmentTitle = String(localized: "Discuss developmental progress", table: table)
            static let pupDevelopmentDescription = String(localized: "Review growth milestones, socialization progress, and any behavioral concerns.", table: table)

            static let youngAdultDentalTitle = String(localized: "Establish dental baseline", table: table)
            static let youngAdultDentalDescription = String(localized: "Good time to establish dental health baseline and discuss home care routine.", table: table)

            static let approachingSeniorTitle = String(localized: "Prepare for senior years", table: table)
            static func approachingSeniorDescription(size: String) -> String {
                String(localized: "As a \(size) dog, consider discussing senior screening options and age-appropriate care adjustments.", table: table)
            }

            static let seniorBloodworkTitle = String(localized: "Senior bloodwork panel", table: table)
            static let seniorBloodworkDescription = String(localized: "Regular bloodwork helps catch age-related issues early. Discuss kidney, liver, and thyroid function.", table: table)

            static let seniorMobilityTitle = String(localized: "Mobility assessment", table: table)
            static let seniorMobilityDescription = String(localized: "Evaluate joint health and discuss pain management options if needed.", table: table)

            static let cognitiveHealthTitle = String(localized: "Cognitive health check", table: table)
            static let cognitiveHealthDescription = String(localized: "Discuss any changes in behavior, sleep patterns, or confusion that might indicate cognitive decline.", table: table)

            // Breed-related tips
            static func screeningDueTitle(condition: String) -> String {
                String(localized: "\(condition) screening due", table: table)
            }
            static func screeningDueDescription(breed: String, condition: String) -> String {
                String(localized: "\(breed)s are at higher risk for \(condition). This is a good time to discuss screening.", table: table)
            }

            static func breedRiskTitle(condition: String) -> String {
                String(localized: "Monitor for \(condition)", table: table)
            }
            static func breedRiskDescription(breed: String, warnings: String) -> String {
                String(localized: "\(breed)s are predisposed to this condition. Watch for: \(warnings)", table: table)
            }

            static func sizeRiskTitle(size: String, condition: String) -> String {
                String(localized: "\(size) breed \(condition) awareness", table: table)
            }
            static let discussWithVet = String(localized: "Discuss monitoring and prevention options with your vet.", table: table)

            // Condition-related tips
            static func overdueFollowUpTitle(type: String) -> String {
                String(localized: "Overdue \(type)", table: table)
            }
            static func overdueFollowUpDescription(condition: String, days: Int) -> String {
                String(localized: "Follow-up for \(condition) is \(days) days overdue. Priority discussion item.", table: table)
            }

            static func upcomingFollowUpTitle(type: String) -> String {
                String(localized: "\(type.capitalized) due soon", table: table)
            }

            static func conditionReviewTitle(condition: String) -> String {
                String(localized: "Review \(condition) status", table: table)
            }
            static func conditionReviewDescription(frequency: String) -> String {
                String(localized: "Regular \(frequency.lowercased()) check-ins help track condition progression.", table: table)
            }

            static let medicationReviewTitle = String(localized: "Medication review", table: table)
            static func medicationReviewDescription(condition: String) -> String {
                String(localized: "Review effectiveness and side effects of medications for \(condition).", table: table)
            }

            // Symptom-related tips
            static func recurringSymptomTitle(symptom: String) -> String {
                String(localized: "Recurring \(symptom.lowercased())", table: table)
            }
            static func recurringSymptomDescription(count: Int, days: Int) -> String {
                String(localized: "Logged \(count) times in the last \(days) days. Discuss potential causes and treatment.", table: table)
            }

            static func worseningSymptomTitle(symptom: String) -> String {
                String(localized: "Worsening \(symptom.lowercased())", table: table)
            }
            static let worseningSymptomDescription = String(localized: "This symptom has been trending worse. Priority discussion item.", table: table)

            static func severeSymptomTitle(symptom: String) -> String {
                String(localized: "Severe \(symptom.lowercased()) episodes", table: table)
            }
            static let severeSymptomDescription = String(localized: "High severity episodes have been logged. Important to discuss.", table: table)

            // Preventive tips
            static let dentalCheckTitle = String(localized: "Dental health check", table: table)
            static let dentalCheckDescription = String(localized: "Regular dental exams prevent periodontal disease and related health issues.", table: table)

            static let weightCheckTitle = String(localized: "Weight assessment", table: table)
            static let weightCheckDescription = String(localized: "Maintaining healthy weight reduces strain on joints and organs.", table: table)

            static let parasitePreventionTitle = String(localized: "Parasite prevention", table: table)
            static let parasitePreventionDescription = String(localized: "Review flea, tick, and heartworm prevention schedule.", table: table)

            // Source labels
            static let annualCare = String(localized: "Annual care", table: table)
            static let routineCare = String(localized: "Routine care", table: table)
            static let preventiveCare = String(localized: "Preventive care", table: table)
        }

        // MARK: - Summary

        enum Summary {
            private static let table = "VetVisit"

            static let title = String(localized: "Vet Visit Summary", table: table)

            // Sections
            static let profileSection = String(localized: "Profile Information", table: table)
            static let conditionsSection = String(localized: "Current Conditions", table: table)
            static let medicationsSection = String(localized: "Current Medications", table: table)
            static let allergiesSection = String(localized: "Allergies", table: table)
            static let recentSymptomsSection = String(localized: "Recent Symptoms (30 days)", table: table)
            static let assessmentsSection = String(localized: "Recent Health Assessments", table: table)
            static let weightTrendSection = String(localized: "Weight History", table: table)

            // Labels
            static let name = String(localized: "Name", table: table)
            static let breed = String(localized: "Breed", table: table)
            static let age = String(localized: "Age", table: table)
            static let size = String(localized: "Size", table: table)
            static let gender = String(localized: "Gender", table: table)
            static let weight = String(localized: "Weight", table: table)
            static let diagnosed = String(localized: "Diagnosed", table: table)
            static let vetNotes = String(localized: "Vet notes", table: table)
            static let purpose = String(localized: "Purpose", table: table)

            // Empty states
            static let noConditions = String(localized: "No current conditions", table: table)
            static let noMedications = String(localized: "No current medications", table: table)
            static let noRecentSymptoms = String(localized: "No symptoms logged in last 30 days", table: table)

            // Footer
            static let generatedBy = String(localized: "Generated by Ollie App", table: table)
        }

        // MARK: - Calendar

        enum Calendar {
            private static let table = "VetVisit"

            static let title = String(localized: "Health Calendar", table: table)
            static let upcoming = String(localized: "Upcoming", table: table)
            static let recurring = String(localized: "Recurring", table: table)
            static let medications = String(localized: "Medications", table: table)
            static let appointments = String(localized: "Appointments", table: table)
            static let milestones = String(localized: "Health Milestones", table: table)
            static let noEvents = String(localized: "No events scheduled", table: table)
        }

        // MARK: - Milestones

        enum Milestones {
            private static let table = "VetVisit"

            static let healthMilestones = String(localized: "Health Milestones", table: table)
            static let ageBasedScreenings = String(localized: "Age-Based Screenings", table: table)
            static let breedScreenings = String(localized: "Breed-Specific Screenings", table: table)
        }

        // MARK: - Follow-ups

        enum FollowUps {
            private static let table = "VetVisit"

            static let title = String(localized: "Follow-up Reminders", table: table)
            static let overdueTitle = String(localized: "Overdue Follow-ups", table: table)
            static let upcomingTitle = String(localized: "Upcoming Follow-ups", table: table)
            static let noFollowUps = String(localized: "No follow-ups scheduled", table: table)
            static let scheduleNow = String(localized: "Schedule Now", table: table)

            static func lastCompleted(date: String) -> String {
                String(localized: "Last completed: \(date)", table: table)
            }
            static let neverCompleted = String(localized: "Never completed", table: table)
        }

        // MARK: - Breed Risks

        enum BreedRisks {
            private static let table = "VetVisit"

            static let title = String(localized: "Breed Health Risks", table: table)
            static let awareness = String(localized: "Breed Risk Awareness", table: table)
            static let screeningStatus = String(localized: "Screening Status", table: table)
            static let scheduleScreening = String(localized: "Schedule Screening", table: table)
            static let noBreedRisks = String(localized: "No breed-specific risks identified", table: table)

            static func riskLevel(_ level: String) -> String {
                String(localized: "\(level) risk", table: table)
            }
            static func typicalOnset(months: Int) -> String {
                let years = months / 12
                if years > 0 {
                    return String(localized: "Typical onset: \(years)+ years", table: table)
                } else {
                    return String(localized: "Typical onset: \(months)+ months", table: table)
                }
            }
        }
    }
}
