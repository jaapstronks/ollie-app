//
//  Strings+Tips.swift
//  Otis-app
//
//  Localized strings for feature discovery tips and contextual guidance
//

import Foundation

private let table = "Training"

extension Strings {

    // MARK: - Feature Discovery Tips

    /// Strings for contextual feature discovery tips
    /// These are shown when users first visit a view to help them understand its purpose
    enum FeatureTips {
        // MARK: - Today View

        /// Title for the Today view introduction tip
        static var todayTitle: String {
            String(localized: "Your daily command center", table: table)
        }

        /// Message for the Today view introduction tip
        static var todayMessage: String {
            String(localized: "See everything at a glance: sleep status, potty progress, and upcoming events. Use the + button to quickly log activities.", table: table)
        }

        // MARK: - Schedule Tab: Development

        /// Title for the Development view tip
        static var developmentTitle: String {
            String(localized: "Track development stages", table: table)
        }

        /// Message for the Development view tip
        static var developmentMessage: String {
            String(localized: "See what developmental stage your puppy is in, upcoming milestones, and the critical socialization window timeline.", table: table)
        }

        // MARK: - Schedule Tab: Calendar

        /// Title for the Calendar view tip
        static var calendarTitle: String {
            String(localized: "Plan ahead", table: table)
        }

        /// Message for the Calendar view tip
        static var calendarMessage: String {
            String(localized: "Schedule vet appointments, training classes, and grooming sessions. Never miss an important date.", table: table)
        }

        /// Action button for the Calendar view tip
        static var calendarAction: String {
            String(localized: "Add Appointment", table: table)
        }

        // MARK: - Schedule Tab: Contacts

        /// Title for the Contacts view tip
        static var contactsTitle: String {
            String(localized: "Keep contacts handy", table: table)
        }

        /// Message for the Contacts view tip
        static var contactsMessage: String {
            String(localized: "Save your vet, trainer, groomer, and dog walker info all in one place. Quickly call or message when you need them.", table: table)
        }

        /// Action button for the Contacts view tip
        static var contactsAction: String {
            String(localized: "Add Your Vet", table: table)
        }

        // MARK: - Train Tab

        /// Title for the Train tab introduction tip
        static var trainTitle: String {
            String(localized: "Your training hub", table: table)
        }

        /// Message for the Train tab introduction tip
        static var trainMessage: String {
            String(localized: "Master potty training, build essential skills, and track socialization progress. Everything you need to raise a well-behaved pup.", table: table)
        }

        // MARK: - Train Tab: Skills

        /// Title for the Skills section tip
        static var skillsTitle: String {
            String(localized: "Build good habits", table: table)
        }

        /// Message for the Skills section tip
        static var skillsMessage: String {
            String(localized: "Track training progress on essential commands and behaviors. Celebrate small wins as your puppy learns.", table: table)
        }

        // MARK: - Train Tab: Socialization

        /// Title for the Socialization section tip
        static var socializationTitle: String {
            String(localized: "Socialize with confidence", table: table)
        }

        /// Message for the Socialization section tip
        static var socializationMessage: String {
            String(localized: "The first 16 weeks are critical. Track exposures to people, animals, sounds, and environments to raise a confident dog.", table: table)
        }

        // MARK: - Places Tab

        /// Title for the Places/Explore view tip
        static var placesTitle: String {
            String(localized: "Discover favorite spots", table: table)
        }

        /// Message for the Places/Explore view tip
        static var placesMessage: String {
            String(localized: "Save dog-friendly parks, trails, and hangouts. See where you've captured photo moments on the map.", table: table)
        }

        // MARK: - Health Tab

        /// Title for the Health view tip
        static var healthTitle: String {
            String(localized: "Monitor health & growth", table: table)
        }

        /// Message for the Health view tip
        static var healthMessage: String {
            String(localized: "Track weight, vaccinations, and potty training progress. Spot patterns and celebrate milestones.", table: table)
        }

        // MARK: - Appointments

        /// Title for the Appointments view tip
        static var appointmentsTitle: String {
            String(localized: "Never miss an appointment", table: table)
        }

        /// Message for the Appointments view tip
        static var appointmentsMessage: String {
            String(localized: "Schedule vet visits, vaccinations, grooming, and training classes. Get reminders so you're always prepared.", table: table)
        }

        /// Action button for the Appointments view tip
        static var appointmentsAction: String {
            String(localized: "Schedule First Visit", table: table)
        }

        // MARK: - Documents

        /// Title for the Documents view tip
        static var documentsTitle: String {
            String(localized: "Keep documents organized", table: table)
        }

        /// Message for the Documents view tip
        static var documentsMessage: String {
            String(localized: "Store vaccination records, microchip info, insurance papers, and pedigree documents all in one place.", table: table)
        }

        /// Action button for the Documents view tip
        static var documentsAction: String {
            String(localized: "Add Document", table: table)
        }

        // MARK: - Spot Detail

        /// Title for the spot detail view tip
        static var spotDetailTitle: String {
            String(localized: "Your spot stats", table: table)
        }

        /// Message for the spot detail view tip
        static var spotDetailMessage: String {
            String(localized: "See when you first visited, how many dogs you've met here, and potty success stats. Add notes and photos to remember special moments.", table: table)
        }

        // MARK: - Training Skills

        /// Title for the training skills view tip
        static var trainingSkillsTitle: String {
            String(localized: "Master skills step by step", table: table)
        }

        /// Message for the training skills view tip
        static var trainingSkillsMessage: String {
            String(localized: "Skills unlock in order as your puppy progresses. Complete the preparation checklist first, then work through each skill at your own pace.", table: table)
        }

        // MARK: - Moments Gallery

        /// Title for the moments gallery tip
        static var momentsGalleryTitle: String {
            String(localized: "Your puppy's photo album", table: table)
        }

        /// Message for the moments gallery tip
        static var momentsGalleryMessage: String {
            String(localized: "Switch between gallery and diary view. Photos are tagged with location and appear on the map where they were taken.", table: table)
        }

        // MARK: - Weight Tracking

        /// Title for the weight tracking tip
        static var weightTrackingTitle: String {
            String(localized: "Track growth over time", table: table)
        }

        /// Message for the weight tracking tip
        static var weightTrackingMessage: String {
            String(localized: "The shaded area shows healthy weight range for your puppy's breed size. Regular weigh-ins help spot growth issues early.", table: table)
        }
    }
}
