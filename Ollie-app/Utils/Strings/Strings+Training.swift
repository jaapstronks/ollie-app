//
//  Strings+Training.swift
//  Otis-app
//
//  Training module strings including skill content

import Foundation

private let table = "Training"

extension Strings {

    // MARK: - Train Tab
    enum Train {
        static let pottyProgress = String(localized: "Potty Progress", table: table)
        static let socialization = String(localized: "Socialization", table: table)
        static let skills = String(localized: "Skills", table: table)
        static let skillsDescription = String(localized: "Teach essential commands", table: table)
        static let outdoorThisWeek = String(localized: "outdoor this week", table: table)
        static let dayStreak = String(localized: "day streak", table: table)
        static let topTriggers = String(localized: "Top triggers", table: table)
        static let allCategories = String(localized: "All categories", table: table)
        static let startTraining = String(localized: "Start training", table: table)
        static let continueTraining = String(localized: "Continue training", table: table)

        // Accessibility
        static let progressRingAccessibility = String(localized: "Training progress", table: table)
        static func progressValue(started: Int, total: Int) -> String {
            String(localized: "\(started) of \(total) skills started", table: table)
        }
        static func skillAccessibility(name: String, status: String) -> String {
            String(localized: "\(name), \(status)", table: table)
        }
        static let skillNotStarted = String(localized: "not started", table: table)
        static let skillStarted = String(localized: "started", table: table)
        static let skillPracticing = String(localized: "practicing", table: table)
        static let skillMastered = String(localized: "mastered", table: table)

        // Training plan subtitle
        static func focusAndReview(focus: Int, review: Int) -> String {
            String(localized: "\(focus) focus, \(review) review", table: table)
        }
        static func skillsToPractice(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 skill to practice", table: table)
            } else {
                return String(localized: "\(count) skills to practice", table: table)
            }
        }
        static func skillsToReview(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 skill to review", table: table)
            } else {
                return String(localized: "\(count) skills to review", table: table)
            }
        }
    }

    // MARK: - Training
    enum Training {
        static let title = String(localized: "Training", table: table)
        static let skillTracker = String(localized: "Skill Tracker", table: table)

        // Categories
        static let categoryFoundations = String(localized: "Foundations", table: table)
        static let categoryBasicCommands = String(localized: "Basic Commands", table: table)
        static let categoryCare = String(localized: "Care", table: table)
        static let categorySafety = String(localized: "Safety", table: table)
        static let categoryImpulseControl = String(localized: "Impulse Control", table: table)

        // Training Methods
        static let methodOperant = String(localized: "Operant", table: table)
        static let methodClassical = String(localized: "Classical", table: table)
        static let methodOperantShort = String(localized: "Dog self-discovers", table: table)
        static let methodClassicalShort = String(localized: "Guide with lure", table: table)

        // Session Recommendation
        static func sessionRecommendation(minutes: Int, timesPerDay: Int) -> String {
            String(localized: "\(minutes) min, \(timesPerDay)x daily", table: table)
        }

        // Common Mistakes section
        static let commonMistakes = String(localized: "Common Mistakes", table: table)

        // Status
        static let statusNotStarted = String(localized: "Not started", table: table)
        static let statusStarted = String(localized: "Started", table: table)
        static let statusPracticing = String(localized: "Practicing", table: table)
        static let statusMastered = String(localized: "Mastered", table: table)

        // Learning Phases (from SkillLearningPhase)
        static let phaseLuring = String(localized: "Luring", table: table)
        static let phaseAddingCue = String(localized: "Adding cue", table: table)
        static let phaseProofing = String(localized: "Proofing", table: table)
        static let phaseGeneralizing = String(localized: "Generalizing", table: table)
        static let phaseMaintaining = String(localized: "Maintaining", table: table)
        static let phaseNeedsWork = String(localized: "Needs work", table: table)

        // Context practice
        static let practicedIn = String(localized: "Practiced in", table: table)
        static func contextsReliable(reliable: Int, total: Int) -> String {
            String(localized: "\(reliable)/\(total) reliable", table: table)
        }

        // Week hero card
        static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)", table: table)
        }
        static let focusSkills = String(localized: "Focus skills", table: table)
        static func progressCount(started: Int, total: Int) -> String {
            String(localized: "\(started)/\(total) started", table: table)
        }

        // Skill card
        static func sessionCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 session", table: table)
            } else {
                return String(localized: "\(count) sessions", table: table)
            }
        }
        static let locked = String(localized: "Locked", table: table)
        static let requires = String(localized: "Requires", table: table)
        static let howTo = String(localized: "How to train", table: table)
        static let doneWhen = String(localized: "Done when", table: table)
        static let tips = String(localized: "Tips", table: table)
        static let recentSessions = String(localized: "Recent sessions", table: table)
        static let logSession = String(localized: "Log session", table: table)
        static let trainInApp = String(localized: "Train in-app", table: table)
        static let markMastered = String(localized: "Mark as mastered", table: table)
        static let markMasteredHint = String(localized: "Mark this skill as mastered to unlock dependent skills", table: table)
        static let unmarkMastered = String(localized: "Unmark mastered", table: table)
        static let quickDone = String(localized: "Quick log", table: table)
        static let quickDoneHint = String(localized: "Instantly log a completed training session", table: table)

        // Log sheet
        static let logTrainingSession = String(localized: "Log Training Session", table: table)
        static let duration = String(localized: "Duration", table: table)
        static let durationMinutes = String(localized: "minutes", table: table)
        static let result = String(localized: "Result", table: table)
        static let resultPlaceholder = String(localized: "e.g. Good focus, needed help", table: table)
        static let note = String(localized: "Note", table: table)
        static let notePlaceholder = String(localized: "Optional note...", table: table)

        // Empty state
        static let noSkillsStarted = String(localized: "No skills started yet", table: table)
        static let tapToBegin = String(localized: "Tap a skill to begin training", table: table)

        // MARK: - Skill Progress & Spaced Repetition

        // Session feedback (from TrainingEngine)
        static let excellentSession = String(localized: "Excellent session!", table: table)
        static let goodProgress = String(localized: "Good progress", table: table)
        static let needsMoreWork = String(localized: "Needs more work", table: table)
        static let stepBackRecommended = String(localized: "Consider stepping back", table: table)

        // Priority labels
        static let needsAttention = String(localized: "Needs attention", table: table)
        static let refresherNeeded = String(localized: "Refresher needed", table: table)
        static let mainFocus = String(localized: "Main focus", table: table)
        static let dueForReview = String(localized: "Due for review", table: table)
        static func dueForReviewCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 skill due for review", table: table)
            } else {
                return String(localized: "\(count) skills due for review", table: table)
            }
        }
        /// Short badge label for maintenance skills section (e.g., "2 due")
        static func skillsDueBadge(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 due", table: table, comment: "Short badge showing 1 skill is due for review")
            } else {
                return String(localized: "\(count) due", table: table, comment: "Short badge showing multiple skills are due for review")
            }
        }
        static let practiceInNewContext = String(localized: "Practice in new location", table: table)
        static let warmUp = String(localized: "Warm-up", table: table)

        // Regression messages
        static let skillNeedsRefresher = String(localized: "This skill needs a refresher", table: table)
        static let priorityShifted = String(localized: "Priority shifted to maintenance", table: table)
        static let backOnTrack = String(localized: "Back on track!", table: table)

        // Session plan
        static let todaysTraining = String(localized: "Today's Training", table: table)
        static let quickRefresher = String(localized: "Quick Refresher", table: table)
        static let startPractice = String(localized: "Start Practice", table: table)
        static let maintenanceReview = String(localized: "Maintenance review", table: table)
        static let easyFinish = String(localized: "Easy finish", table: table)
        static let easyWinToStart = String(localized: "Easy win to start", table: table)
        static let primaryFocusSubtitle = String(localized: "New skills to learn", table: table)
        static let regressionFocusSubtitle = String(localized: "These skills need attention", table: table)
        static let maintenanceSubtitle = String(localized: "Quick refresher reps", table: table)

        // Maintenance Mode
        static let maintenanceMode = String(localized: "Maintenance Mode", table: table)
        static let maintenanceModeEnabled = String(localized: "Maintenance mode enabled", table: table)
        static let enableMaintenanceMode = String(localized: "Enable maintenance mode", table: table)
        static let disableMaintenanceMode = String(localized: "Disable maintenance mode", table: table)
        static let maintenanceModeDescription = String(localized: "Get weekly reminders to practice this skill without tracking progress", table: table)
        static let skillsInMaintenance = String(localized: "Skills in Maintenance", table: table)
        static let refreshDue = String(localized: "Refresh due", table: table)
        static let refreshOverdue = String(localized: "Overdue", table: table)
        static let lastPracticed = String(localized: "Last practiced", table: table)
        static let practicedToday = String(localized: "Practiced today", table: table)
        static let neverPracticed = String(localized: "Never practiced", table: table)
        static let refreshNow = String(localized: "Refresh Now", table: table)
        static let markRefreshed = String(localized: "Mark Refreshed", table: table)
        static func daysAgo(_ days: Int) -> String {
            if days == 1 {
                return String(localized: "1 day ago", table: table)
            }
            return String(localized: "\(days) days ago", table: table)
        }
        static let noMaintenanceSkills = String(localized: "No skills in maintenance", table: table)
        static let noMaintenanceSkillsDescription = String(localized: "Mark skills as maintained when you've taught them and want weekly refresh reminders", table: table)
        static let endOnSuccess = String(localized: "End on a success", table: table)
        static let elapsed = String(localized: "Elapsed", table: table)
        static let recommendedMinutes = String(localized: "min recommended", table: table)
        static let startSession = String(localized: "Start Session", table: table)
        static let sessionLong = String(localized: "Session getting long", table: table)
        static let sessionComplete = String(localized: "Session Complete!", table: table)
        static let greatWorkMessage = String(localized: "Great work! Regular short sessions are the key to success.", table: table)
        static let noSkillsDue = String(localized: "All caught up!", table: table)
        static let noSkillsDueMessage = String(localized: "No skills are due for training right now. Start a new skill or check back later.", table: table)
        static let generatingPlan = String(localized: "Generating your session...", table: table)
        static func progressLabel(completed: Int, total: Int) -> String {
            String(localized: "\(completed) of \(total) skills", table: table)
        }
        static let smartSessionPlan = String(localized: "AI-generated session plan", table: table)
        static let viewAllSkills = String(localized: "View all skills", table: table)

        // Confidence score
        static let confidenceScore = String(localized: "Confidence", table: table)
        static func confidencePercent(_ percent: Int) -> String {
            String(localized: "\(percent)% reliable", table: table)
        }

        // Context progress
        static func contextsCompleted(_ count: Int, total: Int) -> String {
            String(localized: "\(count)/\(total) contexts", table: table)
        }

        // Rep logging
        static let howDidItGo = String(localized: "How did it go?", table: table)
        static let successfulReps = String(localized: "Successful reps", table: table)
        static let failedReps = String(localized: "Failed reps", table: table)
        static let whereDidYouTrain = String(localized: "Where did you train?", table: table)

        // Training contexts
        static let contextHome = String(localized: "Home", table: table)
        static let contextGarden = String(localized: "Garden", table: table)
        static let contextQuietStreet = String(localized: "Quiet street", table: table)
        static let contextBusyStreet = String(localized: "Busy street", table: table)
        static let contextPark = String(localized: "Park", table: table)
        static let contextIndoorPublic = String(localized: "Indoor public", table: table)
        static let contextCarRide = String(localized: "Car ride", table: table)
        static let contextOther = String(localized: "Other", table: table)

        // Regression alerts - friendly, non-alarming messaging
        static let refresherTime = String(localized: "Time for a refresher!", table: table)
        static func refresherNeededSingle(skillName: String) -> String {
            String(localized: "\(skillName) needs a little love", table: table)
        }
        static func refresherNeededMultiple(count: Int) -> String {
            String(localized: "\(count) skills could use some attention", table: table)
        }
        static let regressionNormalMessage = String(localized: "This is totally normal! Dogs often need refreshers, especially during adolescence. A few quick sessions will get things back on track.", table: table)
        static let needsRefresher = String(localized: "Needs refresher", table: table)
        static func skillRecovered(skillName: String) -> String {
            String(localized: "\(skillName) is back to solid!", table: table)
        }
        static func recoveredInSessions(count: Int) -> String {
            String(localized: "Recovered in \(count) sessions", table: table)
        }
        static let adolescenceTitle = String(localized: "Adolescence tip", table: table)
        static let adolescenceMessage = String(localized: "Between 6-18 months, dogs commonly \"forget\" things they knew as puppies. This is biology, not failure! Stay patient and consistent.", table: table)

        // MARK: - Multi-Member Attribution
        static let teamContributions = String(localized: "Team Contributions", table: table)
        static let sessions = String(localized: "sessions", table: table)
        static let sessionsThisWeek = String(localized: "sessions this week", table: table)
        static let weeklyLeaderboard = String(localized: "This Week's Trainers", table: table)

        // MARK: - Preparation Section
        enum Preparation {
            // Section
            static let title = String(localized: "Get Ready", table: table)
            static let subtitle = String(localized: "Complete these items before you start training", table: table)
            static let equipmentTitle = String(localized: "Equipment", table: table)
            static let conceptsTitle = String(localized: "Understanding", table: table)

            // Equipment items
            static let clicker = String(localized: "Clicker (or use in-app clicker)", table: table)
            static let treats = String(localized: "Kibble (your puppy's regular food)", table: table)
            static let quietSpace = String(localized: "Quiet training space", table: table)

            // Concept items
            static let understandOperant = String(localized: "I understand operant conditioning", table: table)
            static let understandClassical = String(localized: "I understand classical conditioning", table: table)
            static let understandTiming = String(localized: "I understand click timing", table: table)

            // Explanations (shown when tapping info button)
            static let operantExplanation = String(localized: "Operant: You stay passive, the dog discovers the behavior", table: table)
            static let classicalExplanation = String(localized: "Classical: You actively guide with a food lure", table: table)
            static let timingExplanation = String(localized: "The click marks the exact moment of correct behavior", table: table)

            // Progress
            static func itemsCompleted(_ completed: Int, total: Int) -> String {
                String(localized: "\(completed) of \(total) completed", table: table)
            }

            // Accessibility
            static func itemToggleAccessibility(name: String, isCompleted: Bool) -> String {
                if isCompleted {
                    return String(localized: "\(name), completed. Double tap to mark as incomplete.", table: table)
                }
                return String(localized: "\(name), incomplete. Double tap to mark as completed.", table: table)
            }
            static func conceptExpandAccessibility(name: String, isExpanded: Bool) -> String {
                if isExpanded {
                    return String(localized: "\(name), expanded. Double tap to collapse.", table: table)
                }
                return String(localized: "\(name). Double tap to learn more.", table: table)
            }

            // Learn more link
            static let learnMore = String(localized: "Learn more", table: table)
        }

        // MARK: - Concept Sheets
        enum Concepts {
            static let iUnderstand = String(localized: "I understand this", table: table)
            static let keyPoints = String(localized: "Key Points", table: table)
            static let example = String(localized: "Example", table: table)

            // Operant Conditioning
            enum Operant {
                static let title = String(localized: "Operant Conditioning", table: table)
                static let subtitle = String(localized: "The dog figures it out themselves", table: table)
                static let explanation = String(localized: "You do nothing except observe and click for desired behavior. Hands behind your back. No luring, no pushing, no verbal cues. You simply wait. The dog figures things out on its own, and you mark the moment it happens. This creates deep, lasting learning.", table: table)
                static let point1 = String(localized: "Train in a low-stimulus environment — living room, no distractions", table: table)
                static let point2 = String(localized: "You are passive. Wait patiently for the behavior to happen", table: table)
                static let point3 = String(localized: "Click the exact moment you see correct behavior", table: table)
                static let point4 = String(localized: "Add the verbal command LAST — only after reliable in multiple environments", table: table)
                static let exampleTitle = String(localized: "Teaching \"Watch Me\"", table: table)
                static let exampleText = String(localized: "Sit on the floor at puppy's level. Hands behind your back. No sounds. Just wait. Eventually, they'll glance at your face. Click that instant and treat. Throw the treat behind them so they reset. Repeat. They'll start offering eye contact more and more.", table: table)
            }

            // Classical Conditioning
            enum Classical {
                static let title = String(localized: "Classical Conditioning", table: table)
                static let subtitle = String(localized: "You guide with a food lure", table: table)
                static let explanation = String(localized: "You actively guide the dog with a treat in your hand. The luring motion becomes the hand signal from the start. No verbal commands during training — work only with hand signals. Words come last, after the behavior is reliable.", table: table)
                static let point1 = String(localized: "Hold a treat at your puppy's nose and guide them slowly", table: table)
                static let point2 = String(localized: "The hand signal is introduced immediately — the lure IS the signal", table: table)
                static let point3 = String(localized: "Click when they reach the desired position", table: table)
                static let point4 = String(localized: "No verbal commands. Hand signals can't be repeated 'louder'", table: table)
                static let exampleTitle = String(localized: "Teaching \"Sit\"", table: table)
                static let exampleText = String(localized: "Treat on nose. Move slowly toward the EARS (not over the head). Nose follows up, bottom goes down. Click the moment they sit. The final hand signal: hand rises beside your face — visible even in a winter coat.", table: table)
            }

            // Click Timing
            enum Timing {
                static let title = String(localized: "Click Timing", table: table)
                static let subtitle = String(localized: "The click ends the exercise", table: table)
                static let explanation = String(localized: "The click marks the exact moment of correct behavior. It signals 'well done, you can relax now.' Don't expect the dog to hold position after clicking. Every click MUST be followed by a treat — clicking without treating destroys the association.", table: table)
                static let point1 = String(localized: "Click at the EXACT moment of correct behavior", table: table)
                static let point2 = String(localized: "Always follow a click with a treat within 1-2 seconds", table: table)
                static let point3 = String(localized: "Never click without treating — this is a fundamental rule", table: table)
                static let point4 = String(localized: "If you click by accident, still give a treat to maintain the association", table: table)
                static let exampleTitle = String(localized: "Marking \"Sit\"", table: table)
                static let exampleText = String(localized: "As your puppy's bottom touches the floor, click THAT instant — not halfway down, not after they've been sitting. The click captures the moment. Then deliver the treat within 1-2 seconds. The click buys you that time.", table: table)
            }
        }

        // MARK: - Learning Phases
        enum Phases {
            // Generic
            static let overview = String(localized: "Overview", table: table)
            static let allSteps = String(localized: "All Steps", table: table)
            static let phaseComplete = String(localized: "I've practiced this", table: table)
            static let continueButton = String(localized: "Continue", table: table)
            static let startLearning = String(localized: "Start Learning", table: table)
            static let continueLearning = String(localized: "Continue Learning", table: table)
            static let startTraining = String(localized: "Start Training", table: table)
            static let continueTraining = String(localized: "Continue Training", table: table)
            static let whatYouWillLearn = String(localized: "What you'll learn", table: table)
            static let goalTitle = String(localized: "Goal", table: table)

            // Phase-based status descriptions
            static func phasesCompleted(_ completed: Int, total: Int) -> String {
                String(localized: "\(completed) of \(total) phases completed", table: table)
            }
            static let inProgress = String(localized: "In progress", table: table)

            static func phaseProgress(current: Int, total: Int) -> String {
                String(localized: "Phase \(current) of \(total)", table: table)
            }

            // Collar & Leash phases
            static let collarLeashIntroductionName = String(localized: "Introduction", table: table)
            static let collarLeashIntroductionSubtitle = String(localized: "Getting comfortable with the collar", table: table)
            static let collarLeashBuildDurationName = String(localized: "Build Duration", table: table)
            static let collarLeashBuildDurationSubtitle = String(localized: "Wearing the collar for longer periods", table: table)
            static let collarLeashLeashWorkName = String(localized: "Leash Introduction", table: table)
            static let collarLeashLeashWorkSubtitle = String(localized: "Accepting the leash without panic", table: table)

            // Watch Me phases
            static let watchMeCaptureAttentionName = String(localized: "Capture Natural Attention", table: table)
            static let watchMeCaptureAttentionSubtitle = String(localized: "Reward natural eye contact without prompting", table: table)
            static let watchMePositionProgressionName = String(localized: "Position & Distraction", table: table)
            static let watchMePositionProgressionSubtitle = String(localized: "Practice at different heights with visual distractions", table: table)
            static let watchMeAddCueName = String(localized: "Add Verbal Cue", table: table)
            static let watchMeAddCueSubtitle = String(localized: "Pair the 'watch me' command with the behavior", table: table)
            static let watchMeProofName = String(localized: "Proof with 3 D's", table: table)
            static let watchMeProofSubtitle = String(localized: "Build duration, distance, and work through distractions", table: table)

            // Loose Leash Walking phases
            static let looseLeashCapturePositionName = String(localized: "Capture Position", table: table)
            static let looseLeashCapturePositionSubtitle = String(localized: "Reward being at your side with high frequency", table: table)
            static let looseLeashBuildDurationName = String(localized: "Build Duration", table: table)
            static let looseLeashBuildDurationSubtitle = String(localized: "Gradually increase steps between rewards", table: table)
            static let looseLeashAddCueName = String(localized: "Add Verbal Cue", table: table)
            static let looseLeashAddCueSubtitle = String(localized: "Pair 'let's go' with starting to walk", table: table)
            static let looseLeashProofEnvironmentsName = String(localized: "Proof in Environments", table: table)
            static let looseLeashProofEnvironmentsSubtitle = String(localized: "Practice in progressively distracting locations", table: table)

            // Come (Magic Recall) phases
            static let comeChooseMagicWordName = String(localized: "Choose Your Magic Word", table: table)
            static let comeChooseMagicWordSubtitle = String(localized: "Pick a special word and high-value treat", table: table)
            static let comeBuildAssociationName = String(localized: "Build the Association", table: table)
            static let comeBuildAssociationSubtitle = String(localized: "Magic word = jackpot treat, every time", table: table)
            static let comePartnerExerciseName = String(localized: "Partner Exercise", table: table)
            static let comePartnerExerciseSubtitle = String(localized: "Sit down, spread arms, call with excitement", table: table)
            static let comeProofAndProgressName = String(localized: "Proof & Progress", table: table)
            static let comeProofAndProgressSubtitle = String(localized: "Practice in new places, add distractions gradually", table: table)

            // Sit phases
            static let sitLureToPositionName = String(localized: "Lure to Position", table: table)
            static let sitLureToPositionSubtitle = String(localized: "Guide your puppy into a sit with a treat", table: table)
            static let sitCaptureAndStrengthenName = String(localized: "Capture & Strengthen", table: table)
            static let sitCaptureAndStrengthenSubtitle = String(localized: "Reward natural sits and build reliability", table: table)
            static let sitAddVerbalCueName = String(localized: "Add Verbal Cue", table: table)
            static let sitAddVerbalCueSubtitle = String(localized: "Pair the word 'sit' with the behavior", table: table)
            static let sitProofThreeDsName = String(localized: "Proof with 3 D's", table: table)
            static let sitProofThreeDsSubtitle = String(localized: "Build duration, distance, and handle distractions", table: table)
        }

        // MARK: - Training Rules
        enum Rules {
            static let title = String(localized: "Training Rules", table: table)
            static let subtitle = String(localized: "Important principles you've learned", table: table)
            static let gotIt = String(localized: "Got it", table: table)
            static let noRulesYet = String(localized: "Rules will appear here as you progress through training", table: table)
            static let acknowledgeHint = String(localized: "Double tap to acknowledge and continue to training", table: table)
            static func ruleCardAccessibility(title: String, isExpanded: Bool) -> String {
                if isExpanded {
                    return String(localized: "\(title), expanded. Double tap to collapse.", table: table)
                }
                return String(localized: "\(title). Double tap to expand.", table: table)
            }

            // Rule content
            static let neverClickWithoutRewardTitle = String(localized: "Never Click Without Reward", table: table)
            static let neverClickWithoutRewardDescription = String(localized: "Every click MUST be followed by a treat. A click without reward breaks the association.", table: table)

            static let wordMustMatchMomentTitle = String(localized: "Word Must Match the Moment", table: table)
            static let wordMustMatchMomentDescription = String(localized: "Say the cue word AS the behavior happens, not before. The dog learns to connect the word with the action.", table: table)

            static let clickEndsExerciseTitle = String(localized: "Click Ends the Exercise", table: table)
            static let clickEndsExerciseDescription = String(localized: "The click signals 'well done, you can relax now'. Don't expect the dog to hold position after clicking.", table: table)

            static let stepBackIfStrugglingTitle = String(localized: "Step Back If Struggling", table: table)
            static let stepBackIfStrugglingDescription = String(localized: "If your dog struggles, go back to an easier step. Success builds confidence.", table: table)
        }

        // MARK: - Practice Matrix
        enum Matrix {
            // Location tiers
            static let inside = String(localized: "Inside", table: table)
            static let outside = String(localized: "Outside", table: table)

            // Cell states
            static let locked = String(localized: "Locked", table: table)
            static let notStarted = String(localized: "Not started", table: table)
            static let inProgress = String(localized: "In progress", table: table)
            static let mastered = String(localized: "Mastered", table: table)

            // Progress
            static func phasesProgress(mastered: Int, total: Int) -> String {
                String(localized: "\(mastered) of \(total) phases mastered", table: table)
            }
            static let allPhasesMastered = String(localized: "All phases mastered!", table: table)
            static let legend = String(localized: "Legend", table: table)

            // Suggested next
            static let suggestedNext = String(localized: "Suggested next", table: table)
            static let tapToPractice = String(localized: "Tap to practice", table: table)

            // Theory flow
            static let alreadyKnowThis = String(localized: "I already know this", table: table)
            static let startPracticing = String(localized: "Start Practicing", table: table)
            static let rereadTheory = String(localized: "Re-read theory", table: table)
            static func readingProgress(read: Int, total: Int) -> String {
                String(localized: "\(read) of \(total) pages read", table: table)
            }
            static func phaseNumber(_ number: Int) -> String {
                String(localized: "Phase \(number)", table: table)
            }

            // Practice cell sheet
            static let practiceDetails = String(localized: "Practice Details", table: table)
            static let quickReminder = String(localized: "Quick Reminder", table: table)
            static let buildingOn = String(localized: "Building on", table: table)
            static let iPracticedThis = String(localized: "I practiced this", table: table)
            static let myDogHasMastered = String(localized: "My dog has mastered this", table: table)
            static let stillMastered = String(localized: "Still mastered", table: table)
            static let unmarkMastered = String(localized: "Unmark mastered", table: table)
            static let practiceAnyway = String(localized: "Practice anyway", table: table)
            static let cellLocked = String(localized: "This cell is locked", table: table)
            static let cellLockedExplanation = String(localized: "Complete the previous step first, or tap 'Practice anyway' to override.", table: table)
            static func lastPracticed(_ relativeTime: String) -> String {
                String(localized: "Last practiced \(relativeTime)", table: table)
            }

            // Skill phases page (redesigned)
            static let learnTheory = String(localized: "Learn the Theory", table: table)
            static let theoryComplete = String(localized: "Complete", table: table)
            static let theoryNotStarted = String(localized: "Not started yet", table: table)
            static func masterPhaseFirst(_ phaseName: String) -> String {
                String(localized: "Master \(phaseName) inside first", table: table)
            }
            static let yourProgress = String(localized: "Your Progress", table: table)
            static let howToDoIt = String(localized: "How to do it", table: table)
            static let neverPracticed = String(localized: "Never practiced", table: table)
            static let logPractice = String(localized: "Log practice session", table: table)
            static let markInProgress = String(localized: "Mark in progress", table: table)
            static let markMastered = String(localized: "Mark as mastered", table: table)
            static let masteredDescription = String(localized: "Your dog performs this reliably in this environment", table: table)
            static let practiceAnywayDescription = String(localized: "Skip the recommended order", table: table)
            static let lockedDescription = String(localized: "Complete the inside location first", table: table)
            static let insideLocation = String(localized: "Inside (home, indoor spaces)", table: table)
            static let outsideLocation = String(localized: "Outside (garden, street, park)", table: table)
        }

        // MARK: - Progression
        enum Progression {
            static let nextUp = String(localized: "Next Up", table: table)
            static let startTraining = String(localized: "Start Training", table: table)
            static let continueTraining = String(localized: "Continue", table: table)
            static let completed = String(localized: "Completed", table: table)
            static let lockedSection = String(localized: "Coming Up", table: table)
            static let masteredSection = String(localized: "Mastered", table: table)
            static let inProgressSection = String(localized: "In Progress", table: table)
            static func masteredSkillsRequired(_ skills: String) -> String {
                String(localized: "Builds on: \(skills)", table: table)
            }
            static let preparationRequired = String(localized: "Complete preparation first", table: table)
            static let viewRules = String(localized: "View Training Rules", table: table)
            static let allSkillsMastered = String(localized: "All skills mastered!", table: table)

            // Prerequisite warning
            static let skipPrerequisitesTitle = String(localized: "Start This Skill?", table: table)
            static func skipPrerequisitesMessage(_ skills: String) -> String {
                String(localized: "This skill builds on: \(skills). Starting without those foundations may make learning harder.", table: table)
            }
            static let startAnyway = String(localized: "Start Anyway", table: table)
            static let learnPrerequisitesFirst = String(localized: "Learn Prerequisites First", table: table)

            // Accessibility
            static func skillLockedAccessibility(name: String, requires: String) -> String {
                String(localized: "\(name), locked. Requires: \(requires)", table: table)
            }
            static func skillStatusAccessibility(name: String, status: String, sessions: Int) -> String {
                if sessions > 0 {
                    return String(localized: "\(name), \(status), \(sessions) sessions completed", table: table)
                }
                return String(localized: "\(name), \(status)", table: table)
            }
            static let viewSkillDetails = String(localized: "View skill details", table: table)
        }

        // MARK: - Training Principles
        enum Principles {
            static let sectionTitle = String(localized: "Training Principles", table: table)

            // Operant vs Classical
            static let methodsTitle = String(localized: "Training Methods", table: table)
            static let operantTitle = String(localized: "Operant (Passive)", table: table)
            static let operantDescription = String(localized: "You stay passive — hands behind your back, no luring, no pushing, no verbal cues. You simply wait and observe. The dog figures things out on their own, and you click for desired behavior. Creates deeper, lasting learning. Best for: attention, calm behaviors.", table: table)
            static let classicalTitle = String(localized: "Classical (Active)", table: table)
            static let classicalDescription = String(localized: "You actively guide the dog with a food lure in your hand. The luring motion becomes the hand signal. Can be used in stimulating environments. Produces faster initial learning. Best for: sit, down, follow exercises.", table: table)

            // Core Principles
            static let timingTitle = String(localized: "Timing", table: table)
            static let timingDescription = String(localized: "The click marks the exact moment of correct behavior. Always reward within 1-2 seconds. If you click by accident, still give a treat — maintaining the association is paramount.", table: table)

            static let neverClickTitle = String(localized: "Never Click Without Reward", table: table)
            static let neverClickDescription = String(localized: "Every single click MUST be followed by a treat. Clicking without treating destroys the association you've built. This is a fundamental rule.", table: table)

            static let commandTimingTitle = String(localized: "Why Hand Signals First", table: table)
            static let commandTimingDescription = String(localized: "Work with hand signals, not words. Humans misuse words — we repeat, escalate, add pressure ('sit, sit, SIT!'). Hand signals can't be made 'louder' or more forceful. Add verbal cues only AFTER the behavior is reliable.", table: table)

            static let environmentTitle = String(localized: "Environment Progression", table: table)
            static let environmentDescription = String(localized: "1) Living room, 2) Kitchen, 3) Garden/doorstep, 4) Quiet street, 5) Park, 6) Beach/busy areas. Only move to a new environment when the previous one is solid. If struggling in a new place, go back to step 1.", table: table)

            static let sessionLengthTitle = String(localized: "Session Guidelines", table: table)
            static let sessionLengthDescription = String(localized: "2-3 short sessions daily (5 minutes each). Don't train during the whole walk — dedicate training to short focused sessions. Walks are for experiencing the world.", table: table)

            static let stepBackTitle = String(localized: "The Step-Back Principle", table: table)
            static let stepBackDescription = String(localized: "Every exercise has a starting step and an end goal. If a behavior works perfectly at home but falls apart elsewhere — go back to step 1. A dog who has done 'down' perfectly for two years may refuse in snow because it feels strange. Never forget the first steps — they're your fallback.", table: table)

            static let variableRewardTitle = String(localized: "Variable Reward", table: table)
            static let variableRewardDescription = String(localized: "If a behavior is no longer rewarded, it disappears. If variably rewarded (sometimes yes, sometimes no), it persists forever — the 'slot machine effect' keeps dogs eager. Phase out constant rewards, but never stop rewarding entirely.", table: table)

            static let releaseWordTitle = String(localized: "Release Word", table: table)
            static let releaseWordDescription = String(localized: "Train a release word ('free') to signal 'you're off duty'. Toss treats in the grass and say 'free, free, free' as your dog sniffs. During free time, keep saying it so the dog links the behavior to the word.", table: table)
        }

        // MARK: - Equipment Guidance
        enum Equipment {
            static let sectionTitle = String(localized: "Equipment", table: table)
            static let leashTitle = String(localized: "Leash", table: table)
            static let leashDescription = String(localized: "1.8–2 meters, fixed length. No retractable leashes — they teach pulling, can drop and scare your puppy, and offer zero control.", table: table)
            static let collarTitle = String(localized: "Collar", table: table)
            static let collarDescription = String(localized: "Regular flat collar. Two fingers should fit underneath. Always have a collar on even if using a harness — some exercises require the collar, and harnesses can twist.", table: table)
            static let harnessTitle = String(localized: "Harness", table: table)
            static let harnessDescription = String(localized: "Fine to use, but always have a regular collar on as well. Some exercises require collar control — harnesses can twist sideways and dogs can escape.", table: table)
            static let clickerTitle = String(localized: "Clicker", table: table)
            static let clickerDescription = String(localized: "Clicker in left hand, treats in right hand. Muffle it initially (under a cushion, in your pocket) — gradually expose your puppy to the full volume.", table: table)
            static let treatsTitle = String(localized: "Treats", table: table)
            static let treatsDescription = String(localized: "Use your puppy's regular kibble for everyday training — not fancy treats. A different brand/flavor of kibble works for harder environments. Reserve special treats (chicken, cheese) ONLY for recall training.", table: table)
            static let treatMotivationTitle = String(localized: "Food Motivation", table: table)
            static let treatMotivationDescription = String(localized: "Feed from your fingers, not a bowl — your puppy earns food through training. If they won't work for kibble, they're too 'wealthy'. A motivated dog progresses fast.", table: table)
        }

        // MARK: - Training Guides
        enum Guides {
            // Entry cards
            static let pottyTitle = String(localized: "Potty Training", table: table)
            static let pottySubtitle = String(localized: "Outdoor success tips", table: table)
            static let crateTitle = String(localized: "Crate Training", table: table)
            static let crateSubtitle = String(localized: "Your pup's happy place", table: table)

            // Potty guide sheet
            static let pottyGuideTitle = String(localized: "Potty Training Guide", table: table)
            static let currentProgress = String(localized: "Current Progress", table: table)
            static let outdoorStreak = String(localized: "Outdoor Streak", table: table)
            static let outdoorRate = String(localized: "Outdoor Rate", table: table)
            static let keyPrinciples = String(localized: "Key Principles", table: table)
            static let tipsForYourPuppy = String(localized: "Tips for Your Puppy", table: table)
            static let commonMistakes = String(localized: "Common Mistakes", table: table)
            static let getStarted = String(localized: "Get started", table: table)

            // Age-based tips headers
            static let earlyWeeks = String(localized: "8-12 Weeks: Foundation Phase", table: table)
            static let middleWeeks = String(localized: "12-16 Weeks: Building Habits", table: table)
            static let olderPuppy = String(localized: "16+ Weeks: Maintaining Success", table: table)

            // Principles
            static let principleTiming = String(localized: "Take out after waking, eating, and playing", table: table)
            static let principleReward = String(localized: "Reward immediately when they go outside", table: table)
            static let principleSupervise = String(localized: "Supervise constantly indoors - prevention is key", table: table)
            static let principlePatience = String(localized: "Never punish accidents - just clean and move on", table: table)

            // Early weeks tips (8-12)
            static let earlyTip1 = String(localized: "Take out every 30-45 minutes while awake", table: table)
            static let earlyTip2 = String(localized: "Always go out within 5 minutes of waking", table: table)
            static let earlyTip3 = String(localized: "Use a crate for naps to build bladder control", table: table)
            static let earlyTip4 = String(localized: "Pick a consistent potty spot outside", table: table)

            // Middle weeks tips (12-16)
            static let middleTip1 = String(localized: "Start extending time between potty breaks", table: table)
            static let middleTip2 = String(localized: "Watch for sniffing or circling - immediate potty signal", table: table)
            static let middleTip3 = String(localized: "Celebrate outdoor successes enthusiastically", table: table)
            static let middleTip4 = String(localized: "Keep a consistent schedule, even on weekends", table: table)

            // Older puppy tips (16+)
            static let olderTip1 = String(localized: "Maintain the schedule that's working", table: table)
            static let olderTip2 = String(localized: "Gradually reduce supervision as reliability builds", table: table)
            static let olderTip3 = String(localized: "Practice in new environments to generalize", table: table)
            static let olderTip4 = String(localized: "Keep rewarding to maintain the habit", table: table)

            // Common mistakes
            static let pottyMistake1 = String(localized: "Punishing accidents (creates fear, not learning)", table: table)
            static let pottyMistake2 = String(localized: "Not going outside with them (missing reward moments)", table: table)
            static let pottyMistake3 = String(localized: "Waiting too long after triggers (meals, naps)", table: table)
            static let pottyMistake4 = String(localized: "Inconsistent schedule (confuses the puppy)", table: table)

            // Crate guide sheet
            static let crateGuideTitle = String(localized: "Crate Training Guide", table: table)
            static let crateProgress = String(localized: "Crate Nap Progress", table: table)
            static func crateUsageMessage(percentage: Int) -> String {
                if percentage < 30 {
                    return String(localized: "Getting started with crate naps", table: table)
                } else if percentage < 70 {
                    return String(localized: "Building good crate habits", table: table)
                } else {
                    return String(localized: "Great crate routine established!", table: table)
                }
            }

            // Crate nudge card
            static func crateNudgeTitle(name: String) -> String {
                String(localized: "\(name) hasn't napped in crate today", table: table)
            }
            static let crateNudgeSubtitle = String(localized: "Crate naps help with potty training and settling", table: table)
            static let startCrateNap = String(localized: "Start Crate Nap", table: table)
            static let notNow = String(localized: "Not now", table: table)
        }

        // MARK: - Potty Training Mastery
        enum PottyTraining {
            static let masteryPromptTitle = String(localized: "Ready to mark potty training as mastered?", table: table)
            static let masteryPromptSubtitle = String(localized: "Your pup has been at 100% outdoor success for several days", table: table)
            static let markMastered = String(localized: "Mark as Mastered", table: table)
            static let markMasteredDescription = String(localized: "Your pup reliably goes potty outside and signals when they need to go", table: table)
            static let mastered = String(localized: "Mastered", table: table)
            static let masteredCelebration = String(localized: "Potty training complete!", table: table)
            static let masteredDescription = String(localized: "Your pup is potty trained! They reliably go outside and signal when needed.", table: table)
            static let reactivateTracking = String(localized: "Having accidents? Reactivate tracking", table: table)
            static func masteredOn(date: String) -> String {
                String(localized: "Mastered on \(date)", table: table)
            }
            static func daysAtPerfect(_ days: Int) -> String {
                if days == 1 {
                    return String(localized: "1 day at 100%", table: table)
                } else {
                    return String(localized: "\(days) days at 100%", table: table)
                }
            }

            // Incident messaging (gentle, not patronizing)
            static let incidentHappened = String(localized: "It happens", table: table)
            static let incidentMessage = String(localized: "One indoor moment doesn't undo all that progress. Tomorrow's a new day.", table: table)

            // Reactivation prompt
            static let reactivationTitle = String(localized: "Need some refresher tips?", table: table)
            static let reactivationMessage = String(localized: "A few indoor moments lately. Would you like to reactivate potty training guidance?", table: table)
            static let reactivateNow = String(localized: "Yes, reactivate", table: table)
            static let notNow = String(localized: "Not now", table: table)
            static let reactivateLink = String(localized: "Having accidents? Reactivate tracking", table: table)
        }

        // MARK: - Crate Training
        enum CrateTraining {
            static let sectionTitle = String(localized: "Crate Training", table: table)
            static let subtitle = String(localized: "A tool for rest and independence — not a punishment", table: table)

            // Stats
            static func crateNapPercentage(_ percent: Int) -> String {
                String(localized: "\(percent)% of recent naps in crate", table: table)
            }
            static let noNapsYet = String(localized: "No naps logged yet", table: table)

            // Benefits
            static let benefitsTitle = String(localized: "Why it helps", table: table)
            static let benefitPotty = String(localized: "Puppies avoid soiling their sleeping area, making potty training faster", table: table)
            static let benefitSelfSoothe = String(localized: "They learn to settle and self-soothe instead of getting overtired and hyper", table: table)
            static let benefitSeparation = String(localized: "Teaches that being separate from you is normal and safe — preventing separation anxiety", table: table)
            static let benefitSafeSpace = String(localized: "Gives them a safe retreat when visitors come or when life gets overwhelming", table: table)
            static let benefitLongerNaps = String(localized: "Crate naps are usually longer and more restorative", table: table)
            static let benefitIndependence = String(localized: "Dogs who follow you everywhere (room to room, up and down stairs) learn the opposite of independence. The crate prevents this.", table: table)

            // Tips
            static let tipsTitle = String(localized: "Getting started", table: table)
            static let tipCozy = String(localized: "Make it cozy with a blanket and safe chew toy", table: table)
            static let tipMeals = String(localized: "Feed meals in the crate so it becomes a positive place", table: table)
            static let tipTired = String(localized: "Put them in when tired — after play or a walk works best", table: table)
            static let tipStayClose = String(localized: "Stay nearby when they whimper. They're learning, not suffering", table: table)
            static let tipNoCrying = String(localized: "If your dog screams in the crate, that means you're using it too little, not that it doesn't work. Put them in more often — it gets calmer with use.", table: table)
            static let tipShortFirst = String(localized: "Start with short periods and gradually increase", table: table)

            // Encouragement
            static let encouragement = String(localized: "Most puppies love their crate within a week. It becomes their happy place.", table: table)

            // Mastery
            static let markMastered = String(localized: "Mark as Mastered", table: table)
            static let markMasteredDescription = String(localized: "Your pup is comfortable sleeping in the crate whenever needed", table: table)
            static let mastered = String(localized: "Mastered", table: table)
            static let masteredCelebration = String(localized: "Crate training complete!", table: table)
            static let masteredDescription = String(localized: "Your pup is crate trained. They can sleep comfortably in the crate whenever needed.", table: table)
            static let reactivateTracking = String(localized: "Having issues? Reactivate tracking", table: table)
            static func masteredOn(date: String) -> String {
                String(localized: "Mastered on \(date)", table: table)
            }

            // Bulk edit
            static let bulkEditTitle = String(localized: "Edit Nap Locations", table: table)
            static let bulkEditButton = String(localized: "Edit nap locations", table: table)
            static let bulkEditExplanation = String(localized: "Select naps to update their location. This helps track crate training progress.", table: table)
            static let bulkEditEmptyDescription = String(localized: "Log some naps first, then you can set their locations here.", table: table)
            static let bulkEditFooter = String(localized: "Tap naps to select them, then apply the location.", table: table)
            static let setLocationTo = String(localized: "Set location to", table: table)
            static let napsWithoutLocation = String(localized: "Naps without location", table: table)
            static let napsWithLocation = String(localized: "Naps with location", table: table)
            static let noLocationSet = String(localized: "No location set", table: table)
            static func applyToSelected(_ count: Int) -> String {
                if count == 1 {
                    return String(localized: "Apply to 1 nap", table: table)
                } else {
                    return String(localized: "Apply to \(count) naps", table: table)
                }
            }
        }

        // Skill content - names, descriptions, done criteria, how-to steps, tips
        enum Skills {
            // MARK: - Clicker
            static let clickerName = String(localized: "Clicker", table: table)
            static let clickerDescription = String(localized: "The clicker is a marker signal that tells your puppy exactly when they did something right. It bridges the gap between the behavior and the reward. You can use a clicker OR a marker word like 'yes' — but pick one, not both.", table: table)
            static let clickerDoneWhen = String(localized: "Test it: let your puppy wander to another room, then click. If they come running back expecting a treat, the clicker is properly conditioned.", table: table)
            static let clickerHowTo1 = String(localized: "Muffle the clicker initially — put it under a cushion, wrap it in a scarf, or hold it in your pocket. The sound can overwhelm some puppies.", table: table)
            static let clickerHowTo2 = String(localized: "Click once, then give a treat within 1-2 seconds. Click → treat, click → treat. Build the association.", table: table)
            static let clickerHowTo3 = String(localized: "Repeat 10-15 times per session. Your puppy should start perking up and looking expectant when they hear the click.", table: table)
            static let clickerHowTo4 = String(localized: "Gradually expose your puppy to the full volume of the clicker over several sessions as they become comfortable.", table: table)
            static let clickerHowTo5 = String(localized: "Test: let your puppy wander away, then click. If they come running back expecting food, the clicker is conditioned. This is a one-time test — don't use the clicker as a recall tool.", table: table)
            static let clickerTip1 = String(localized: "Every single click MUST be followed by a treat. Clicking without treating destroys the association you've built.", table: table)
            static let clickerTip2 = String(localized: "Use your puppy's regular kibble for training — save special treats exclusively for recall training.", table: table)
            static let clickerTip3 = String(localized: "The clicker is not permanent. Once a behavior is solid across many environments, you can phase it out. But variable reward continues for life.", table: table)
            static let clickerTip4 = String(localized: "If you click by accident, still give a treat — maintaining the association is more important than perfect timing.", table: table)
            static let clickerMistake1 = String(localized: "Clicking without giving a treat — this breaks the entire system", table: table)
            static let clickerMistake2 = String(localized: "Using the clicker to get attention or call your dog — it's only for marking correct behavior", table: table)
            static let clickerMistake3 = String(localized: "Mixing clicker and marker word — choose one method and stick with it", table: table)

            // MARK: - Name Recognition
            static let nameRecognitionName = String(localized: "Name Recognition", table: table)
            static let nameRecognitionDescription = String(localized: "A simple skill to get your puppy's attention. Note: your puppy's name gets used constantly in daily life ('Good dog, Max!', 'No, Max!', 'Max, stop that!'), so it becomes background noise over time. That's perfectly fine — the name is for casual attention, not emergencies. For reliable recall, you'll use a special 'magic word' later.", table: table)
            static let nameRecognitionDoneWhen = String(localized: "Your puppy looks at you when you say their name in a calm environment. Don't expect perfection — this is a 'nice to have' attention-getter, not a critical command.", table: table)
            static let nameRecognitionHowTo1 = String(localized: "Wait until your puppy looks away from you", table: table)
            static let nameRecognitionHowTo2 = String(localized: "Say their name once in a happy, upbeat voice", table: table)
            static let nameRecognitionHowTo3 = String(localized: "When they look at you, click and treat. That's it!", table: table)
            static let nameRecognitionHowTo4 = String(localized: "Repeat a few times, but keep sessions very short (1-2 minutes)", table: table)
            static let nameRecognitionHowTo5 = String(localized: "Practice casually throughout the day — no need to drill this one", table: table)
            static let nameRecognitionTip1 = String(localized: "Don't worry about perfecting this — name recognition naturally fades as the name becomes 'just a word' they hear all day", table: table)
            static let nameRecognitionTip2 = String(localized: "Only say the name once. If they don't respond, just try later — no big deal", table: table)
            static let nameRecognitionTip3 = String(localized: "For emergencies and reliable recall, you'll train a separate 'magic word' that stays powerful", table: table)
            static let nameRecognitionTip4 = String(localized: "Keep it fun and casual — this is an easy win to build training confidence", table: table)

            // MARK: - Luring
            static let luringName = String(localized: "Luring", table: table)
            static let luringDescription = String(localized: "Use a treat to guide your puppy into positions. This technique is used to teach many other commands.", table: table)
            static let luringDoneWhen = String(localized: "Your puppy follows the treat smoothly in any direction without jumping or grabbing.", table: table)
            static let luringHowTo1 = String(localized: "Hold a treat between your thumb and fingers", table: table)
            static let luringHowTo2 = String(localized: "Let your puppy sniff the treat but not eat it", table: table)
            static let luringHowTo3 = String(localized: "Move the treat slowly - your puppy's nose should follow", table: table)
            static let luringHowTo4 = String(localized: "Practice moving in different directions", table: table)
            static let luringHowTo5 = String(localized: "Reward when they follow the lure smoothly", table: table)
            static let luringTip1 = String(localized: "Move slowly and smoothly", table: table)
            static let luringTip2 = String(localized: "Keep the treat close to their nose", table: table)
            static let luringTip3 = String(localized: "If they lose interest, use higher value treats", table: table)
            static let luringTip4 = String(localized: "Eventually fade the lure into a hand signal", table: table)
            static let luringMistake1 = String(localized: "Moving the lure too fast (puppy can't follow)", table: table)
            static let luringMistake2 = String(localized: "Holding the treat too far from the nose (puppy jumps)", table: table)

            // MARK: - Touch & Handling
            static let handlingName = String(localized: "Touch & Handling", table: table)
            static let handlingDescription = String(localized: "Teach your puppy to touch their nose to your palm (targeting) and to stay relaxed when being touched everywhere. Essential for positioning, recall, vet visits, and grooming.", table: table)
            static let handlingDoneWhen = String(localized: "Your puppy touches their nose to your palm on cue and stays relaxed when you touch their ears, paws, mouth, and tail.", table: table)
            static let handlingHowTo1 = String(localized: "Present a flat palm near your puppy's nose - most will naturally investigate", table: table)
            static let handlingHowTo2 = String(localized: "Click and treat when their nose touches your palm", table: table)
            static let handlingHowTo3 = String(localized: "Add the cue 'touch' once reliable, then practice at different heights and distances", table: table)
            static let handlingHowTo4 = String(localized: "For body handling: start when calm, gently touch ears, paws, tail, mouth while giving treats", table: table)
            static let handlingHowTo5 = String(localized: "Gradually increase duration and pressure of handling - make it part of daily routine", table: table)
            static let handlingTip1 = String(localized: "Don't push your hand into their face - let them come to you", table: table)
            static let handlingTip2 = String(localized: "Rub a treat on your palm if they need encouragement for nose targeting", table: table)
            static let handlingTip3 = String(localized: "Touch targeting is a great alternative to 'come' for recall", table: table)
            static let handlingTip4 = String(localized: "Stop handling if puppy shows stress signals - go slower next time", table: table)

            // MARK: - Collar & Leash
            static let collarLeashName = String(localized: "Collar & Leash", table: table)
            static let collarLeashDescription = String(localized: "Get your puppy comfortable wearing a collar and being on a leash. Foundation for all outdoor training.", table: table)
            static let collarLeashDoneWhen = String(localized: "Your puppy ignores the collar and doesn't panic when leash is attached or lifted.", table: table)
            static let collarLeashHowTo1 = String(localized: "Let puppy sniff the collar first", table: table)
            static let collarLeashHowTo2 = String(localized: "Put collar on during positive moments (meals, play)", table: table)
            static let collarLeashHowTo3 = String(localized: "Start with short periods", table: table)
            static let collarLeashHowTo4 = String(localized: "Attach leash and let them drag it supervised", table: table)
            static let collarLeashHowTo5 = String(localized: "Pick up leash and follow puppy around", table: table)
            static let collarLeashTip1 = String(localized: "Check collar fit - two fingers should fit underneath", table: table)
            static let collarLeashTip2 = String(localized: "Never leave leash on unsupervised", table: table)
            static let collarLeashTip3 = String(localized: "If puppy freezes, lure them forward with treats", table: table)
            static let collarLeashTip4 = String(localized: "Practice inside before going outside", table: table)

            // MARK: - Sit
            static let sitName = String(localized: "Sit", table: table)
            static let sitDescription = String(localized: "Trained with classical conditioning (luring). No verbal commands during training — work only with hand signals. The hand signal is introduced immediately, becoming the cue from the start.", table: table)
            static let sitDoneWhen = String(localized: "Your puppy sits on hand signal (hand rises beside your face, palm forward) from any distance. The silhouette is visible even in a winter coat.", table: table)
            // Phase 1: Lure to Position
            static let sitHowTo1 = String(localized: "Treat on nose. Move it slowly up and slightly back, toward the EARS (not toward the tail, or the dog walks backward). Click the moment they start shifting weight backward.", table: table)
            static let sitHowTo2 = String(localized: "Hand slightly above the nose (~10-15 cm). No longer touching the nose. The dog follows the visual of the hand going up, sits. Click and treat.", table: table)
            static let sitHowTo3 = String(localized: "Hand starts at your side, sweeps up to a 90° angle (elbow to armpit). This becomes the final hand signal. No longer going to the dog's nose — it simply rises beside your face.", table: table)
            // Phase 2: Reinforce
            static let sitHowTo4 = String(localized: "Between sessions, watch for natural sits. Mark and reward immediately. This reinforces the behavior throughout the day.", table: table)
            static let sitHowTo5 = String(localized: "Continue until reliable with the hand signal (8 out of 10 times). Only move to the next step when effortless — no ambiguity, no hesitation.", table: table)
            // Phase 3: Add Verbal Cue (only after hand signal is reliable)
            static let sitHowTo6 = String(localized: "Add verbal cue LAST, only after the hand signal works in multiple environments. Say 'sit' as the dog is about to sit (during the action), not before.", table: table)
            static let sitHowTo7 = String(localized: "Test: say 'sit' when the dog is distracted. If they sit → it's trained. If not → go back to hand signal practice.", table: table)
            static let sitHowTo8 = String(localized: "Final hand signal: hand rises beside your face, palm forward. This is visible from any distance, even with a coat on. Children naturally throw hands up — dogs will sit for that gesture.", table: table)
            // Phase 4: Proof with 3 D's
            static let sitHowTo9 = String(localized: "Build Duration: Start with 1 second, then 2, then 5. Reward multiple times while they hold the sit - don't just reward when they get up.", table: table)
            static let sitHowTo10 = String(localized: "Add Distance: Take one step back while they sit. Return and reward. Gradually increase to several meters, always returning to reward.", table: table)
            static let sitHowTo11 = String(localized: "Practice in new locations: kitchen, garden, front door, quiet street, park. Each new place is like starting over - use the lure again if needed, then fade it.", table: table)
            // Tips by phase
            static let sitTip1 = String(localized: "If your puppy backs up instead of sitting, practice with their back against a wall or in a corner - the only option becomes sitting down", table: table)
            static let sitTip2 = String(localized: "Move the treat slowly and keep it close to their nose. Too fast or too high causes jumping and frustration", table: table)
            static let sitTip3 = String(localized: "Combine luring (during practice sessions) with capturing (throughout the day) for faster, more reliable learning", table: table)
            static let sitTip4 = String(localized: "Say the word only ONCE. Not 'sit, sit, SIT!' - that teaches them to wait until you sound angry. One cue, wait, then help with gesture if needed", table: table)
            static let sitTip5 = String(localized: "Work on only one D at a time. More distractions? Keep duration short and stay close. More distance? Less distraction and shorter duration", table: table)
            static let sitTip6 = String(localized: "Use sit in daily life: before meals, at the door, before leashing, at curbs, before treats. This makes sit their default way to ask for things", table: table)
            // Mistakes
            static let sitMistake1 = String(localized: "Holding the treat too high (causes jumping) or moving too fast (causes frustration)", table: table)
            static let sitMistake2 = String(localized: "Saying 'sit' before they know the behavior - the word becomes meaningless", table: table)
            static let sitMistake3 = String(localized: "Pushing their bottom down instead of luring - this creates resistance, not learning", table: table)
            static let sitMistake4 = String(localized: "Training for too long - puppies have 2-3 minute attention spans. Keep sessions short and fun", table: table)

            // MARK: - Watch Me
            static let watchMeName = String(localized: "Watch Me", table: table)
            static let watchMeDescription = String(localized: "Trained purely with operant conditioning (passive). You do nothing except observe and click for eye contact. Because your puppy figures it out themselves, this creates deep, lasting learning.", table: table)
            static let watchMeDoneWhen = String(localized: "When your puppy is sniffing the ground and you say 'look', they immediately look up at your face. Test this — if they respond, it's trained.", table: table)
            static let watchMeHowTo1 = String(localized: "Get on your puppy's level. Sit on the floor. For small dogs, put them on the couch while you sit on the floor so you're at eye level.", table: table)
            static let watchMeHowTo2 = String(localized: "Treats in right hand, clicker in left. Both hands behind your back. Say nothing. Don't make sounds. Don't move your hands. Don't lure. Just wait.", table: table)
            static let watchMeHowTo3 = String(localized: "The instant your puppy makes eye contact — click and treat. Even a split-second glance at your face counts.", table: table)
            static let watchMeHowTo4 = String(localized: "Throw the treat away so your puppy has to move to get it, then naturally resets. This prevents learning attention only while sitting.", table: table)
            static let watchMeHowTo5 = String(localized: "Repeat. They'll look at your hands, look around, sniff — and eventually glance at your face again. Click that moment.", table: table)
            static let watchMeHowTo6 = String(localized: "Gradually increase duration. Once reliable, wait for 1 second of eye contact before clicking. Then 2. Then 3.", table: table)
            static let watchMeHowTo7 = String(localized: "Change your position. Floor → chair → standing. At each stage, your puppy needs to find your face at a new height.", table: table)
            static let watchMeHowTo8 = String(localized: "Arms out to the sides. Your puppy must choose: look at the hands (where treats come from) or look at your face. Reward only face contact.", table: table)
            static let watchMeHowTo9 = String(localized: "Add the verbal cue only AFTER reliable eye contact in multiple environments. Say 'look' during the action toward your face, not while looking elsewhere.", table: table)
            static let watchMeHowTo10 = String(localized: "Test: when your puppy is sniffing and not looking, say the cue. If they look up → trained. If not → back to the previous step.", table: table)
            static let watchMeTip1 = String(localized: "You are passive. Hands behind your back. No luring, no pushing, no verbal cues. You simply wait and reward eye contact.", table: table)
            static let watchMeTip2 = String(localized: "Train in a low-stimulus environment. Living room, no distractions. Your puppy needs to focus one-on-one.", table: table)
            static let watchMeTip3 = String(localized: "If your puppy keeps going behind you, sit with your back against a wall or couch.", table: table)
            static let watchMeTip4 = String(localized: "Don't worry about sit vs stand vs down — position doesn't matter, only the eye contact.", table: table)
            static let watchMeMistake1 = String(localized: "Holding a treat near your face — this becomes a bribe, not genuine learned behavior", table: table)
            static let watchMeMistake2 = String(localized: "Making sounds or calling to get attention — stay completely passive", table: table)
            static let watchMeMistake3 = String(localized: "Adding the verbal cue before the behavior is reliable in multiple environments", table: table)

            // MARK: - Touch
            static let touchName = String(localized: "Touch", table: table)
            static let touchDescription = String(localized: "Puppy learns to touch their nose to your palm. Useful for positioning and recall.", table: table)
            static let touchDoneWhen = String(localized: "Your puppy touches their nose to your palm on command from 1 meter away.", table: table)
            static let touchHowTo1 = String(localized: "Present flat palm near puppy's nose", table: table)
            static let touchHowTo2 = String(localized: "Most puppies will naturally investigate", table: table)
            static let touchHowTo3 = String(localized: "Click and treat when nose touches palm", table: table)
            static let touchHowTo4 = String(localized: "Add the cue 'touch'", table: table)
            static let touchHowTo5 = String(localized: "Practice at different heights and distances", table: table)
            static let touchTip1 = String(localized: "Don't push your hand into their face", table: table)
            static let touchTip2 = String(localized: "Rub treat on palm if they need encouragement", table: table)
            static let touchTip3 = String(localized: "Great alternative to 'come' for recall", table: table)
            static let touchTip4 = String(localized: "Can be used to guide puppy into positions", table: table)

            // MARK: - Loose Leash Walking
            static let looseLeashName = String(localized: "Loose Leash Walking", table: table)
            static let looseLeashDescription = String(localized: "The goal: your dog walks beside you, looking up at your face, on a loose leash. This is classical conditioning — you actively guide with food. The final test: 10 meters with eye contact and hand behind your back.", table: table)
            static let looseLeashDoneWhen = String(localized: "Your puppy walks 10 straight meters beside you, looking at your face with the hand behind your back, before you need to reward.", table: table)
            // Phase 1: Hand on nose, walking backward
            static let looseLeashHowTo1 = String(localized: "Hold your hand low enough that your puppy doesn't need to jump — even very low for small/young dogs. Keep about 30 cm from your knee so they walk beside you with space, not against your leg.", table: table)
            static let looseLeashHowTo2 = String(localized: "Start walking BACKWARD with the treat on their nose. Click → stop → give treat → wait until they finish eating → then walk again. Keep your hand loaded with treats.", table: table)
            static let looseLeashHowTo3 = String(localized: "Short sessions: 5 minutes in the living room, then stop. Multiple short sessions throughout the day work better than one long one.", table: table)
            // Phase 2: Hand up high
            static let looseLeashHowTo4 = String(localized: "Pull your hand straight out to the side and UP — level with your face, not hip height. The dog must look up toward your face, not follow a low hand.", table: table)
            static let looseLeashHowTo5 = String(localized: "After each click and treat, restart from step 1: walk 2-3 steps with hand low on nose, then bring it up high again. Sometimes reward at step 1, sometimes skip to the high position.", table: table)
            // Phase 3: Rotation and removing the hand
            static let looseLeashHowTo6 = String(localized: "The rotation: with arm stretched to the right, rotate your LEFT shoulder inward. Your hand stays in exactly the same place — the dog doesn't notice any change. Practice: put your hand against a wall (hand can't move), then rotate your body.", table: table)
            static let looseLeashHowTo7 = String(localized: "Move your hand across your chest (right shoulder to left shoulder) then behind your back. This removes the hand from sight so your dog looks at your FACE instead.", table: table)
            // Phase 4: Eye contact while walking
            static let looseLeashHowTo8 = String(localized: "Once the hand is behind your back, click and reward for eye contact. You should be able to walk at least 10 straight meters with your dog looking at your face before moving to forward starts.", table: table)
            // Phase 5: Forward start
            static let looseLeashHowTo9 = String(localized: "Instead of starting by walking backward, step forward with your LEFT leg (closest to the dog). Sweep the treat hand toward their nose, bring it to your shoulder, then behind your back.", table: table)
            static let looseLeashHowTo10 = String(localized: "Progression: master indoors first, then the doorstep, then quiet streets, then busier environments. Stop training indoors once it works there — the goal is outdoor obedience.", table: table)
            static let looseLeashTip1 = String(localized: "Stand STILL when you reward. Click → stop → treat → wait → walk again. Don't keep reaching into your pocket between reps — keep your hand loaded.", table: table)
            static let looseLeashTip2 = String(localized: "If your dog jumps, your hand is too high. If they lose interest, lower the hand and make it easier.", table: table)
            static let looseLeashTip3 = String(localized: "Don't train during the whole walk. Dedicate training to short, focused sessions. Walks are for experiencing the world.", table: table)
            static let looseLeashTip4 = String(localized: "Use a standard 1.8-2m leash. Never use retractable leashes — they teach pulling, can drop and scare your puppy, and offer zero control.", table: table)
            static let looseLeashMistake1 = String(localized: "Using a retractable leash — teaches pulling and is dangerous", table: table)
            static let looseLeashMistake2 = String(localized: "Hand too low (dog doesn't look up) or too high (dog jumps)", table: table)
            static let looseLeashMistake3 = String(localized: "Trying to treat while walking — always stop to treat so the pattern is clear", table: table)

            // MARK: - Down
            static let downName = String(localized: "Down", table: table)
            static let downDescription = String(localized: "More complex than sit. Trained with classical conditioning (luring), starting from a sit. Uses the tether technique to teach that lying down — not nose-pushing — earns the reward.", table: table)
            static let downDoneWhen = String(localized: "Your puppy lies down on a hand signal (sweep from navel sideways) from a standing position. The signal is a clear silhouette visible even in a winter coat.", table: table)
            static let downHowTo1 = String(localized: "Start from sit. Bring the treat to the nose, then slowly straight down toward the ground, ending between the front paws. Keep the line straight down — if your hand drifts forward, the dog stands up.", table: table)
            static let downHowTo2 = String(localized: "Don't let your puppy push your hand away. Maintain gentle contact. They'll try to lick and dig at your fingers — hold steady. Click for any downward movement: nose dipping, an elbow bending, weight shifting.", table: table)
            static let downHowTo3 = String(localized: "Tether technique: put your foot on the leash so your puppy can't reach your hand. Lure toward the ground but keep your hand just out of reach (~5 cm gap). They'll eventually slide into a down to get closer.", table: table)
            static let downHowTo4 = String(localized: "This teaches that lying down earns the reward — not the nose-pushing and licking. Only progress when the tethered down is smooth.", table: table)
            static let downHowTo5 = String(localized: "Build height gradually: ankle → knee → hip → waist. At each level, your puppy must think 'that gesture means go down.' Be patient at each transition.", table: table)
            static let downHowTo6 = String(localized: "Final signal: from waist height, sweep your hand sideways (not pulled behind your body). This creates a clear silhouette visible from any distance.", table: table)
            static let downHowTo7 = String(localized: "Build duration: after the down, move your hand down to ankle quickly, then back up. Your puppy thinks the hand is still near and stays put. Return route = same as exit route (sneak hand down behind legs).", table: table)
            static let downTip1 = String(localized: "Dachshunds: their neck is longer than their legs — they can look at your hand at ground level while standing. Every increment is tiny. More patience needed.", table: table)
            static let downTip2 = String(localized: "French Bulldogs: limited neck flexibility. They may stick their butt up as they dive their head down. More patience needed.", table: table)
            static let downTip3 = String(localized: "If luring doesn't work, switch to operant/shaping: click for any movement toward the ground — nose dipping, one elbow bending, looking down. No pushing.", table: table)
            static let downTip4 = String(localized: "To keep your dog in a down (e.g., at a restaurant): wrap the leash under your foot so they physically can't stand.", table: table)
            static let downMistake1 = String(localized: "Moving your hand forward (away from the dog) instead of straight down — they'll stand up to follow", table: table)
            static let downMistake2 = String(localized: "Not using the tether — the puppy learns that pushing/licking works instead of lying down", table: table)
            static let downMistake3 = String(localized: "Physically pushing the dog into position — this creates resistance, not learning", table: table)

            // MARK: - Come (Magic Word Recall)
            static let comeName = String(localized: "Magic Recall", table: table)
            static let comeDescription = String(localized: "A bombproof recall that could save your dog's life. Here's the secret: don't use their name or 'come' — those words are worn out from daily overuse ('Come here!', 'Max, come!', 'Come on, let's go!'). Instead, you'll choose a 'magic word' that you ONLY use for emergency recall, paired with a high-value treat that makes coming to you irresistible.", table: table)
            static let comeDoneWhen = String(localized: "Your dog drops everything and sprints to you when they hear the magic word, even with major distractions.", table: table)
            // Phase 1: Choose Your Magic Word
            static let comeHowTo1 = String(localized: "Pick a word that sounds happy and exciting but isn't used in daily conversation. For non-English speakers, 'Happy!' works great. Or invent a fun word like 'Bingo!', 'Yippee!', or 'Presto!' — something you'll enjoy saying with enthusiasm.", table: table)
            static let comeHowTo2 = String(localized: "The word should be short (1-2 syllables), easy to say with excitement, and completely unique to recall. Never use it casually. This word = jackpot treat, always.", table: table)
            static let comeHowTo3 = String(localized: "Choose your high-value treat: chicken, cheese, hot dog, or whatever makes your dog go absolutely crazy. This treat is ONLY for magic word training — never for anything else.", table: table)
            // Phase 2: Build the Association
            static let comeHowTo4 = String(localized: "Start indoors with no distractions. Say your magic word excitedly, then immediately give the jackpot treat. Your dog doesn't need to do anything yet — just build the association: magic word = amazing treat.", table: table)
            static let comeHowTo5 = String(localized: "Repeat 5-10 times per session. Within a few sessions, your dog should perk up and look excited the moment they hear the magic word.", table: table)
            static let comeHowTo6 = String(localized: "Test the association: say the magic word when your dog is slightly distracted. If they whip around excitedly, you're ready for the next phase.", table: table)
            // Phase 3: Partner Exercise
            static let comeHowTo7 = String(localized: "Have a partner hold your dog gently (or have them on a long line). Sit down on the floor about 2-3 meters away, spread your arms wide, and call the magic word with genuine excitement.", table: table)
            static let comeHowTo8 = String(localized: "When your dog runs to you, make it a HUGE celebration. Jackpot treats, praise, petting — the works. This should feel like winning the lottery to them.", table: table)
            static let comeHowTo9 = String(localized: "Gradually increase distance. When reliable, progress to standing (but still with open arms and excitement). Eventually, you can be more casual, but always reward generously.", table: table)
            // Phase 4: Proof and Progress
            static let comeHowTo10 = String(localized: "Once reliable, add a sit after they arrive. One treat for coming, one treat for sitting. This prevents the 'drive-by' where your dog runs past you.", table: table)
            static let comeHowTo11 = String(localized: "Add distractions gradually. Put a snuffle mat on the ground, let your dog engage with it, then call the magic word. Click when they turn around → reward immediately. The magic word must cut through anything.", table: table)
            static let comeHowTo12 = String(localized: "Keep the magic word special: use it sparingly (a few times per week), always reward with high-value treats, and never use it for anything unpleasant. This word stays powerful for life.", table: table)
            // Tips by phase
            static let comeTip1 = String(localized: "The magic word works because it's never 'polluted' by everyday use. Your dog's name and 'come' have been said thousands of times with no reward — they've learned to tune them out", table: table)
            static let comeTip2 = String(localized: "Examples of good magic words: 'Bingo!', 'Yippee!', 'Presto!', 'Party!', 'Jackpot!', 'Happy!' (great for non-native English speakers)", table: table)
            static let comeTip3 = String(localized: "Sitting down with open arms is irresistible to dogs — it looks welcoming and non-threatening. This body language makes them want to run to you", table: table)
            static let comeTip4 = String(localized: "Never practice off-leash until it's 100% reliable on the long line — one failed recall weakens the magic", table: table)
            static let comeTip5 = String(localized: "If recall fails, don't repeat the word. Walk closer, show the treat, and try again later with less distraction. Protect the magic word's power", table: table)
            static let comeTip6 = String(localized: "Reserve the magic word for when you really need it. Use your dog's name or 'come here' for casual situations — save the magic for emergencies", table: table)
            // Mistakes
            static let comeMistake1 = String(localized: "Using the magic word too often or for casual situations — this dilutes its power", table: table)
            static let comeMistake2 = String(localized: "Using the magic word then giving a low-value reward — always use the jackpot treat", table: table)
            static let comeMistake3 = String(localized: "Calling for something unpleasant (bath, nail trim, crate) — go get them instead", table: table)
            static let comeMistake4 = String(localized: "Practicing off-leash before rock-solid reliability — one successful escape teaches them ignoring works", table: table)

            // MARK: - Wait
            static let waitName = String(localized: "Wait", table: table)
            static let waitDescription = String(localized: "Short-term boundary training — puppy pauses at doors and before meals. The goal is that they wait naturally, not that they're commanded into position.", table: table)
            static let waitDoneWhen = String(localized: "Your puppy waits at doors without trying to rush through, and waits calmly while you lower the food bowl.", table: table)
            // Door manners
            static let waitHowTo1 = String(localized: "Door training: open the door. If your puppy tries to rush through — close it immediately. No verbal cue needed yet.", table: table)
            static let waitHowTo2 = String(localized: "Open again. Dog tries again → close. Repeat until your puppy hesitates and looks at you instead of bolting.", table: table)
            static let waitHowTo3 = String(localized: "This is practical safety training — you don't want a dog bolting out the front door into traffic.", table: table)
            // Food bowl manners
            static let waitHowTo4 = String(localized: "Food bowl training: put a few kibbles in the bowl, lower it toward the ground. If puppy dives → pull the bowl up. Wait 20 seconds.", table: table)
            static let waitHowTo5 = String(localized: "Lower again — they'll wait slightly longer this time. Repeat until they look at you instead of diving. Then give a release word ('free') and set the bowl down.", table: table)
            static let waitTip1 = String(localized: "No verbal command needed for door/bowl training. The consequence (door closes, bowl rises) teaches the boundary.", table: table)
            static let waitTip2 = String(localized: "For hyper dogs at mealtime: put them on leash. If they bark → time-out (20 seconds). Bring back, try again. Train during evening meals first.", table: table)
            static let waitTip3 = String(localized: "Release with 'free' or 'okay' — this signals 'you can go now'.", table: table)
            static let waitTip4 = String(localized: "Once the behavior is reliable, you can add the verbal cue 'wait' to formalize it.", table: table)

            // MARK: - Place
            static let placeName = String(localized: "Place", table: table)
            static let placeDescription = String(localized: "Puppy goes to their bed or mat and stays there. Great for settling at home.", table: table)
            static let placeDoneWhen = String(localized: "Your puppy goes to their bed and lies down for 2 minutes.", table: table)
            static let placeHowTo1 = String(localized: "Lure puppy onto their bed or mat", table: table)
            static let placeHowTo2 = String(localized: "Ask for a down on the mat", table: table)
            static let placeHowTo3 = String(localized: "Reward for staying on the mat", table: table)
            static let placeHowTo4 = String(localized: "Add the cue 'place' or 'bed'", table: table)
            static let placeHowTo5 = String(localized: "Gradually add duration and distance", table: table)
            static let placeTip1 = String(localized: "Use a portable mat to transfer this skill anywhere", table: table)
            static let placeTip2 = String(localized: "Great for when guests arrive", table: table)
            static let placeTip3 = String(localized: "Build duration very slowly", table: table)
            static let placeTip4 = String(localized: "Practice during meals and TV time", table: table)

            // MARK: - Stay
            static let stayName = String(localized: "Stay", table: table)
            static let stayDescription = String(localized: "Long-duration stay that teaches independence. The 'Passive Stay' method: you give NO commands — the dog self-discovers that settling earns rewards.", table: table)
            static let stayDoneWhen = String(localized: "Your puppy stays calmly for several minutes while you walk away, and understands that you always come back.", table: table)
            // Passive Stay method
            static let stayHowTo1 = String(localized: "Tie your dog to something sturdy (table leg, radiator) with a SHORT leash — just enough to stand, sit, and lie down. No commands.", table: table)
            static let stayHowTo2 = String(localized: "Walk 3-5 meters away, with your BACK to the dog. Watch via a mirror or phone camera.", table: table)
            static let stayHowTo3 = String(localized: "The moment they sit or lie down → click → turn around → walk back → reward. Toss a treat behind them so they can sniff briefly.", table: table)
            static let stayHowTo4 = String(localized: "Repeat 3 times per session, same location. Do 3-4 sessions per day with breaks. No words during the exercise.", table: table)
            static let stayHowTo5 = String(localized: "Short leash = less room to sniff = runs out of things to do faster = settles sooner. Don't pace back and forth (creates nervousness) — just stand still.", table: table)
            static let stayTip1 = String(localized: "Only AFTER the dog reliably understands the pattern do you add a 'stay' cue. First master it at one location, then introduce a second.", table: table)
            static let stayTip2 = String(localized: "Real-world use: tie dog to a tree at a friend's house, to a post outside a shop. They learn you always come back — reducing separation anxiety.", table: table)
            static let stayTip3 = String(localized: "If they break, simply reset without punishment. The consequence is: you don't come back and reward yet.", table: table)
            static let stayTip4 = String(localized: "This teaches general independence — being separate from you is normal and safe.", table: table)
        }
    }
}
