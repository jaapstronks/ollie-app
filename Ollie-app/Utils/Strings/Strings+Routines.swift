//
//  Strings+Routines.swift
//  Otis-app
//
//  Localization strings for routines, weight goals, body condition, grooming, and enrichment

import Foundation

private let table = "Routines"

extension Strings {

    // MARK: - Routine View

    enum Routine {
        static let title = String(localized: "Daily Routine", table: table)
        static let editRoutine = String(localized: "Edit Routine", table: table)
        static let addItem = String(localized: "Add Item", table: table)
        static let noItems = String(localized: "No routine items yet", table: table)
        static let noItemsDescription = String(localized: "Add items to create your daily routine.", table: table)
        static let completed = String(localized: "Completed", table: table)
        static let upcoming = String(localized: "Upcoming", table: table)
        static let nextUp = String(localized: "Next up", table: table)
        static let allDone = String(localized: "All done for today!", table: table)

        // Categories
        static let morning = String(localized: "Morning", table: table)
        static let afternoon = String(localized: "Afternoon", table: table)
        static let evening = String(localized: "Evening", table: table)
        static let anytime = String(localized: "Anytime", table: table)

        // Edit sheet
        static let itemLabel = String(localized: "Label", table: table)
        static let itemTime = String(localized: "Time", table: table)
        static let itemCategory = String(localized: "Category", table: table)
        static let linkedEvent = String(localized: "Linked event type", table: table)
        static let linkedEventDescription = String(localized: "Auto-complete when this event is logged", table: table)
        static let enabled = String(localized: "Enabled", table: table)

        // Default item labels
        static let morningWalk = String(localized: "Morning walk", table: table)
        static let middayWalk = String(localized: "Midday walk", table: table)
        static let eveningWalk = String(localized: "Evening walk", table: table)
        static let breakfast = String(localized: "Breakfast", table: table)
        static let dinner = String(localized: "Dinner", table: table)
        static let playTime = String(localized: "Play time", table: table)
        static let finalPottyBreak = String(localized: "Final potty break", table: table)
    }

    // MARK: - Weight Goal

    enum WeightGoal {
        static let title = String(localized: "Weight Goal", table: table)
        static let setGoal = String(localized: "Set Weight Goal", table: table)
        static let editGoal = String(localized: "Edit Goal", table: table)
        static let currentWeight = String(localized: "Current weight", table: table)
        static let targetWeight = String(localized: "Target weight", table: table)
        static let startWeight = String(localized: "Start weight", table: table)
        static let targetDate = String(localized: "Target date", table: table)
        static let noTargetDate = String(localized: "No target date", table: table)
        static let progress = String(localized: "Progress", table: table)
        static let remaining = String(localized: "remaining", table: table)
        static let achieved = String(localized: "Goal achieved!", table: table)
        static let onTrack = String(localized: "On track", table: table)
        static let overdue = String(localized: "Overdue", table: table)

        // Directions
        static let lose = String(localized: "Lose weight", table: table)
        static let maintain = String(localized: "Maintain weight", table: table)
        static let gain = String(localized: "Gain weight", table: table)

        // Rate
        static func weeklyRate(_ rate: String) -> String {
            String(localized: "\(rate)/week recommended", table: table)
        }
        static func daysRemaining(_ days: Int) -> String {
            String(localized: "\(days) days remaining", table: table)
        }
    }

    // MARK: - Body Condition Score

    enum BodyCondition {
        static let title = String(localized: "Body Condition", table: table)
        static let score = String(localized: "Body Condition Score", table: table)
        static let logScore = String(localized: "Log BCS", table: table)
        static let latestScore = String(localized: "Latest score", table: table)
        static let history = String(localized: "History", table: table)
        static let noScores = String(localized: "No scores recorded yet", table: table)
        static let ninePointScale = String(localized: "9-point scale", table: table)

        // BCS categories (1-9)
        static let emaciated = String(localized: "Emaciated", table: table)
        static let veryThin = String(localized: "Very thin", table: table)
        static let thin = String(localized: "Thin", table: table)
        static let underweight = String(localized: "Underweight", table: table)
        static let ideal = String(localized: "Ideal", table: table)
        static let slightlyOverweight = String(localized: "Slightly overweight", table: table)
        static let overweight = String(localized: "Overweight", table: table)
        static let obese = String(localized: "Obese", table: table)
        static let severelyObese = String(localized: "Severely obese", table: table)

        // Descriptions
        static let emaciated_desc = String(localized: "Ribs, spine, and hip bones are highly visible. No body fat. Severe muscle wasting.", table: table)
        static let veryThin_desc = String(localized: "Ribs easily visible with no fat covering. Tops of spine visible. Pronounced waist.", table: table)
        static let thin_desc = String(localized: "Ribs easily felt with minimal fat covering. Waist easily visible from above.", table: table)
        static let underweight_desc = String(localized: "Ribs easily felt with slight fat covering. Waist visible from above. Slight abdominal tuck.", table: table)
        static let ideal_desc = String(localized: "Ribs felt without excess fat covering. Waist visible from above. Abdominal tuck present.", table: table)
        static let slightlyOverweight_desc = String(localized: "Ribs felt with slight excess fat covering. Waist visible from above but less defined.", table: table)
        static let overweight_desc = String(localized: "Ribs difficult to feel with moderate fat covering. Waist barely visible. No abdominal tuck.", table: table)
        static let obese_desc = String(localized: "Ribs very difficult to feel under heavy fat covering. No waist visible. Fat deposits present.", table: table)
        static let severelyObese_desc = String(localized: "Ribs not palpable. Obvious fat deposits over spine and tail base. No waist or tuck.", table: table)

        // Recommendations
        static let urgentVet = String(localized: "Urgent: Consult your veterinarian immediately for a nutritional assessment.", table: table)
        static let increaseFood = String(localized: "Increase food intake and consult your vet to rule out underlying conditions.", table: table)
        static let slightlyIncreaseFood = String(localized: "Consider gradually increasing daily food portions.", table: table)
        static let addTreats = String(localized: "Slightly increase food or add healthy treats.", table: table)
        static let maintain = String(localized: "Maintain current diet and exercise routine.", table: table)
        static let reduceTreats = String(localized: "Slightly reduce treats or increase activity.", table: table)
        static let reduceFood = String(localized: "Reduce daily food intake and increase exercise duration.", table: table)
        static let consultVet = String(localized: "Consult your vet for a weight management plan.", table: table)
        static let urgentWeightLoss = String(localized: "Urgent: Work with your veterinarian on a structured weight loss program.", table: table)
    }

    // MARK: - Grooming

    enum Grooming {
        static let title = String(localized: "Grooming", table: table)
        static let schedule = String(localized: "Grooming Schedule", table: table)
        static let markComplete = String(localized: "Mark complete", table: table)
        static let due = String(localized: "Due", table: table)
        static let overdue = String(localized: "Overdue", table: table)
        static let upcoming = String(localized: "Upcoming", table: table)
        static let allCaughtUp = String(localized: "All caught up!", table: table)
        static let noDueActivities = String(localized: "No grooming due right now", table: table)
        static let interval = String(localized: "Interval", table: table)
        static let lastCompleted = String(localized: "Last completed", table: table)
        static let notYetDone = String(localized: "Not yet done", table: table)

        static func daysUntil(_ days: Int) -> String {
            String(localized: "Due in \(days) days", table: table)
        }
        static func daysOverdue(_ days: Int) -> String {
            String(localized: "\(days) day\(days == 1 ? "" : "s") overdue", table: table)
        }
        static let dueToday = String(localized: "Due today", table: table)
        static let dueTomorrow = String(localized: "Due tomorrow", table: table)
        static func dueInWeeks(_ weeks: Int) -> String {
            String(localized: "Due in \(weeks) week\(weeks == 1 ? "" : "s")", table: table)
        }
        static func everyDays(_ days: Int) -> String {
            String(localized: "Every \(days) days", table: table)
        }

        // Types
        static let brushing = String(localized: "Brushing", table: table)
        static let bathing = String(localized: "Bath", table: table)
        static let nailTrim = String(localized: "Nail trim", table: table)
        static let earCleaning = String(localized: "Ear cleaning", table: table)
        static let teethBrushing = String(localized: "Teeth brushing", table: table)
        static let haircut = String(localized: "Haircut", table: table)
        static let deShedding = String(localized: "De-shedding", table: table)
        static let pawCare = String(localized: "Paw care", table: table)
        static let eyeCleaning = String(localized: "Eye cleaning", table: table)
        static let analGlands = String(localized: "Anal glands", table: table)

        // Descriptions
        static let brushing_desc = String(localized: "Remove loose fur and prevent matting", table: table)
        static let bathing_desc = String(localized: "Full bath with dog shampoo", table: table)
        static let nailTrim_desc = String(localized: "Trim nails to prevent overgrowth", table: table)
        static let earCleaning_desc = String(localized: "Clean ears to prevent infections", table: table)
        static let teethBrushing_desc = String(localized: "Brush teeth for dental health", table: table)
        static let haircut_desc = String(localized: "Professional coat trimming", table: table)
        static let deShedding_desc = String(localized: "Remove undercoat and reduce shedding", table: table)
        static let pawCare_desc = String(localized: "Check pads and trim fur between toes", table: table)
        static let eyeCleaning_desc = String(localized: "Clean eye area and remove tear stains", table: table)
        static let analGlands_desc = String(localized: "Express anal glands if needed", table: table)

        // Coat type settings (from GroomingSettingsView)
        static let coatType = String(localized: "Coat Type", table: table)
        static let selectCoatType = String(localized: "Select Coat Type", table: table)
        static let notSet = String(localized: "Not set", table: table)
        static let suggested = String(localized: "Suggested", table: table)
        static let careTips = String(localized: "Care Tips", table: table)
        static let noActivities = String(localized: "No grooming activities", table: table)
        static let setupDefaults = String(localized: "Set Up Defaults", table: table)
        static let setCoatTypeFirst = String(localized: "Set a coat type to see recommended schedule", table: table)
        static let resetToDefaults = String(localized: "Reset to Defaults", table: table)
        static let resetToDefaultsTitle = String(localized: "Reset Grooming Schedule?", table: table)
        static let resetToDefaultsMessage = String(localized: "This will replace your current grooming schedule with the defaults for your dog's coat type.", table: table)

        static func coatTypeSuggestion(_ coatType: String) -> String {
            String(localized: "Based on your dog's breed, we suggest \"\(coatType)\" as the coat type.", table: table)
        }

        // Quick log sheet
        static let logActivity = String(localized: "Log Grooming", table: table)
        static let log = String(localized: "Log", table: table)
        static let whatDidYouDo = String(localized: "What did you do?", table: table)
        static let when = String(localized: "When", table: table)
        static let notesOptional = String(localized: "Notes (optional)", table: table)
        static let notePlaceholder = String(localized: "Add any notes about this grooming session...", table: table)
    }

    // MARK: - Grooming Nudge (Today Tab)

    enum GroomingNudge {
        static func overdueTitle(activity: String) -> String {
            String(localized: "\(activity) is overdue", table: table)
        }

        static func multipleOverdueTitle(count: Int) -> String {
            String(localized: "\(count) grooming tasks overdue", table: table)
        }

        static func dueTitle(activity: String) -> String {
            String(localized: "Time for \(activity)?", table: table)
        }

        static func overdueSubtitle(days: Int, name: String) -> String {
            String(localized: "\(days) days past due for \(name)", table: table)
        }

        static let lastDoneSubtitle = String(localized: "Last done", table: table)
        static func lastDoneSubtitle(date: String) -> String {
            String(localized: "Last done \(date)", table: table)
        }
        static let neverDoneSubtitle = String(localized: "Never logged", table: table)
    }

    // MARK: - Enrichment

    enum Enrichment {
        static let title = String(localized: "Enrichment", table: table)
        static let activities = String(localized: "Enrichment Activities", table: table)
        static let logActivity = String(localized: "Log Activity", table: table)
        static let todaySuggestion = String(localized: "Today's suggestion", table: table)
        static let tryToday = String(localized: "Try today", table: table)
        static let weeklyProgress = String(localized: "Weekly Progress", table: table)
        static let noActivities = String(localized: "No activities this week", table: table)
        static let duration = String(localized: "Duration", table: table)
        static let category = String(localized: "Category", table: table)
        static let recentActivities = String(localized: "Recent activities", table: table)
        static func activitiesThisWeek(_ count: Int) -> String {
            String(localized: "\(count) activities this week", table: table)
        }
        static func minutesThisWeek(_ minutes: Int) -> String {
            String(localized: "\(minutes) min this week", table: table)
        }

        // Categories
        static let mental = String(localized: "Mental", table: table)
        static let physical = String(localized: "Physical", table: table)
        static let social = String(localized: "Social", table: table)
        static let training = String(localized: "Training", table: table)
        static let calming = String(localized: "Calming", table: table)

        // Types
        static let puzzleToy = String(localized: "Puzzle toy", table: table)
        static let snuffleMat = String(localized: "Snuffle mat", table: table)
        static let hideAndSeek = String(localized: "Hide and seek", table: table)
        static let nosework = String(localized: "Nose work", table: table)
        static let trickTraining = String(localized: "Trick training", table: table)
        static let foodDispenser = String(localized: "Food dispenser", table: table)
        static let tugPlay = String(localized: "Tug play", table: table)
        static let fetchPlay = String(localized: "Fetch", table: table)
        static let socialPlay = String(localized: "Social play", table: table)
        static let newEnvironment = String(localized: "New environment", table: table)
        static let agility = String(localized: "Agility", table: table)
        static let swimming = String(localized: "Swimming", table: table)
        static let chewSession = String(localized: "Chew session", table: table)
        static let calmingActivity = String(localized: "Calming activity", table: table)

        // Descriptions
        static let puzzleToy_desc = String(localized: "Interactive toys that challenge problem-solving", table: table)
        static let snuffleMat_desc = String(localized: "Hide treats in fabric for foraging", table: table)
        static let hideAndSeek_desc = String(localized: "Hide treats or toys around the house", table: table)
        static let nosework_desc = String(localized: "Scent tracking and detection games", table: table)
        static let trickTraining_desc = String(localized: "Learning new tricks or behaviors", table: table)
        static let foodDispenser_desc = String(localized: "Kong, lick mat, or slow feeder", table: table)
        static let tugPlay_desc = String(localized: "Interactive tug games with rules", table: table)
        static let fetchPlay_desc = String(localized: "Retrieving games with balls or toys", table: table)
        static let socialPlay_desc = String(localized: "Play with other dogs or people", table: table)
        static let newEnvironment_desc = String(localized: "Exploring new places or routes", table: table)
        static let agility_desc = String(localized: "Obstacle courses and jumps", table: table)
        static let swimming_desc = String(localized: "Water play and swimming", table: table)
        static let chewSession_desc = String(localized: "Safe chewing with appropriate items", table: table)
        static let calmingActivity_desc = String(localized: "Relaxation training or massage", table: table)
    }

    // MARK: - Adult Wellness

    enum AdultWellness {
        static let title = String(localized: "Adult Wellness", table: table)
        static let subtitle = String(localized: "Routine and wellness tracking for adult dogs", table: table)
        static let routineCard = String(localized: "Daily Routine", table: table)
        static let groomingCard = String(localized: "Grooming", table: table)
        static let enrichmentCard = String(localized: "Enrichment", table: table)
        static let weightCard = String(localized: "Weight Management", table: table)
    }
}
