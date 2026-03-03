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
        static let outdoorThisWeek = String(localized: "outdoor this week", table: table)
        static let dayStreak = String(localized: "day streak", table: table)
        static let topTriggers = String(localized: "Top triggers", table: table)
        static let allCategories = String(localized: "All categories", table: table)

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
        static let unmarkMastered = String(localized: "Unmark mastered", table: table)

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
            static let sitDescription = String(localized: "A classical (active) skill where you guide your puppy into position with a lure. Foundation for many other commands.", table: table)
            static let sitDoneWhen = String(localized: "Your puppy sits on a hand signal from 10-15cm away, then responds to just the verbal cue.", table: table)
            static let sitHowTo1 = String(localized: "Hold treat at puppy's nose level, let them sniff", table: table)
            static let sitHowTo2 = String(localized: "Move the treat toward their EARS (not over their head toward tail)", table: table)
            static let sitHowTo3 = String(localized: "As their nose follows up, their bottom goes down naturally", table: table)
            static let sitHowTo4 = String(localized: "Click the moment bottom touches floor, then treat", table: table)
            static let sitHowTo5 = String(localized: "Gradually increase distance: start touching nose, progress to 10-15cm away", table: table)
            static let sitTip1 = String(localized: "Move toward the ears, not over the head - this prevents jumping", table: table)
            static let sitTip2 = String(localized: "Say 'sit' AS the bottom touches down, not before", table: table)
            static let sitTip3 = String(localized: "Final hand signal: hand beside your face, 90° at armpit and elbow - a clear silhouette", table: table)
            static let sitTip4 = String(localized: "The silhouette matters: your dog should recognize the signal even with a winter jacket or from a distance", table: table)
            static let sitMistake1 = String(localized: "Moving the lure over the head toward the tail (causes jumping or backing up)", table: table)
            static let sitMistake2 = String(localized: "Saying the command before the behavior happens", table: table)
            static let sitMistake3 = String(localized: "Pushing the dog's bottom down instead of luring", table: table)

            // MARK: - Watch Me
            static let watchMeName = String(localized: "Watch Me", table: table)
            static let watchMeDescription = String(localized: "An operant (passive) skill where your puppy self-discovers that looking at you is rewarding. Creates deep, reliable attention.", table: table)
            static let watchMeDoneWhen = String(localized: "Your puppy looks at you on command, even with distractions like your arms held out to the sides.", table: table)
            static let watchMeHowTo1 = String(localized: "Sit at puppy's level. Hands behind back - no lure, no gestures. Wait for eye contact, click and treat", table: table)
            static let watchMeHowTo2 = String(localized: "Build duration: once step 1 works, wait a moment before clicking to extend the eye contact", table: table)
            static let watchMeHowTo3 = String(localized: "Raise your position: sit on a chair so puppy must look up higher. Repeat steps 1-2", table: table)
            static let watchMeHowTo4 = String(localized: "Stand with arms out to the sides. Click only when puppy looks at your face, not your hands", table: table)
            static let watchMeHowTo5 = String(localized: "Add cue: say 'watch me' AS the eye contact happens, then click and treat", table: table)
            static let watchMeHowTo6 = String(localized: "Test: say 'watch me' first. If puppy looks, it works! If not, go back to step 5", table: table)
            static let watchMeTip1 = String(localized: "This is operant: let them discover it, don't guide them", table: table)
            static let watchMeTip2 = String(localized: "If puppy stares constantly, toss the treat behind them to break eye contact", table: table)
            static let watchMeTip3 = String(localized: "Practice in increasingly distracting environments", table: table)
            static let watchMeTip4 = String(localized: "Great for redirecting attention before crossing streets", table: table)
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
            static let looseLeashHowTo1 = String(localized: "Start inside or in a boring area", table: table)
            static let looseLeashHowTo2 = String(localized: "Reward frequently for staying beside you", table: table)
            static let looseLeashHowTo3 = String(localized: "If puppy pulls, stop walking immediately", table: table)
            static let looseLeashHowTo4 = String(localized: "Wait for loose leash before continuing", table: table)
            static let looseLeashHowTo5 = String(localized: "Change direction frequently to keep attention", table: table)
            static let looseLeashTip1 = String(localized: "This takes weeks to master - be patient", table: table)
            static let looseLeashTip2 = String(localized: "Use a front-clip harness if pulling is severe", table: table)
            static let looseLeashTip3 = String(localized: "Practice 'let's go' turns to redirect", table: table)
            static let looseLeashTip4 = String(localized: "Tired puppies walk better - play first", table: table)
            static let looseLeashMistake1 = String(localized: "Using a retractable leash (teaches pulling)", table: table)
            static let looseLeashMistake2 = String(localized: "Pulling back on the leash when the dog pulls (creates opposition reflex)", table: table)

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
            static let comeDescription = String(localized: "Recall - the most important safety command. Your puppy comes to you when called.", table: table)
            static let comeDoneWhen = String(localized: "Your puppy comes immediately when called in the house and garden.", table: table)
            static let comeHowTo1 = String(localized: "Start very close with high-value treats", table: table)
            static let comeHowTo2 = String(localized: "Say puppy's name + 'come' in excited voice", table: table)
            static let comeHowTo3 = String(localized: "Reward generously when they reach you", table: table)
            static let comeHowTo4 = String(localized: "Always make coming to you worthwhile", table: table)
            static let comeHowTo5 = String(localized: "Never call for something negative", table: table)
            static let comeTip1 = String(localized: "Use a long line for safety during training", table: table)
            static let comeTip2 = String(localized: "Never chase your puppy if they don't come", table: table)
            static let comeTip3 = String(localized: "Practice randomly throughout the day", table: table)
            static let comeTip4 = String(localized: "Coming to you should be the best thing ever", table: table)
            static let comeMistake1 = String(localized: "Calling your dog for something unpleasant (bath, nail trim)", table: table)
            static let comeMistake2 = String(localized: "Chasing your dog when they don't come", table: table)
            static let comeMistake3 = String(localized: "Repeating the command multiple times without consequence", table: table)

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
