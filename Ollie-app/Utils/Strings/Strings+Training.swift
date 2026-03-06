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
        static let refresherNeeded = String(localized: "Refresher needed", table: table)
        static let mainFocus = String(localized: "Main focus", table: table)
        static let dueForReview = String(localized: "Due for review", table: table)
        static let practiceInNewContext = String(localized: "Practice in new location", table: table)
        static let warmUp = String(localized: "Warm-up", table: table)

        // Regression messages
        static let skillNeedsRefresher = String(localized: "This skill needs a refresher", table: table)
        static let priorityShifted = String(localized: "Priority shifted to maintenance", table: table)
        static let backOnTrack = String(localized: "Back on track!", table: table)

        // Session plan
        static let todaysTraining = String(localized: "Today's Training", table: table)
        static let maintenanceReview = String(localized: "Maintenance review", table: table)
        static let easyFinish = String(localized: "Easy finish", table: table)
        static let easyWinToStart = String(localized: "Easy win to start", table: table)
        static let primaryFocusSubtitle = String(localized: "New skills to learn", table: table)
        static let regressionFocusSubtitle = String(localized: "These skills need attention", table: table)
        static let maintenanceSubtitle = String(localized: "Quick refresher reps", table: table)
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
                static let subtitle = String(localized: "Learning through self-discovery", table: table)
                static let explanation = String(localized: "In operant conditioning, you stay passive while your puppy self-discovers the desired behavior. When they do something right, you mark it with a click and reward. This creates deep, lasting learning because the puppy figured it out themselves.", table: table)
                static let point1 = String(localized: "You stay quiet and still — no luring, no gestures", table: table)
                static let point2 = String(localized: "Wait patiently for the behavior to happen naturally", table: table)
                static let point3 = String(localized: "Click the exact moment you see the correct behavior", table: table)
                static let point4 = String(localized: "Creates stronger, more reliable learning than luring", table: table)
                static let exampleTitle = String(localized: "Teaching \"Watch Me\"", table: table)
                static let exampleText = String(localized: "Sit quietly with your hands behind your back. Don't call your puppy or make any sounds. Just wait. Eventually, they'll look at your face out of curiosity. The instant they make eye contact — click and treat! After several repetitions, they'll start offering eye contact more and more.", table: table)
            }

            // Classical Conditioning
            enum Classical {
                static let title = String(localized: "Classical Conditioning", table: table)
                static let subtitle = String(localized: "Learning through guidance", table: table)
                static let explanation = String(localized: "In classical conditioning, you actively guide your puppy into position using a food lure. This produces faster initial learning, making it great for physical positions like sit and down. The puppy follows the treat, and you reward when they reach the correct position.", table: table)
                static let point1 = String(localized: "Hold a treat close to your puppy's nose", table: table)
                static let point2 = String(localized: "Move the treat slowly to guide them into position", table: table)
                static let point3 = String(localized: "Click when they reach the desired position", table: table)
                static let point4 = String(localized: "Gradually fade the lure into a hand signal", table: table)
                static let exampleTitle = String(localized: "Teaching \"Sit\"", table: table)
                static let exampleText = String(localized: "Hold a treat at your puppy's nose level. Slowly move it toward their EARS (not over their head). Their nose follows up, and their bottom goes down naturally. Click the moment their bottom touches the floor, then give the treat.", table: table)
            }

            // Click Timing
            enum Timing {
                static let title = String(localized: "Click Timing", table: table)
                static let subtitle = String(localized: "The moment that matters most", table: table)
                static let explanation = String(localized: "The click is a marker signal that tells your puppy exactly when they did something right. It bridges the gap between the behavior and the reward. Timing is everything — you must click at the precise moment the correct behavior happens, not a second before or after.", table: table)
                static let point1 = String(localized: "Click at the EXACT moment of correct behavior", table: table)
                static let point2 = String(localized: "Always follow a click with a treat within 1-2 seconds", table: table)
                static let point3 = String(localized: "Never click without treating — this breaks the association", table: table)
                static let point4 = String(localized: "If you click by accident, still give a treat", table: table)
                static let exampleTitle = String(localized: "Marking \"Sit\"", table: table)
                static let exampleText = String(localized: "As your puppy's bottom touches the floor, you click THAT instant — not when they're halfway down, not when they've been sitting for a second. The click captures the exact moment. Then you have 1-2 seconds to deliver the treat. The click buys you that time.", table: table)
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
            static let startTraining = String(localized: "Start Training", table: table)
            static let whatYouWillLearn = String(localized: "What you'll learn", table: table)
            static let goalTitle = String(localized: "Goal", table: table)

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

            // Come (Recall) phases
            static let comeFoundationName = String(localized: "Foundation", table: table)
            static let comeFoundationSubtitle = String(localized: "Build enthusiasm for running to you", table: table)
            static let comeFrontPositionName = String(localized: "Front Position", table: table)
            static let comeFrontPositionSubtitle = String(localized: "Coming directly to you and allowing collar touch", table: table)
            static let comeBuildDistanceName = String(localized: "Build Distance", table: table)
            static let comeBuildDistanceSubtitle = String(localized: "Practice with increasing distance on a long line", table: table)
            static let comeProofDistractionsName = String(localized: "Proof with Distractions", table: table)
            static let comeProofDistractionsSubtitle = String(localized: "Reliable recall in challenging environments", table: table)

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
                String(localized: "Master \(skills) first", table: table)
            }
            static let preparationRequired = String(localized: "Complete preparation first", table: table)
            static let viewRules = String(localized: "View Training Rules", table: table)
            static let allSkillsMastered = String(localized: "All skills mastered!", table: table)

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
            static let operantDescription = String(localized: "Trainer stays inactive while dog self-discovers the behavior. Creates deeper, longer-lasting learning. Used for: attention, wait, stay.", table: table)
            static let classicalTitle = String(localized: "Classical (Active)", table: table)
            static let classicalDescription = String(localized: "Trainer guides the dog with a food lure. Produces faster initial learning. Used for: sit, down, come.", table: table)

            // Core Principles
            static let timingTitle = String(localized: "Timing", table: table)
            static let timingDescription = String(localized: "The click marks the exact moment of correct behavior. Always reward within 1-2 seconds of clicking.", table: table)

            static let neverClickTitle = String(localized: "Never Click Without Reward", table: table)
            static let neverClickDescription = String(localized: "Every click must be followed by a treat. Clicking without rewarding breaks the association and confuses your dog.", table: table)

            static let commandTimingTitle = String(localized: "Command Timing", table: table)
            static let commandTimingDescription = String(localized: "Say the cue word AS the behavior is happening, not before. Your dog learns to associate the word with the action.", table: table)

            static let environmentTitle = String(localized: "Environment Progression", table: table)
            static let environmentDescription = String(localized: "Start in low-distraction areas. Only increase difficulty after your dog succeeds consistently. If struggling, step back to an easier context.", table: table)

            static let sessionLengthTitle = String(localized: "Session Guidelines", table: table)
            static let sessionLengthDescription = String(localized: "Do 2-3 short training sessions daily. Don't train continuously during walks. Reduce daily food ration by 1/3 when using treats heavily.", table: table)

            static let stepBackTitle = String(localized: "Step Back When Needed", table: table)
            static let stepBackDescription = String(localized: "If your dog fails more than twice in a row, make the exercise easier. Success builds confidence and keeps training fun.", table: table)
        }

        // MARK: - Equipment Guidance
        enum Equipment {
            static let sectionTitle = String(localized: "Equipment", table: table)
            static let leashTitle = String(localized: "Leash", table: table)
            static let leashDescription = String(localized: "Use a standard 1.8-2m leash. Avoid retractable leashes - they teach pulling and can cause injuries.", table: table)
            static let collarTitle = String(localized: "Collar", table: table)
            static let collarDescription = String(localized: "A regular flat collar that fits snugly - two fingers should fit underneath. Remove for crate time.", table: table)
            static let clickerTitle = String(localized: "Clicker", table: table)
            static let clickerDescription = String(localized: "Muffle the sound initially by putting it in your pocket. Some puppies find the loud click startling at first.", table: table)
            static let treatsTitle = String(localized: "Treats", table: table)
            static let treatsDescription = String(localized: "Use small, soft, high-value treats. Training treats should be tiny - pea-sized or smaller.", table: table)
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

        // MARK: - Crate Training
        enum CrateTraining {
            static let sectionTitle = String(localized: "Crate Training", table: table)
            static let subtitle = String(localized: "A cozy den that helps with everything", table: table)

            // Stats
            static func crateNapPercentage(_ percent: Int) -> String {
                String(localized: "\(percent)% of recent naps in crate", table: table)
            }
            static let noNapsYet = String(localized: "No naps logged yet", table: table)

            // Benefits
            static let benefitsTitle = String(localized: "Why it helps", table: table)
            static let benefitPotty = String(localized: "Puppies avoid soiling their sleeping area, making potty training faster", table: table)
            static let benefitSelfSoothe = String(localized: "They learn to settle and self-soothe instead of getting overtired and hyper", table: table)
            static let benefitSeparation = String(localized: "Prevents separation anxiety by teaching them to be calm alone for short periods", table: table)
            static let benefitSafeSpace = String(localized: "Gives them a safe retreat when visitors come or when life gets overwhelming", table: table)
            static let benefitLongerNaps = String(localized: "Crate naps are usually longer and more restorative", table: table)

            // Tips
            static let tipsTitle = String(localized: "Getting started", table: table)
            static let tipCozy = String(localized: "Make it cozy with a blanket and safe chew toy", table: table)
            static let tipMeals = String(localized: "Feed meals in the crate so it becomes a positive place", table: table)
            static let tipTired = String(localized: "Put them in when tired - after play or a walk works best", table: table)
            static let tipStayClose = String(localized: "Stay nearby when they whimper. They're learning, not suffering", table: table)
            static let tipNoCrying = String(localized: "Don't let them out while crying - wait for a quiet moment", table: table)
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
        }

        // Skill content - names, descriptions, done criteria, how-to steps, tips
        enum Skills {
            // MARK: - Clicker
            static let clickerName = String(localized: "Clicker", table: table)
            static let clickerDescription = String(localized: "The clicker is a marker signal that tells your puppy exactly when they did something right. It bridges the gap between the behavior and the reward.", table: table)
            static let clickerDoneWhen = String(localized: "Your puppy immediately looks at you or your hand when they hear the click, expecting a treat.", table: table)
            static let clickerHowTo1 = String(localized: "Muffle the clicker initially (in your pocket or hand) - the sound can startle some puppies", table: table)
            static let clickerHowTo2 = String(localized: "Click once, then give a treat within 1-2 seconds", table: table)
            static let clickerHowTo3 = String(localized: "Repeat 10-15 times per session - your puppy should start anticipating treats", table: table)
            static let clickerHowTo4 = String(localized: "Test: click when puppy looks away. If they turn to you expecting food, it's working", table: table)
            static let clickerHowTo5 = String(localized: "The click must ALWAYS be followed by a treat - this is a fundamental rule", table: table)
            static let clickerTip1 = String(localized: "Keep sessions short (2-3 minutes)", table: table)
            static let clickerTip2 = String(localized: "Use high-value, pea-sized treats", table: table)
            static let clickerTip3 = String(localized: "Never click to get attention - click only to mark correct behavior", table: table)
            static let clickerTip4 = String(localized: "If you click by accident, still give a treat to maintain the association", table: table)
            static let clickerMistake1 = String(localized: "Clicking without giving a treat afterwards", table: table)
            static let clickerMistake2 = String(localized: "Using the clicker to get your dog's attention", table: table)
            static let clickerMistake3 = String(localized: "Delaying the treat more than 2 seconds after clicking", table: table)

            // MARK: - Name Recognition
            static let nameRecognitionName = String(localized: "Name Recognition", table: table)
            static let nameRecognitionDescription = String(localized: "Your puppy learns to look at you when they hear their name. Essential for getting attention before giving commands.", table: table)
            static let nameRecognitionDoneWhen = String(localized: "Your puppy immediately looks at you when you say their name, even with mild distractions.", table: table)
            static let nameRecognitionHowTo1 = String(localized: "Wait until your puppy looks away", table: table)
            static let nameRecognitionHowTo2 = String(localized: "Say their name once in a happy voice", table: table)
            static let nameRecognitionHowTo3 = String(localized: "When they look at you, click and treat", table: table)
            static let nameRecognitionHowTo4 = String(localized: "Gradually add distractions", table: table)
            static let nameRecognitionHowTo5 = String(localized: "Practice in different locations", table: table)
            static let nameRecognitionTip1 = String(localized: "Never use their name negatively", table: table)
            static let nameRecognitionTip2 = String(localized: "Only say the name once - don't repeat it", table: table)
            static let nameRecognitionTip3 = String(localized: "If they don't respond, try again later or reduce distractions", table: table)
            static let nameRecognitionTip4 = String(localized: "Pair with eye contact for maximum attention", table: table)

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

            // MARK: - Handling
            static let handlingName = String(localized: "Handling", table: table)
            static let handlingDescription = String(localized: "Get your puppy comfortable being touched everywhere. Important for vet visits, grooming, and health checks.", table: table)
            static let handlingDoneWhen = String(localized: "Your puppy stays relaxed when you touch their ears, paws, mouth, and tail.", table: table)
            static let handlingHowTo1 = String(localized: "Start when puppy is calm and relaxed", table: table)
            static let handlingHowTo2 = String(localized: "Gently touch ears, paws, tail, mouth", table: table)
            static let handlingHowTo3 = String(localized: "Give treats while handling", table: table)
            static let handlingHowTo4 = String(localized: "Keep sessions very short at first", table: table)
            static let handlingHowTo5 = String(localized: "Gradually increase duration and pressure", table: table)
            static let handlingTip1 = String(localized: "Go slowly - this builds lifelong trust", table: table)
            static let handlingTip2 = String(localized: "Stop if puppy shows stress signals", table: table)
            static let handlingTip3 = String(localized: "Practice lifting paws and looking in ears", table: table)
            static let handlingTip4 = String(localized: "Make it part of daily routine", table: table)

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
            static let sitDescription = String(localized: "The easiest and most useful command. A puppy who sits can't jump up at the same time - it replaces unwanted behavior naturally. You'll use this dozens of times every day.", table: table)
            static let sitDoneWhen = String(localized: "Your puppy sits on verbal cue alone in various environments, and holds the sit until released.", table: table)
            // Phase 1: Lure to Position
            static let sitHowTo1 = String(localized: "Hold a treat between thumb and finger, right at your puppy's nose level. Let them sniff but not grab it.", table: table)
            static let sitHowTo2 = String(localized: "Move your hand slowly up and slightly back, over their head toward their ears. Their nose follows up, bottom goes down naturally.", table: table)
            static let sitHowTo3 = String(localized: "The moment their bottom touches the floor: mark ('yes!' or click) and give the treat. Repeat 5-8 times per session.", table: table)
            // Phase 2: Capture & Strengthen
            static let sitHowTo4 = String(localized: "Between sessions, watch for natural sits. When your puppy sits on their own, mark and reward immediately - this reinforces the behavior throughout the day.", table: table)
            static let sitHowTo5 = String(localized: "Continue until your puppy sits reliably with the lure gesture (8 out of 10 times). This usually takes a few days of consistent practice.", table: table)
            // Phase 3: Add Verbal Cue
            static let sitHowTo6 = String(localized: "Say 'sit' clearly in a normal voice, then immediately make the lure gesture. Mark and reward when they sit.", table: table)
            static let sitHowTo7 = String(localized: "After 10-20 repetitions, say 'sit' and wait 2 seconds before helping with the gesture. Give them a chance to respond to the word alone.", table: table)
            static let sitHowTo8 = String(localized: "Gradually fade the lure gesture into a subtle hand signal. Final signal: hand rises beside your face - a clear silhouette visible from any distance.", table: table)
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
            static let watchMeDescription = String(localized: "An operant (passive) skill where your puppy self-discovers that looking at you is rewarding. Creates deep, reliable attention.", table: table)
            static let watchMeDoneWhen = String(localized: "Your puppy looks at you on command, even with distractions like your arms held out to the sides.", table: table)
            static let watchMeHowTo1 = String(localized: "Sit at puppy's level with clicker and treats ready. Hands behind your back - no lure, no gestures, no sounds. Wait.", table: table)
            static let watchMeHowTo2 = String(localized: "Click the instant your puppy looks at your face/eyes. Treat immediately.", table: table)
            static let watchMeHowTo3 = String(localized: "To reset: toss a treat to the side or behind them. Wait for them to look back at you. Repeat 10-20 times.", table: table)
            static let watchMeHowTo4 = String(localized: "Raise position: sit on a chair so puppy must look UP to make eye contact. Repeat the capture process.", table: table)
            static let watchMeHowTo5 = String(localized: "Stand with arms held out to sides. Click ONLY when puppy looks at your face, not your hands.", table: table)
            static let watchMeHowTo6 = String(localized: "Add cue: Say 'watch me' exactly AS the eye contact happens - the cue should precede the click by a fraction of a second.", table: table)
            static let watchMeHowTo7 = String(localized: "Test: Say 'watch me' first, then wait. If puppy looks, it's working. If not, go back to step 6.", table: table)
            static let watchMeHowTo8 = String(localized: "Build duration: Start at 1 second of eye contact before clicking. Gradually extend to 3-5 seconds.", table: table)
            static let watchMeHowTo9 = String(localized: "Add distance: Give the cue while standing further away. Start in low-distraction areas.", table: table)
            static let watchMeHowTo10 = String(localized: "Proof with distractions: Practice near other people, with treats visible, and eventually near other dogs (at distance first).", table: table)
            static let watchMeTip1 = String(localized: "This is operant: let them discover it, don't guide them", table: table)
            static let watchMeTip2 = String(localized: "If puppy stares constantly, toss the treat behind them to break eye contact", table: table)
            static let watchMeTip3 = String(localized: "Practice in increasingly distracting environments", table: table)
            static let watchMeTip4 = String(localized: "The 3 D's: Always reduce one D when increasing another (e.g., shorter duration when adding distance)", table: table)
            static let watchMeMistake1 = String(localized: "Holding a treat near your face (this becomes a bribe, not learned behavior)", table: table)
            static let watchMeMistake2 = String(localized: "Making noises or calling to get attention", table: table)
            static let watchMeMistake3 = String(localized: "Adding the verbal cue too early before behavior is reliable", table: table)

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
            static let looseLeashDescription = String(localized: "Walk nicely on a loose leash without pulling. Makes walks enjoyable for both of you.", table: table)
            static let looseLeashDoneWhen = String(localized: "Your puppy can walk 10 meters on a loose leash with moderate distractions.", table: table)
            static let looseLeashHowTo1 = String(localized: "Step off with your left foot (this signals movement). Take only 1-2 steps initially.", table: table)
            static let looseLeashHowTo2 = String(localized: "Click while moving forward as puppy follows beside you. Stop immediately and treat from your left hand at your side.", table: table)
            static let looseLeashHowTo3 = String(localized: "As puppy eats the treat, step off again. Click for following, stop and treat. High frequency initially: every 1-2 steps.", table: table)
            static let looseLeashHowTo4 = String(localized: "Build anticipation: puppy learns being at your left side predicts treats. Use visual markers (cones, sidewalk cracks) to remind yourself to click/treat.", table: table)
            static let looseLeashHowTo5 = String(localized: "Gradually increase steps between clicks: 3 steps, then 5, then 7. Vary randomly - sometimes 1 step, sometimes 5.", table: table)
            static let looseLeashHowTo6 = String(localized: "Always stop to treat - don't try to treat while walking. This teaches the stop-and-reward pattern clearly.", table: table)
            static let looseLeashHowTo7 = String(localized: "When puppy reliably anticipates position, add verbal cue 'let's go' BEFORE stepping off.", table: table)
            static let looseLeashHowTo8 = String(localized: "Say cue, then step off with left foot. Always cue before movement begins - this becomes your walking command.", table: table)
            static let looseLeashHowTo9 = String(localized: "Practice in the least distracting environment first. Then progress: different rooms, hallways, quiet outdoor areas.", table: table)
            static let looseLeashHowTo10 = String(localized: "If puppy pulls, stop immediately. Wait for loose leash, then cue and continue. Change direction frequently to keep attention on you.", table: table)
            static let looseLeashTip1 = String(localized: "This takes weeks to master - be patient", table: table)
            static let looseLeashTip2 = String(localized: "Tired puppies walk better - play or train first to take the edge off", table: table)
            static let looseLeashTip3 = String(localized: "Use a front-clip harness if pulling is severe - it redirects forward motion", table: table)
            static let looseLeashTip4 = String(localized: "The 3 D's: Duration, Distance, Distraction - only increase one at a time", table: table)
            static let looseLeashMistake1 = String(localized: "Using a retractable leash (teaches pulling and is dangerous)", table: table)
            static let looseLeashMistake2 = String(localized: "Pulling back on the leash when the dog pulls (creates opposition reflex)", table: table)
            static let looseLeashMistake3 = String(localized: "Trying to treat while walking (confuses the stop-and-reward pattern)", table: table)

            // MARK: - Down
            static let downName = String(localized: "Down", table: table)
            static let downDescription = String(localized: "A classical skill using a lure to guide your puppy into a lying position. Essential for settling and calm behavior.", table: table)
            static let downDoneWhen = String(localized: "Your puppy lies down on a hand signal from standing position, with a clear sweep from your navel to the side.", table: table)
            static let downHowTo1 = String(localized: "Lure from nose slowly down. Click at chest height, treat. Continue to ground, click when lying, treat", table: table)
            static let downHowTo2 = String(localized: "Tether puppy (table leg). Lure diagonally down and away - puppy can't follow, must lie down. Wait patiently", table: table)
            static let downHowTo3 = String(localized: "Extend distance: sweep hand from nose to ground, 0.5m away from puppy. Click when lying", table: table)
            static let downHowTo4 = String(localized: "Raise signal height gradually: ankle → knee → hip → standing. At each level, wait for the down", table: table)
            static let downHowTo5 = String(localized: "Final signal: from standing, sweep hand from navel to side - a clear silhouette visible from distance", table: table)
            static let downTip1 = String(localized: "The tether prevents frustration from pushing forward", table: table)
            static let downTip2 = String(localized: "Reward small progress - head lowering, one elbow down", table: table)
            static let downTip3 = String(localized: "If puppy doesn't lie down, wait patiently - let them figure it out", table: table)
            static let downTip4 = String(localized: "Create a clear silhouette so the signal is visible even with a winter jacket", table: table)
            static let downMistake1 = String(localized: "Pulling the treat too far away (puppy stands up instead)", table: table)
            static let downMistake2 = String(localized: "Waiting for perfect position instead of rewarding progress", table: table)
            static let downMistake3 = String(localized: "Physically pushing the dog into position", table: table)

            // MARK: - Come
            static let comeName = String(localized: "Come", table: table)
            static let comeDescription = String(localized: "Recall is the most important safety command you'll ever teach. A reliable recall can save your puppy's life in emergencies and opens up a world of off-leash adventures together.", table: table)
            static let comeDoneWhen = String(localized: "Your puppy comes immediately when called, even with distractions, and allows you to touch their collar.", table: table)
            // Phase 1: Foundation - Run With Me
            static let comeHowTo1 = String(localized: "Start with puppy at your side on a standard leash. Say 'Come!' and immediately run 2-4 meters forward together.", table: table)
            static let comeHowTo2 = String(localized: "Click as your puppy follows alongside you. Slow down so they can catch up. Reward with treats from your hand.", table: table)
            static let comeHowTo3 = String(localized: "Repeat 10 times per session. Your puppy learns that 'come' means exciting movement toward you, building a strong positive association.", table: table)
            // Phase 2: Front Position & Collar Grab
            static let comeHowTo4 = String(localized: "Face your puppy from 1-2 meters away. Say 'Come!' and move backward quickly. Click when they take the first steps toward you.", table: table)
            static let comeHowTo5 = String(localized: "Reward between your legs to teach a straight approach. This prevents circling behavior and teaches them to come directly to you.", table: table)
            static let comeHowTo6 = String(localized: "While treating, gently slide your fingers under the collar. Practice until collar touch is part of the reward sequence - this prevents 'close but out of reach' behavior.", table: table)
            // Phase 3: Build Distance
            static let comeHowTo7 = String(localized: "Attach a long line (10m) for safety. Have a helper hold your puppy, or use a 'stay' if reliable. Increase distance gradually: 3m, 5m, 10m+.", table: table)
            static let comeHowTo8 = String(localized: "Call 'Come!' and move away from your puppy. Click while they're running at full speed toward you. Open your legs and toss a treat through them.", table: table)
            static let comeHowTo9 = String(localized: "As they grab the treat, turn and run the opposite direction. This builds speed and enthusiasm - recall becomes a chase game they love.", table: table)
            // Phase 4: Proof with Distractions
            static let comeHowTo10 = String(localized: "Practice in progressively challenging environments: different rooms, backyard, front yard, quiet park, busier areas. Always use a long line until 100% reliable.", table: table)
            static let comeHowTo11 = String(localized: "Practice when your puppy is sniffing, watching other dogs at distance, or exploring. Use treats of higher value than the competing distraction.", table: table)
            static let comeHowTo12 = String(localized: "Integrate recall into daily life: call before meals, before going outside, randomly during play. Vary rewards - sometimes treats, sometimes play, sometimes just praise and release back to fun.", table: table)
            // Tips by phase
            static let comeTip1 = String(localized: "Puppies naturally love running with their people - use this enthusiasm to build a powerful positive association with the recall command", table: table)
            static let comeTip2 = String(localized: "Pick a fresh cue word if your current recall has been 'poisoned' by negative experiences or being ignored repeatedly", table: table)
            static let comeTip3 = String(localized: "Many dogs shy away when you reach for their collar. Practice collar touches with rewards until it's a positive part of coming to you", table: table)
            static let comeTip4 = String(localized: "Never practice recall off-leash until it's 100% reliable on the long line - one failed recall teaches your puppy that ignoring you is an option", table: table)
            static let comeTip5 = String(localized: "If recall fails, don't repeat the command. Wait, reward any movement toward you, and make the exercise easier next time", table: table)
            static let comeTip6 = String(localized: "Coming to you should NEVER end the fun. After a recall during play, reward and release back to play. This teaches that coming doesn't mean game over", table: table)
            // Mistakes
            static let comeMistake1 = String(localized: "Calling your dog for something unpleasant (bath, nail trim, end of play) - go get them instead", table: table)
            static let comeMistake2 = String(localized: "Chasing your dog when they don't come - this turns into a fun keep-away game for them", table: table)
            static let comeMistake3 = String(localized: "Repeating 'come, come, COME' - this teaches them the word is meaningless until you sound angry", table: table)
            static let comeMistake4 = String(localized: "Practicing off-leash before recall is rock-solid - one successful escape teaches them ignoring works", table: table)

            // MARK: - Wait
            static let waitName = String(localized: "Wait", table: table)
            static let waitDescription = String(localized: "Short-term stay - puppy pauses briefly at doors, before meals, etc.", table: table)
            static let waitDoneWhen = String(localized: "Your puppy waits for 10 seconds at doors and before meals.", table: table)
            static let waitHowTo1 = String(localized: "Put puppy in sit", table: table)
            static let waitHowTo2 = String(localized: "Show palm and say 'wait'", table: table)
            static let waitHowTo3 = String(localized: "Take one small step back", table: table)
            static let waitHowTo4 = String(localized: "Return and treat before they move", table: table)
            static let waitHowTo5 = String(localized: "Gradually increase distance and duration", table: table)
            static let waitTip1 = String(localized: "This is different from 'stay' - shorter and more casual", table: table)
            static let waitTip2 = String(localized: "Great for safety at doors and curbs", table: table)
            static let waitTip3 = String(localized: "Release with 'okay' or 'free'", table: table)
            static let waitTip4 = String(localized: "Practice before putting food bowl down", table: table)

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
            static let stayDescription = String(localized: "Long-duration stay - puppy remains in position until released.", table: table)
            static let stayDoneWhen = String(localized: "Your puppy stays for 30 seconds while you walk 5 meters away.", table: table)
            static let stayHowTo1 = String(localized: "Start from sit or down", table: table)
            static let stayHowTo2 = String(localized: "Add duration first (stay close but longer)", table: table)
            static let stayHowTo3 = String(localized: "Then add distance (stay far but shorter)", table: table)
            static let stayHowTo4 = String(localized: "Return to puppy before releasing", table: table)
            static let stayHowTo5 = String(localized: "Add distractions last", table: table)
            static let stayTip1 = String(localized: "The three Ds: Duration, Distance, Distraction - increase one at a time", table: table)
            static let stayTip2 = String(localized: "Always return to puppy - don't call them to break stay", table: table)
            static let stayTip3 = String(localized: "If they break, simply reset without punishment", table: table)
            static let stayTip4 = String(localized: "This takes months to master - be patient", table: table)
        }
    }
}
