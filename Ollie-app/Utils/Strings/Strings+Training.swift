//
//  Strings+Training.swift
//  Ollie-app
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

        // Week plan titles
        enum WeekTitles {
            static let week1 = String(localized: "Foundation Week", table: table)
            static let week2 = String(localized: "First Commands", table: table)
            static let week3 = String(localized: "Safety & Movement", table: table)
            static let week4 = String(localized: "Impulse Control", table: table)
            static let week5 = String(localized: "Duration Training", table: table)
            static let week6 = String(localized: "Consolidation Week", table: table)

            static func title(for week: Int) -> String {
                switch week {
                case 1: return week1
                case 2: return week2
                case 3: return week3
                case 4: return week4
                case 5: return week5
                case 6: return week6
                default: return week6
                }
            }
        }

        // Skill content - names, descriptions, done criteria, how-to steps, tips
        enum Skills {
            // MARK: - Clicker
            static let clickerName = String(localized: "Clicker", table: table)
            static let clickerDescription = String(localized: "Teach your puppy that the click sound means a treat is coming. This is the foundation for all marker-based training.", table: table)
            static let clickerDoneWhen = String(localized: "Your puppy immediately looks at you or your hand when they hear the click, expecting a treat.", table: table)
            static let clickerHowTo1 = String(localized: "Hold treats ready in your hand", table: table)
            static let clickerHowTo2 = String(localized: "Click the clicker (or use a marker word like 'yes')", table: table)
            static let clickerHowTo3 = String(localized: "Immediately give a treat within 1-2 seconds", table: table)
            static let clickerHowTo4 = String(localized: "Repeat 10-15 times per session", table: table)
            static let clickerHowTo5 = String(localized: "Your puppy should start looking for treats when they hear the click", table: table)
            static let clickerTip1 = String(localized: "Keep sessions short (2-3 minutes)", table: table)
            static let clickerTip2 = String(localized: "Use high-value treats", table: table)
            static let clickerTip3 = String(localized: "The click must ALWAYS be followed by a treat", table: table)
            static let clickerTip4 = String(localized: "Don't click to get attention - click to mark behavior", table: table)

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
            static let sitDescription = String(localized: "The classic sit command. A building block for many other behaviors.", table: table)
            static let sitDoneWhen = String(localized: "Your puppy sits on command with just the verbal cue, no lure needed.", table: table)
            static let sitHowTo1 = String(localized: "Hold treat above puppy's nose", table: table)
            static let sitHowTo2 = String(localized: "Move treat slowly back over their head", table: table)
            static let sitHowTo3 = String(localized: "As their head goes up, their bottom goes down", table: table)
            static let sitHowTo4 = String(localized: "Click and treat the moment bottom touches floor", table: table)
            static let sitHowTo5 = String(localized: "Add the word 'sit' once behavior is reliable", table: table)
            static let sitTip1 = String(localized: "Don't push their bottom down", table: table)
            static let sitTip2 = String(localized: "If they jump, hold treat closer to nose", table: table)
            static let sitTip3 = String(localized: "Practice before meals for extra motivation", table: table)
            static let sitTip4 = String(localized: "Gradually phase out hand movement", table: table)

            // MARK: - Watch Me
            static let watchMeName = String(localized: "Watch Me", table: table)
            static let watchMeDescription = String(localized: "Your puppy learns to make eye contact on command. Great for getting focus before other commands.", table: table)
            static let watchMeDoneWhen = String(localized: "Your puppy makes eye contact for 3-5 seconds on command.", table: table)
            static let watchMeHowTo1 = String(localized: "Hold a treat near your face", table: table)
            static let watchMeHowTo2 = String(localized: "Wait for eye contact", table: table)
            static let watchMeHowTo3 = String(localized: "The moment they look at your eyes, click and treat", table: table)
            static let watchMeHowTo4 = String(localized: "Add the cue 'watch' or 'look'", table: table)
            static let watchMeHowTo5 = String(localized: "Gradually increase duration", table: table)
            static let watchMeTip1 = String(localized: "Start in low-distraction environment", table: table)
            static let watchMeTip2 = String(localized: "Some dogs find direct eye contact uncomfortable - be patient", table: table)
            static let watchMeTip3 = String(localized: "Use this to redirect attention from distractions", table: table)
            static let watchMeTip4 = String(localized: "Great to use before crossing streets", table: table)

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

            // MARK: - Down
            static let downName = String(localized: "Down", table: table)
            static let downDescription = String(localized: "Puppy lies down on command. A calm position useful for settling.", table: table)
            static let downDoneWhen = String(localized: "Your puppy lies down on command from a sit, without lure.", table: table)
            static let downHowTo1 = String(localized: "Start with puppy in sit", table: table)
            static let downHowTo2 = String(localized: "Lure treat from nose straight down to floor", table: table)
            static let downHowTo3 = String(localized: "Then slowly pull treat away from puppy along floor", table: table)
            static let downHowTo4 = String(localized: "Click and treat when elbows touch ground", table: table)
            static let downHowTo5 = String(localized: "Add the cue 'down' once behavior is reliable", table: table)
            static let downTip1 = String(localized: "Don't push puppy down", table: table)
            static let downTip2 = String(localized: "If they stand, you moved the treat too far", table: table)
            static let downTip3 = String(localized: "Practice on a comfortable surface first", table: table)
            static let downTip4 = String(localized: "Great for restaurant and café visits", table: table)

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
