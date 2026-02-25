//
//  Strings+Training.swift
//  Ollie-app
//
//  Training module strings including skill content

import Foundation

extension Strings {

    // MARK: - Train Tab
    enum Train {
        static let pottyProgress = String(localized: "Potty Progress")
        static let socialization = String(localized: "Socialization")
        static let skills = String(localized: "Skills")
        static let outdoorThisWeek = String(localized: "outdoor this week")
        static let dayStreak = String(localized: "day streak")
        static let topTriggers = String(localized: "Top triggers")
        static let allCategories = String(localized: "All categories")
    }

    // MARK: - Training
    enum Training {
        static let title = String(localized: "Training")
        static let skillTracker = String(localized: "Skill Tracker")

        // Categories
        static let categoryFoundations = String(localized: "Foundations")
        static let categoryBasicCommands = String(localized: "Basic Commands")
        static let categoryCare = String(localized: "Care")
        static let categorySafety = String(localized: "Safety")
        static let categoryImpulseControl = String(localized: "Impulse Control")

        // Status
        static let statusNotStarted = String(localized: "Not started")
        static let statusStarted = String(localized: "Started")
        static let statusPracticing = String(localized: "Practicing")
        static let statusMastered = String(localized: "Mastered")

        // Week hero card
        static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)")
        }
        static let focusSkills = String(localized: "Focus skills")
        static func progressCount(started: Int, total: Int) -> String {
            String(localized: "\(started)/\(total) started")
        }

        // Skill card
        static func sessionCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 session")
            } else {
                return String(localized: "\(count) sessions")
            }
        }
        static let locked = String(localized: "Locked")
        static let requires = String(localized: "Requires")
        static let howTo = String(localized: "How to train")
        static let doneWhen = String(localized: "Done when")
        static let tips = String(localized: "Tips")
        static let recentSessions = String(localized: "Recent sessions")
        static let logSession = String(localized: "Log session")
        static let markMastered = String(localized: "Mark as mastered")
        static let unmarkMastered = String(localized: "Unmark mastered")

        // Log sheet
        static let logTrainingSession = String(localized: "Log Training Session")
        static let duration = String(localized: "Duration")
        static let durationMinutes = String(localized: "minutes")
        static let result = String(localized: "Result")
        static let resultPlaceholder = String(localized: "e.g. Good focus, needed help")
        static let note = String(localized: "Note")
        static let notePlaceholder = String(localized: "Optional note...")

        // Empty state
        static let noSkillsStarted = String(localized: "No skills started yet")
        static let tapToBegin = String(localized: "Tap a skill to begin training")

        // Week plan titles
        enum WeekTitles {
            static let week1 = String(localized: "Foundation Week")
            static let week2 = String(localized: "First Commands")
            static let week3 = String(localized: "Safety & Movement")
            static let week4 = String(localized: "Impulse Control")
            static let week5 = String(localized: "Duration Training")
            static let week6 = String(localized: "Consolidation Week")

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
            static let clickerName = String(localized: "Clicker")
            static let clickerDescription = String(localized: "Teach your puppy that the click sound means a treat is coming. This is the foundation for all marker-based training.")
            static let clickerDoneWhen = String(localized: "Your puppy immediately looks at you or your hand when they hear the click, expecting a treat.")
            static let clickerHowTo1 = String(localized: "Hold treats ready in your hand")
            static let clickerHowTo2 = String(localized: "Click the clicker (or use a marker word like 'yes')")
            static let clickerHowTo3 = String(localized: "Immediately give a treat within 1-2 seconds")
            static let clickerHowTo4 = String(localized: "Repeat 10-15 times per session")
            static let clickerHowTo5 = String(localized: "Your puppy should start looking for treats when they hear the click")
            static let clickerTip1 = String(localized: "Keep sessions short (2-3 minutes)")
            static let clickerTip2 = String(localized: "Use high-value treats")
            static let clickerTip3 = String(localized: "The click must ALWAYS be followed by a treat")
            static let clickerTip4 = String(localized: "Don't click to get attention - click to mark behavior")

            // MARK: - Name Recognition
            static let nameRecognitionName = String(localized: "Name Recognition")
            static let nameRecognitionDescription = String(localized: "Your puppy learns to look at you when they hear their name. Essential for getting attention before giving commands.")
            static let nameRecognitionDoneWhen = String(localized: "Your puppy immediately looks at you when you say their name, even with mild distractions.")
            static let nameRecognitionHowTo1 = String(localized: "Wait until your puppy looks away")
            static let nameRecognitionHowTo2 = String(localized: "Say their name once in a happy voice")
            static let nameRecognitionHowTo3 = String(localized: "When they look at you, click and treat")
            static let nameRecognitionHowTo4 = String(localized: "Gradually add distractions")
            static let nameRecognitionHowTo5 = String(localized: "Practice in different locations")
            static let nameRecognitionTip1 = String(localized: "Never use their name negatively")
            static let nameRecognitionTip2 = String(localized: "Only say the name once - don't repeat it")
            static let nameRecognitionTip3 = String(localized: "If they don't respond, try again later or reduce distractions")
            static let nameRecognitionTip4 = String(localized: "Pair with eye contact for maximum attention")

            // MARK: - Luring
            static let luringName = String(localized: "Luring")
            static let luringDescription = String(localized: "Use a treat to guide your puppy into positions. This technique is used to teach many other commands.")
            static let luringDoneWhen = String(localized: "Your puppy follows the treat smoothly in any direction without jumping or grabbing.")
            static let luringHowTo1 = String(localized: "Hold a treat between your thumb and fingers")
            static let luringHowTo2 = String(localized: "Let your puppy sniff the treat but not eat it")
            static let luringHowTo3 = String(localized: "Move the treat slowly - your puppy's nose should follow")
            static let luringHowTo4 = String(localized: "Practice moving in different directions")
            static let luringHowTo5 = String(localized: "Reward when they follow the lure smoothly")
            static let luringTip1 = String(localized: "Move slowly and smoothly")
            static let luringTip2 = String(localized: "Keep the treat close to their nose")
            static let luringTip3 = String(localized: "If they lose interest, use higher value treats")
            static let luringTip4 = String(localized: "Eventually fade the lure into a hand signal")

            // MARK: - Handling
            static let handlingName = String(localized: "Handling")
            static let handlingDescription = String(localized: "Get your puppy comfortable being touched everywhere. Important for vet visits, grooming, and health checks.")
            static let handlingDoneWhen = String(localized: "Your puppy stays relaxed when you touch their ears, paws, mouth, and tail.")
            static let handlingHowTo1 = String(localized: "Start when puppy is calm and relaxed")
            static let handlingHowTo2 = String(localized: "Gently touch ears, paws, tail, mouth")
            static let handlingHowTo3 = String(localized: "Give treats while handling")
            static let handlingHowTo4 = String(localized: "Keep sessions very short at first")
            static let handlingHowTo5 = String(localized: "Gradually increase duration and pressure")
            static let handlingTip1 = String(localized: "Go slowly - this builds lifelong trust")
            static let handlingTip2 = String(localized: "Stop if puppy shows stress signals")
            static let handlingTip3 = String(localized: "Practice lifting paws and looking in ears")
            static let handlingTip4 = String(localized: "Make it part of daily routine")

            // MARK: - Collar & Leash
            static let collarLeashName = String(localized: "Collar & Leash")
            static let collarLeashDescription = String(localized: "Get your puppy comfortable wearing a collar and being on a leash. Foundation for all outdoor training.")
            static let collarLeashDoneWhen = String(localized: "Your puppy ignores the collar and doesn't panic when leash is attached or lifted.")
            static let collarLeashHowTo1 = String(localized: "Let puppy sniff the collar first")
            static let collarLeashHowTo2 = String(localized: "Put collar on during positive moments (meals, play)")
            static let collarLeashHowTo3 = String(localized: "Start with short periods")
            static let collarLeashHowTo4 = String(localized: "Attach leash and let them drag it supervised")
            static let collarLeashHowTo5 = String(localized: "Pick up leash and follow puppy around")
            static let collarLeashTip1 = String(localized: "Check collar fit - two fingers should fit underneath")
            static let collarLeashTip2 = String(localized: "Never leave leash on unsupervised")
            static let collarLeashTip3 = String(localized: "If puppy freezes, lure them forward with treats")
            static let collarLeashTip4 = String(localized: "Practice inside before going outside")

            // MARK: - Sit
            static let sitName = String(localized: "Sit")
            static let sitDescription = String(localized: "The classic sit command. A building block for many other behaviors.")
            static let sitDoneWhen = String(localized: "Your puppy sits on command with just the verbal cue, no lure needed.")
            static let sitHowTo1 = String(localized: "Hold treat above puppy's nose")
            static let sitHowTo2 = String(localized: "Move treat slowly back over their head")
            static let sitHowTo3 = String(localized: "As their head goes up, their bottom goes down")
            static let sitHowTo4 = String(localized: "Click and treat the moment bottom touches floor")
            static let sitHowTo5 = String(localized: "Add the word 'sit' once behavior is reliable")
            static let sitTip1 = String(localized: "Don't push their bottom down")
            static let sitTip2 = String(localized: "If they jump, hold treat closer to nose")
            static let sitTip3 = String(localized: "Practice before meals for extra motivation")
            static let sitTip4 = String(localized: "Gradually phase out hand movement")

            // MARK: - Watch Me
            static let watchMeName = String(localized: "Watch Me")
            static let watchMeDescription = String(localized: "Your puppy learns to make eye contact on command. Great for getting focus before other commands.")
            static let watchMeDoneWhen = String(localized: "Your puppy makes eye contact for 3-5 seconds on command.")
            static let watchMeHowTo1 = String(localized: "Hold a treat near your face")
            static let watchMeHowTo2 = String(localized: "Wait for eye contact")
            static let watchMeHowTo3 = String(localized: "The moment they look at your eyes, click and treat")
            static let watchMeHowTo4 = String(localized: "Add the cue 'watch' or 'look'")
            static let watchMeHowTo5 = String(localized: "Gradually increase duration")
            static let watchMeTip1 = String(localized: "Start in low-distraction environment")
            static let watchMeTip2 = String(localized: "Some dogs find direct eye contact uncomfortable - be patient")
            static let watchMeTip3 = String(localized: "Use this to redirect attention from distractions")
            static let watchMeTip4 = String(localized: "Great to use before crossing streets")

            // MARK: - Touch
            static let touchName = String(localized: "Touch")
            static let touchDescription = String(localized: "Puppy learns to touch their nose to your palm. Useful for positioning and recall.")
            static let touchDoneWhen = String(localized: "Your puppy touches their nose to your palm on command from 1 meter away.")
            static let touchHowTo1 = String(localized: "Present flat palm near puppy's nose")
            static let touchHowTo2 = String(localized: "Most puppies will naturally investigate")
            static let touchHowTo3 = String(localized: "Click and treat when nose touches palm")
            static let touchHowTo4 = String(localized: "Add the cue 'touch'")
            static let touchHowTo5 = String(localized: "Practice at different heights and distances")
            static let touchTip1 = String(localized: "Don't push your hand into their face")
            static let touchTip2 = String(localized: "Rub treat on palm if they need encouragement")
            static let touchTip3 = String(localized: "Great alternative to 'come' for recall")
            static let touchTip4 = String(localized: "Can be used to guide puppy into positions")

            // MARK: - Loose Leash Walking
            static let looseLeashName = String(localized: "Loose Leash Walking")
            static let looseLeashDescription = String(localized: "Walk nicely on a loose leash without pulling. Makes walks enjoyable for both of you.")
            static let looseLeashDoneWhen = String(localized: "Your puppy can walk 10 meters on a loose leash with moderate distractions.")
            static let looseLeashHowTo1 = String(localized: "Start inside or in a boring area")
            static let looseLeashHowTo2 = String(localized: "Reward frequently for staying beside you")
            static let looseLeashHowTo3 = String(localized: "If puppy pulls, stop walking immediately")
            static let looseLeashHowTo4 = String(localized: "Wait for loose leash before continuing")
            static let looseLeashHowTo5 = String(localized: "Change direction frequently to keep attention")
            static let looseLeashTip1 = String(localized: "This takes weeks to master - be patient")
            static let looseLeashTip2 = String(localized: "Use a front-clip harness if pulling is severe")
            static let looseLeashTip3 = String(localized: "Practice 'let's go' turns to redirect")
            static let looseLeashTip4 = String(localized: "Tired puppies walk better - play first")

            // MARK: - Down
            static let downName = String(localized: "Down")
            static let downDescription = String(localized: "Puppy lies down on command. A calm position useful for settling.")
            static let downDoneWhen = String(localized: "Your puppy lies down on command from a sit, without lure.")
            static let downHowTo1 = String(localized: "Start with puppy in sit")
            static let downHowTo2 = String(localized: "Lure treat from nose straight down to floor")
            static let downHowTo3 = String(localized: "Then slowly pull treat away from puppy along floor")
            static let downHowTo4 = String(localized: "Click and treat when elbows touch ground")
            static let downHowTo5 = String(localized: "Add the cue 'down' once behavior is reliable")
            static let downTip1 = String(localized: "Don't push puppy down")
            static let downTip2 = String(localized: "If they stand, you moved the treat too far")
            static let downTip3 = String(localized: "Practice on a comfortable surface first")
            static let downTip4 = String(localized: "Great for restaurant and café visits")

            // MARK: - Come
            static let comeName = String(localized: "Come")
            static let comeDescription = String(localized: "Recall - the most important safety command. Your puppy comes to you when called.")
            static let comeDoneWhen = String(localized: "Your puppy comes immediately when called in the house and garden.")
            static let comeHowTo1 = String(localized: "Start very close with high-value treats")
            static let comeHowTo2 = String(localized: "Say puppy's name + 'come' in excited voice")
            static let comeHowTo3 = String(localized: "Reward generously when they reach you")
            static let comeHowTo4 = String(localized: "Always make coming to you worthwhile")
            static let comeHowTo5 = String(localized: "Never call for something negative")
            static let comeTip1 = String(localized: "Use a long line for safety during training")
            static let comeTip2 = String(localized: "Never chase your puppy if they don't come")
            static let comeTip3 = String(localized: "Practice randomly throughout the day")
            static let comeTip4 = String(localized: "Coming to you should be the best thing ever")

            // MARK: - Wait
            static let waitName = String(localized: "Wait")
            static let waitDescription = String(localized: "Short-term stay - puppy pauses briefly at doors, before meals, etc.")
            static let waitDoneWhen = String(localized: "Your puppy waits for 10 seconds at doors and before meals.")
            static let waitHowTo1 = String(localized: "Put puppy in sit")
            static let waitHowTo2 = String(localized: "Show palm and say 'wait'")
            static let waitHowTo3 = String(localized: "Take one small step back")
            static let waitHowTo4 = String(localized: "Return and treat before they move")
            static let waitHowTo5 = String(localized: "Gradually increase distance and duration")
            static let waitTip1 = String(localized: "This is different from 'stay' - shorter and more casual")
            static let waitTip2 = String(localized: "Great for safety at doors and curbs")
            static let waitTip3 = String(localized: "Release with 'okay' or 'free'")
            static let waitTip4 = String(localized: "Practice before putting food bowl down")

            // MARK: - Place
            static let placeName = String(localized: "Place")
            static let placeDescription = String(localized: "Puppy goes to their bed or mat and stays there. Great for settling at home.")
            static let placeDoneWhen = String(localized: "Your puppy goes to their bed and lies down for 2 minutes.")
            static let placeHowTo1 = String(localized: "Lure puppy onto their bed or mat")
            static let placeHowTo2 = String(localized: "Ask for a down on the mat")
            static let placeHowTo3 = String(localized: "Reward for staying on the mat")
            static let placeHowTo4 = String(localized: "Add the cue 'place' or 'bed'")
            static let placeHowTo5 = String(localized: "Gradually add duration and distance")
            static let placeTip1 = String(localized: "Use a portable mat to transfer this skill anywhere")
            static let placeTip2 = String(localized: "Great for when guests arrive")
            static let placeTip3 = String(localized: "Build duration very slowly")
            static let placeTip4 = String(localized: "Practice during meals and TV time")

            // MARK: - Stay
            static let stayName = String(localized: "Stay")
            static let stayDescription = String(localized: "Long-duration stay - puppy remains in position until released.")
            static let stayDoneWhen = String(localized: "Your puppy stays for 30 seconds while you walk 5 meters away.")
            static let stayHowTo1 = String(localized: "Start from sit or down")
            static let stayHowTo2 = String(localized: "Add duration first (stay close but longer)")
            static let stayHowTo3 = String(localized: "Then add distance (stay far but shorter)")
            static let stayHowTo4 = String(localized: "Return to puppy before releasing")
            static let stayHowTo5 = String(localized: "Add distractions last")
            static let stayTip1 = String(localized: "The three Ds: Duration, Distance, Distraction - increase one at a time")
            static let stayTip2 = String(localized: "Always return to puppy - don't call them to break stay")
            static let stayTip3 = String(localized: "If they break, simply reset without punishment")
            static let stayTip4 = String(localized: "This takes months to master - be patient")
        }
    }
}
