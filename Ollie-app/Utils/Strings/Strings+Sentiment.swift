//
//  Strings+Sentiment.swift
//  Ollie-app
//
//  Strings for sentiment check-in system
//

import Foundation

private let table = "Sentiment"

extension Strings {

    enum Sentiment {
        // MARK: - Category Names
        static let categoryPotty = String(localized: "Potty training", table: table)
        static let categoryBench = String(localized: "Crate training", table: table)
        static let categorySleeping = String(localized: "Sleeping", table: table)
        static let categoryWalks = String(localized: "Walks", table: table)
        static let categorySkills = String(localized: "Skills training", table: table)
        static let categoryNipping = String(localized: "Nipping & biting", table: table)
        static let categoryLeash = String(localized: "Leash behavior", table: table)
        static let categoryJumping = String(localized: "Jumping up", table: table)
        static let categoryResourceGuarding = String(localized: "Resource guarding", table: table)
        static let categoryChewing = String(localized: "Chewing", table: table)
        static let categoryBarking = String(localized: "Barking", table: table)
        static let categorySeparation = String(localized: "Being alone", table: table)
        static let categoryCar = String(localized: "Car travel", table: table)
        static let categoryHandling = String(localized: "Handling & grooming", table: table)

        // MARK: - Questions
        static let questionPotty = String(localized: "How is potty training going?", table: table)
        static let questionBench = String(localized: "How is crate training going?", table: table)
        static let questionSleeping = String(localized: "How is sleeping going?", table: table)
        static let questionWalks = String(localized: "How are walks going?", table: table)
        static let questionSkills = String(localized: "How is skills training going?", table: table)
        static let questionNipping = String(localized: "How is nipping & biting?", table: table)
        static let questionLeash = String(localized: "How is leash behavior?", table: table)
        static let questionJumping = String(localized: "How is jumping up?", table: table)
        static let questionResourceGuarding = String(localized: "How is resource guarding?", table: table)
        static let questionChewing = String(localized: "How is chewing behavior?", table: table)
        static let questionBarking = String(localized: "How is barking?", table: table)
        static let questionSeparation = String(localized: "How is being alone going?", table: table)
        static let questionCar = String(localized: "How is car travel going?", table: table)
        static let questionHandling = String(localized: "How is handling & grooming going?", table: table)

        // MARK: - Rating Labels
        static let ratingStruggling = String(localized: "Struggling", table: table)
        static let ratingDifficult = String(localized: "Difficult", table: table)
        static let ratingOkay = String(localized: "Okay", table: table)
        static let ratingGood = String(localized: "Good", table: table)
        static let ratingGreat = String(localized: "Great!", table: table)

        // MARK: - Check-in UI
        static let checkInTitle = String(localized: "Quick check-in", table: table)
        static let checkInSubtitle = String(localized: "Help us give better advice", table: table)
        static let skipForNow = String(localized: "Skip for now", table: table)
        static let submit = String(localized: "Submit", table: table)

        // MARK: - Context Summaries (shown before question)
        static let noDataYet = String(localized: "We don't have data on this yet.", table: table)

        static func pottyContext(outdoorPercent: Int, accidentsToday: Int) -> String {
            if accidentsToday > 0 {
                return String(localized: "\(outdoorPercent)% outdoor success this week, \(accidentsToday) accident(s) today.", table: table)
            } else {
                return String(localized: "\(outdoorPercent)% outdoor success this week.", table: table)
            }
        }

        static func benchContext(napsInCrate: Int, totalNaps: Int) -> String {
            if totalNaps == 0 {
                return String(localized: "No naps logged recently.", table: table)
            }
            let percent = totalNaps > 0 ? (napsInCrate * 100 / totalNaps) : 0
            return String(localized: "\(percent)% of naps in the crate (\(napsInCrate) of \(totalNaps)).", table: table)
        }

        static func sleepContext(avgNightHours: Double, napsToday: Int) -> String {
            let hours = String(format: "%.1f", avgNightHours)
            return String(localized: "Averaging \(hours)h night sleep, \(napsToday) nap(s) today.", table: table)
        }

        static func walksContext(walksThisWeek: Int, avgDuration: Int) -> String {
            return String(localized: "\(walksThisWeek) walks this week, averaging \(avgDuration) min.", table: table)
        }

        static func skillsContext(activeSkills: Int, sessionsThisWeek: Int) -> String {
            return String(localized: "\(activeSkills) skills in progress, \(sessionsThisWeek) sessions this week.", table: table)
        }

        // MARK: - Onboarding
        static let onboardingTitle = String(localized: "How's it going?", table: table)
        static let onboardingSubtitle = String(localized: "A quick check-in helps us focus advice on what matters most.", table: table)
        static let thankYouTitle = String(localized: "Thanks for sharing!", table: table)
        static let thankYouSubtitle = String(localized: "We'll use this to give you more relevant tips and advice.", table: table)

        // MARK: - Category Hints
        static let skillsTrainingHint = String(localized: "Commands like sit, down, stay, come, and leave it.", table: table)

        // MARK: - Primary Focus
        static let primaryFocusTitle = String(localized: "Main focus", table: table)
        static let primaryFocusSubtitle = String(localized: "What do you most want help with?", table: table)
        static let setPrimaryFocus = String(localized: "Set as main focus", table: table)
        static let clearPrimaryFocus = String(localized: "Clear main focus", table: table)

        // MARK: - Focus Area
        static let goodAreaToFocus = String(localized: "This is a good area to focus on right now.", table: table)

        // MARK: - Root Cause Explanations
        static let rootCausePottyCrate = String(localized: "Crate training helps with potty training - puppies naturally avoid soiling their den.", table: table)
        static let rootCauseNippingSleep = String(localized: "Overtired puppies bite more. Getting enough sleep will reduce nipping.", table: table)
        static let rootCauseNippingCrate = String(localized: "The crate gives you a timeout option and ensures your pup gets enough rest.", table: table)
        static let rootCauseSeparationCrate = String(localized: "Crate training builds comfort with alone time, which prevents separation anxiety.", table: table)
        static let rootCauseChewingSleep = String(localized: "Tired or bored puppies chew more. Enforcing naps helps.", table: table)
        static let rootCauseChewingCrate = String(localized: "When you can't supervise, the crate prevents destructive chewing.", table: table)
        static let rootCauseBarkingSleep = String(localized: "Overtired puppies are more reactive. More sleep often means less barking.", table: table)

        // MARK: - Tips: Crate Training
        static let tipCrateWhiningTitle = String(localized: "The 1-minute rule", table: table)
        static let tipCrateWhiningBody = String(localized: "Puppies will settle if you can wait through about 1 minute of whining. Sit nearby so they know you're there.", table: table)
        static let tipCrateLocationTitle = String(localized: "Location matters", table: table)
        static let tipCrateLocationBody = String(localized: "Put the crate in a quiet corner of a social room - not isolated, but not in the middle of activity.", table: table)
        static let tipCrateCoverTitle = String(localized: "Create a cozy den", table: table)
        static let tipCrateCoverBody = String(localized: "Cover the crate with a blanket to create a den-like feeling. Leave one side open for airflow.", table: table)
        static let tipCratePositiveTitle = String(localized: "Never punish", table: table)
        static let tipCratePositiveBody = String(localized: "The crate should always be positive. Never use it as punishment or your pup will resist going in.", table: table)
        static let tipCrateBenefitsTitle = String(localized: "Why crate training matters", table: table)
        static let tipCrateBenefitsBody = String(localized: "It helps with potty training, prevents destructive behavior, and gives your pup a safe space.", table: table)

        // MARK: - Tips: Potty Training
        static let tipPottyScheduleTitle = String(localized: "Timing is everything", table: table)
        static let tipPottyScheduleBody = String(localized: "Take your puppy out immediately after waking, eating, playing, and every 1-2 hours while awake.", table: table)
        static let tipPottyCrateTitle = String(localized: "Use the crate", table: table)
        static let tipPottyCrateBody = String(localized: "Puppies naturally avoid soiling where they sleep. The crate makes potty training much easier.", table: table)
        static let tipPottyAccidentTitle = String(localized: "Don't punish accidents", table: table)
        static let tipPottyAccidentBody = String(localized: "Clean up calmly without scolding. Punishment creates fear, not learning.", table: table)
        static let tipPottyRewardTitle = String(localized: "Celebrate outside!", table: table)
        static let tipPottyRewardBody = String(localized: "Give treats and praise immediately when your puppy goes outside. Make it a party!", table: table)

        // MARK: - Tips: Sleep
        static let tipSleepAmountTitle = String(localized: "18-20 hours daily", table: table)
        static let tipSleepAmountBody = String(localized: "Puppies need 18-20 hours of sleep per day. If yours isn't sleeping this much, enforce more naps.", table: table)
        static let tipSleepEnforceTitle = String(localized: "Enforce naps", table: table)
        static let tipSleepEnforceBody = String(localized: "Puppies don't know when they're tired. After 1-2 hours awake, put them in the crate for a nap.", table: table)
        static let tipSleepOvertiredTitle = String(localized: "Watch for overtired signs", table: table)
        static let tipSleepOvertiredBody = String(localized: "Biting, zoomies, not listening, and being generally 'difficult' often means your pup needs sleep.", table: table)

        // MARK: - Tips: Nipping
        static let tipNippingSleepTitle = String(localized: "Sleep prevents biting", table: table)
        static let tipNippingSleepBody = String(localized: "Most nipping happens when puppies are overtired. A well-rested pup bites much less.", table: table)
        static let tipNippingTimeoutTitle = String(localized: "Use timeouts", table: table)
        static let tipNippingTimeoutBody = String(localized: "When biting gets intense, calmly put your pup in the crate for a few minutes to settle down.", table: table)
        static let tipNippingRedirectTitle = String(localized: "Redirect to toys", table: table)
        static let tipNippingRedirectBody = String(localized: "Always have a toy nearby to redirect biting. Praise when they bite the toy instead of you.", table: table)
        static let tipNippingNormalTitle = String(localized: "It's normal (but temporary)", table: table)
        static let tipNippingNormalBody = String(localized: "All puppies go through a nippy phase. With consistent management, it peaks around 12-16 weeks then fades.", table: table)

        // MARK: - Tips: Training
        static let tipTrainingHungryTitle = String(localized: "Train before meals", table: table)
        static let tipTrainingHungryBody = String(localized: "A hungry puppy is a motivated puppy. Schedule training sessions before meal times.", table: table)
        static let tipTrainingShortTitle = String(localized: "Keep it short", table: table)
        static let tipTrainingShortBody = String(localized: "5-10 minute sessions work best. End on a win and your pup will be eager for next time.", table: table)
        static let tipTrainingKibbleTitle = String(localized: "Use kibble for training", table: table)
        static let tipTrainingKibbleBody = String(localized: "If training isn't working, try switching to kibble as treats. Fresh food can make them picky.", table: table)

        // MARK: - Tips: Chewing
        static let tipChewingBoredTitle = String(localized: "Boredom causes chewing", table: table)
        static let tipChewingBoredBody = String(localized: "Puppies chew when bored or understimulated. Provide appropriate chew toys and puzzles.", table: table)
        static let tipChewingTeethingTitle = String(localized: "Teething relief", table: table)
        static let tipChewingTeethingBody = String(localized: "Frozen washcloths and frozen Kongs help soothe teething gums and redirect chewing.", table: table)

        // MARK: - Tips: Separation
        static let tipSeparationCrateTitle = String(localized: "Crate builds confidence", table: table)
        static let tipSeparationCrateBody = String(localized: "Regular crate time teaches your pup that being alone is okay. Start with short periods.", table: table)
        static let tipSeparationGradualTitle = String(localized: "Start small", table: table)
        static let tipSeparationGradualBody = String(localized: "Leave the room for just seconds at first, then gradually increase. Build up to longer absences.", table: table)

        // MARK: - Tips: Barking
        static let tipBarkingTiredTitle = String(localized: "Check sleep first", table: table)
        static let tipBarkingTiredBody = String(localized: "Overtired puppies are more reactive and bark more. More naps often means less barking.", table: table)
        static let tipBarkingAlertTitle = String(localized: "Acknowledge, then redirect", table: table)
        static let tipBarkingAlertBody = String(localized: "Thank your pup for alerting you, then redirect with a 'quiet' cue or toy.", table: table)

        // MARK: - Tips: Jumping
        static let tipJumpingSitTitle = String(localized: "Four on the floor", table: table)
        static let tipJumpingSitBody = String(localized: "Only give attention when all four paws are on the ground. Reward sitting automatically.", table: table)
        static let tipJumpingIgnoreTitle = String(localized: "Turn away", table: table)
        static let tipJumpingIgnoreBody = String(localized: "When your pup jumps, turn away and ignore. Attention - even negative - rewards jumping.", table: table)

        // MARK: - Tips: Leash
        static let tipLeashEngagementTitle = String(localized: "Be interesting", table: table)
        static let tipLeashEngagementBody = String(localized: "If your pup pulls toward distractions, become more interesting! Use treats and engagement.", table: table)
        static let tipLeashStopTitle = String(localized: "Stop and wait", table: table)
        static let tipLeashStopBody = String(localized: "When the leash goes tight, stop moving. Only walk again when there's slack. Consistency is key.", table: table)

        // MARK: - Actions
        static let learnMore = String(localized: "Learn more", table: table)
    }
}
