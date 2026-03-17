//
//  Strings+Foundations.swift
//  Ollie-app
//
//  Training foundations module strings - welcome, quizzes, theory content
//

import Foundation

extension Strings {

    // MARK: - Training Foundations Extension
    // Note: This extends the Training enum defined in Strings+Training.swift
}

private let foundationsTable = "Training"

extension Strings.Training {

    // MARK: - Foundations Module
    enum Foundations {
        // Quiz UI
        static let quiz = String(localized: "Quiz", table: foundationsTable)
        static let quizTrue = String(localized: "True", table: foundationsTable)
        static let quizFalse = String(localized: "False", table: foundationsTable)
        static let quizCorrect = String(localized: "That's right!", table: foundationsTable)
        static let quizSurprising = String(localized: "Surprised? Most people get this wrong.", table: foundationsTable)
        static let heresWhy = String(localized: "Here's why:", table: foundationsTable)
        static let theTruth = String(localized: "The truth:", table: foundationsTable)

        // Module names
        static let module1Name = String(localized: "Getting started", table: foundationsTable)
        static let module1Subtitle = String(localized: "Welcome to skills training", table: foundationsTable)
        static let module2Name = String(localized: "How Dogs Learn", table: foundationsTable)
        static let module2Subtitle = String(localized: "Understanding your training partner", table: foundationsTable)
        static let module3Name = String(localized: "Taking It Further", table: foundationsTable)
        static let module3Subtitle = String(localized: "Adding complexity and new environments", table: foundationsTable)

        // Skip button
        static let skipFoundations = String(localized: "I already know this", table: foundationsTable)
        static let letsBegin = String(localized: "Let's begin", table: foundationsTable)
        static let continueReading = String(localized: "Continue", table: foundationsTable)
        static let answerQuizToContinue = String(localized: "Answer the quiz to continue", table: foundationsTable)

        // Progress
        static func pageProgress(current: Int, total: Int) -> String {
            String(localized: "Page \(current) of \(total)", table: foundationsTable)
        }

        // Skills locked message
        static let skillsLocked = String(localized: "Skills training is locked", table: foundationsTable)
        static let completeGettingStarted = String(localized: "Complete Getting Started to begin training", table: foundationsTable)

        // MARK: - Module 1: Getting Started

        enum Welcome {
            // Page 1: Welcome
            static let title = String(localized: "Welcome", table: foundationsTable)
            static let heading = String(localized: "Welcome to the most rewarding part of having a dog.", table: foundationsTable)

            static let para1 = String(localized: "For thousands of years, humans and dogs have evolved together — a partnership unlike any other in the animal kingdom. Dogs were bred not just to live alongside us, but to understand us, to read our gestures, to want to please us.", table: foundationsTable)

            static let para2 = String(localized: "That means your dog already knows how to learn. They're ready. Willing. Eager.", table: foundationsTable)

            static let para3 = String(localized: "What they're waiting for is you to learn how to teach them.", table: foundationsTable)

            static let para4 = String(localized: "This section will help you do exactly that. You'll learn a simple, proven system that trainers worldwide use — and you'll be amazed at how quickly your dog picks it up.", table: foundationsTable)

            static let noteTitle = String(localized: "A note", table: foundationsTable)
            static let noteText = String(localized: "Nothing replaces in-person training with a professional. If you can, book a puppy class in your area! But most of the practice happens at home, between classes — and that's where this guide becomes invaluable.", table: foundationsTable)

            // Page 2: Quiz - Look at me
            static let quizTitle = String(localized: "A Quick Test", table: foundationsTable)
            static let quizIntro = String(localized: "Before we begin, let's find out what you already know.", table: foundationsTable)

            static let quiz1Question = String(localized: "To teach your dog to look at you, say \"look at me\" repeatedly until they glance at your face, then give a treat.", table: foundationsTable)
            static let quiz1Explanation = String(localized: "Your dog doesn't understand English. When you say \"look at me\" while they're sniffing the floor, they associate those words with... sniffing the floor. The command becomes meaningless noise.\n\nThe right way? Wait silently until they happen to look at you. Mark it (\"Yes!\" or click) and treat. Only after they reliably offer eye contact do you add the words — saying \"look\" as they're looking.", table: foundationsTable)

            static let quiz2Question = String(localized: "Your dog is chewing your slipper. You say \"let go! let go!\" until they drop it, then praise them. This teaches them \"let go.\"", table: foundationsTable)
            static let quiz2Explanation = String(localized: "Even worse — you've accidentally taught them that \"let go\" means biting! They heard those words while biting, so now \"let go\" is associated with the action of biting down.\n\nThe right way? Get them to release (with a trade, or by waiting), then say \"let go\" as they're releasing. Reward. Repeat. The word gets attached to the action of releasing.", table: foundationsTable)

            // Page 3: The Big Secret
            static let secretTitle = String(localized: "The Big Secret", table: foundationsTable)
            static let secretHeading = String(localized: "Here's what most people get wrong:", table: foundationsTable)
            static let secretPara1 = String(localized: "They think training is about teaching the dog. But your dog already knows how to learn — they've been bred for this for 15,000 years.", table: foundationsTable)
            static let secretHighlight = String(localized: "Training is really about teaching you.", table: foundationsTable)
            static let secretPara2 = String(localized: "You're learning a new language. A language of timing, markers, rewards, and patience. Once you speak it, your dog will understand you instantly.", table: foundationsTable)
            static let secretPara3 = String(localized: "The good news? This language is simple. There are just a few rules:", table: foundationsTable)

            static let rule1 = String(localized: "Capture first, cue later — reward the behavior when it happens, add words only after it's reliable", table: foundationsTable)
            static let rule2 = String(localized: "Mark the moment — a click or \"yes!\" tells them exactly what they did right", table: foundationsTable)
            static let rule3 = String(localized: "Reward immediately — the treat confirms the marker", table: foundationsTable)
            static let rule4 = String(localized: "Keep it short — 2-5 minute sessions, end on a win", table: foundationsTable)

            static let secretClosing = String(localized: "That's it. The rest is practice.", table: foundationsTable)

            // Page 4: It's Harder for You
            static let harderTitle = String(localized: "It's Harder for You", table: foundationsTable)
            static let harderHeading = String(localized: "Let's be honest:", table: foundationsTable)
            static let harderPara1 = String(localized: "The tricky part isn't your dog. It's you.", table: foundationsTable)
            static let harderPara2 = String(localized: "Your dog will pick this up faster than you expect. They're wired for it. But you'll fumble. You'll click at the wrong moment. You'll say the cue too early. You'll forget the treats.", table: foundationsTable)
            static let harderHighlight = String(localized: "That's completely fine.", table: foundationsTable)
            static let harderPara3 = String(localized: "Dogs are forgiving. They don't need perfection — they need consistency. If you're roughly right, roughly often, they'll figure out the pattern.", table: foundationsTable)

            static let counterintuitiveTitle = String(localized: "Some things will feel counterintuitive:", table: foundationsTable)
            static let counterintuitive1 = String(localized: "Staying silent when you want to say \"good dog!\"", table: foundationsTable)
            static let counterintuitive2 = String(localized: "Waiting passively when you want to help", table: foundationsTable)
            static let counterintuitive3 = String(localized: "Using hand signals instead of words", table: foundationsTable)

            static let harderClosing = String(localized: "Trust the process. These methods work because of how dog brains actually function — not how we assume they function.", table: foundationsTable)
            static let harderRemember = String(localized: "Remember: You're not failing if it's messy. You're learning. So is your dog. You're learning together.", table: foundationsTable)

            // Page 5: Your Toolkit
            static let toolkitTitle = String(localized: "What You'll Need", table: foundationsTable)
            static let toolkitIntro = String(localized: "Your training toolkit:", table: foundationsTable)

            static let toolMarkerTitle = String(localized: "A marker", table: foundationsTable)
            static let toolMarkerDesc = String(localized: "Clicker or the word \"yes!\" — pick one, stick with it", table: foundationsTable)

            static let toolKibbleTitle = String(localized: "Kibble", table: foundationsTable)
            static let toolKibbleDesc = String(localized: "Your dog's regular food, not fancy treats. Why? Motivation. Save special treats for one thing only: emergency recall.", table: foundationsTable)

            static let toolLeashTitle = String(localized: "Collar & leash", table: foundationsTable)
            static let toolLeashDesc = String(localized: "A simple flat collar and a 2m fixed-length leash. No retractables.", table: foundationsTable)

            static let toolSpaceTitle = String(localized: "A quiet space", table: foundationsTable)
            static let toolSpaceDesc = String(localized: "Start where there are no distractions. Your living room is perfect.", table: foundationsTable)

            static let toolkitClosing = String(localized: "Each skill will walk you through the specifics. For now, just have these ready.", table: foundationsTable)

            // Page 6: Let's Begin
            static let beginTitle = String(localized: "Let's begin", table: foundationsTable)
            static let beginHeading = String(localized: "You're about to build something incredible.", table: foundationsTable)
            static let beginPara1 = String(localized: "A sit that happens with a flick of your hand. A recall that cuts through any distraction. A dog who looks to you for guidance, trusts your cues, and wants to get it right.", table: foundationsTable)
            static let beginPara2 = String(localized: "This isn't about obedience. It's about communication. Partnership. A relationship built on mutual understanding.", table: foundationsTable)
            static let beginHighlight = String(localized: "Your dog is ready.", table: foundationsTable)
            static let beginClosing = String(localized: "Let's teach you how to teach them.", table: foundationsTable)
        }

        // MARK: - Module 2: How Dogs Learn

        enum HowDogsLearn {
            // Page 1: Two Ways
            static let twoWaysTitle = String(localized: "Two Ways Dogs Learn", table: foundationsTable)
            static let twoWaysIntro = String(localized: "You've now tried a few skills. Let's talk about why they work.", table: foundationsTable)
            static let twoWaysPara = String(localized: "There are two approaches to training, and you've experienced both:", table: foundationsTable)

            static let operantTitle = String(localized: "Operant (Passive Training)", table: foundationsTable)
            static let operantDesc = String(localized: "You do nothing. Hands behind your back. You wait. When the dog happens to do what you want, you mark and reward. The dog figures it out themselves.", table: foundationsTable)
            static let operantExample = String(localized: "Example: \"Watch Me\" — you wait silently until they glance at your face. Click. Treat.", table: foundationsTable)

            static let classicalTitle = String(localized: "Classical (Active Training)", table: foundationsTable)
            static let classicalDesc = String(localized: "You guide the dog with a treat lure. The luring motion becomes the hand signal.", table: foundationsTable)
            static let classicalExample = String(localized: "Example: \"Sit\" — treat on nose, move up and back, dog sits. Click. Treat.", table: foundationsTable)

            static let whenToUseTitle = String(localized: "When to use which?", table: foundationsTable)
            static let whenOperant = String(localized: "Operant: great for natural behaviors (eye contact, settling, calm)", table: foundationsTable)
            static let whenClassical = String(localized: "Classical: great for positions (sit, down, heel)", table: foundationsTable)
            static let whenMix = String(localized: "Sometimes you'll mix them. If luring isn't working, switch to shaping. Dogs are individuals.", table: foundationsTable)

            // Page 2: The Word Trap (Quiz)
            static let wordTrapTitle = String(localized: "The Word Trap", table: foundationsTable)
            static let wordTrapQuizQuestion = String(localized: "Your dog isn't sitting. You say \"sit\" louder and more insistently: \"Sit. Sit. SIT!\" What is your dog learning?", table: foundationsTable)
            static let wordTrapOptionA = String(localized: "That they should sit faster", table: foundationsTable)
            static let wordTrapOptionB = String(localized: "That the command is \"sit-sit-SIT-with-anger\"", table: foundationsTable)
            static let wordTrapOptionC = String(localized: "That you're frustrated (but nothing about sitting)", table: foundationsTable)
            static let wordTrapExplanation = String(localized: "Your dog doesn't understand that you're repeating yourself. They think \"sit-sit-SIT\" is one long command. And they're learning that the cue involves you sounding increasingly upset.\n\nThis is why we use hand signals first. Hand signals can't be \"shouted.\" You can't make them louder or angrier. They stay consistent.\n\nAdd words only after the hand signal is rock solid. One word. Once. Then wait.", table: foundationsTable)

            // Page 3: Step-Back Rule
            static let stepBackTitle = String(localized: "The Step-Back Rule", table: foundationsTable)
            static let stepBackHighlight = String(localized: "This might be the most important thing you learn:", table: foundationsTable)
            static let stepBackRule = String(localized: "If your dog is struggling, it's not their fault. It's too hard.", table: foundationsTable)
            static let stepBackAction = String(localized: "Go back a step. Make it easier. Success builds confidence. Frustration kills learning.", table: foundationsTable)

            static let signsTitle = String(localized: "Signs your dog is struggling:", table: foundationsTable)
            static let sign1 = String(localized: "Sniffing the ground (displacement behavior)", table: foundationsTable)
            static let sign2 = String(localized: "Turning away from you", table: foundationsTable)
            static let sign3 = String(localized: "Trying random behaviors rapidly", table: foundationsTable)
            static let sign4 = String(localized: "Leaving the training area", table: foundationsTable)

            static let stepBackResponse = String(localized: "When you see this, don't push. Don't repeat louder. Don't get frustrated yourself.", table: foundationsTable)
            static let stepBackClosing = String(localized: "Just make it easier. Go back to a step that works. End on a success.", table: foundationsTable)
            static let stepBackGoal = String(localized: "The goal is not to challenge your dog. The goal is to set them up for wins.", table: foundationsTable)

            // Page 4: Session Structure
            static let sessionTitle = String(localized: "Session Structure", table: foundationsTable)

            static let howLongTitle = String(localized: "How long should you train?", table: foundationsTable)
            static let howLongAnswer = String(localized: "2-5 minutes. That's it.", table: foundationsTable)
            static let howLongWhy = String(localized: "Puppy brains tire fast. After 5 minutes, you're not teaching — you're frustrating both of you.", table: foundationsTable)

            static let howOftenTitle = String(localized: "How often?", table: foundationsTable)
            static let howOftenAnswer = String(localized: "2-3 short sessions per day beats one long one. Spaced practice is more effective than cramming.", table: foundationsTable)

            static let howEndTitle = String(localized: "How to end?", table: foundationsTable)
            static let howEndAnswer = String(localized: "Always on a win. If things are going badly, make it easy enough that they succeed at something, then stop.", table: foundationsTable)

            static let walksTitle = String(localized: "What about walks?", table: foundationsTable)
            static let walksAnswer = String(localized: "Don't train during walks. Walks are for sniffing, exploring, experiencing the world. Training happens in short, focused sessions — ideally at your doorstep or in your living room.", table: foundationsTable)
        }

        // MARK: - Module 3: Taking It Further

        enum TakingFurther {
            // Page 1: The 3 D's
            static let threeDsTitle = String(localized: "The 3 D's", table: foundationsTable)
            static let threeDsIntro = String(localized: "Your dog sits perfectly in the living room. Now what?", table: foundationsTable)
            static let threeDsPara = String(localized: "Real-world reliability comes from the 3 D's:", table: foundationsTable)

            static let durationTitle = String(localized: "Duration", table: foundationsTable)
            static let durationDesc = String(localized: "How long can they hold it?", table: foundationsTable)
            static let distanceTitle = String(localized: "Distance", table: foundationsTable)
            static let distanceDesc = String(localized: "How far can you be?", table: foundationsTable)
            static let distractionTitle = String(localized: "Distraction", table: foundationsTable)
            static let distractionDesc = String(localized: "Can they do it with things happening around them?", table: foundationsTable)

            static let goldenRule = String(localized: "The golden rule: Only work on ONE at a time.", table: foundationsTable)

            static let threeDsQuizQuestion = String(localized: "You're adding distractions (a bouncing ball nearby). What should you do to duration and distance?", table: foundationsTable)
            static let threeDsOptionA = String(localized: "Keep them the same", table: foundationsTable)
            static let threeDsOptionB = String(localized: "Increase them too — challenge the dog", table: foundationsTable)
            static let threeDsOptionC = String(localized: "Make them easier", table: foundationsTable)
            static let threeDsExplanation = String(localized: "When one variable gets harder, the others get easier. Training at the park for the first time? Keep duration short, stay close, and expect less. You're not testing them — you're teaching them that this skill works here too.", table: foundationsTable)

            // Page 2: Why Dogs Forget
            static let forgetTitle = String(localized: "Why Dogs \"Forget\"", table: foundationsTable)
            static let forgetScenario = String(localized: "You've trained \"down\" for months. Your dog does it perfectly. Then you try it at the beach and... nothing.", table: foundationsTable)
            static let forgetHighlight = String(localized: "This is normal. This is biology.", table: foundationsTable)
            static let forgetPara1 = String(localized: "Dogs don't generalize well. To them, \"down in the living room\" and \"down at the beach\" are genuinely different skills. The smells are different. The surface is different. The distractions are different.", table: foundationsTable)
            static let forgetPara2 = String(localized: "A dog who lies down perfectly on carpet may refuse on wet grass because it feels strange. A dog who sits instantly at home may act confused in a busy park.", table: foundationsTable)
            static let forgetReassure = String(localized: "This isn't failure. This is how learning works.", table: foundationsTable)

            static let solutionTitle = String(localized: "The solution?", table: foundationsTable)
            static let solutionPara = String(localized: "Go back to step 1 in the new environment. Lure them down. Click. Treat. Rebuild. It'll go faster this time — but you do need to rebuild.", table: foundationsTable)

            static let progressionTitle = String(localized: "Environment progression:", table: foundationsTable)
            static let progression1 = String(localized: "Living room (no distractions)", table: foundationsTable)
            static let progression2 = String(localized: "Kitchen", table: foundationsTable)
            static let progression3 = String(localized: "Garden/doorstep", table: foundationsTable)
            static let progression4 = String(localized: "Quiet street", table: foundationsTable)
            static let progression5 = String(localized: "Busier street", table: foundationsTable)
            static let progression6 = String(localized: "Park", table: foundationsTable)
            static let progression7 = String(localized: "Beach/busy areas", table: foundationsTable)

            static let progressionRule = String(localized: "Only move up when the previous environment is solid.", table: foundationsTable)

            // Page 3: Variable Rewards
            static let variableTitle = String(localized: "Variable Rewards", table: foundationsTable)
            static let variableIntro = String(localized: "Here's a fascinating principle from behavioral psychology:", table: foundationsTable)
            static let variablePara1 = String(localized: "If a behavior is rewarded every time, and then the rewards stop, the behavior disappears quickly.", table: foundationsTable)
            static let variablePara2 = String(localized: "But if a behavior is rewarded sometimes — unpredictably — it persists almost forever.", table: foundationsTable)
            static let variableHighlight = String(localized: "This is called the slot machine effect.", table: foundationsTable)
            static let variablePara3 = String(localized: "Not knowing when the next reward comes keeps the behavior strong and eager.", table: foundationsTable)

            static let variableMeansTitle = String(localized: "What this means for you:", table: foundationsTable)
            static let variableMeans = String(localized: "Once a skill is solid (8 out of 10 times in multiple environments), start varying the rewards:", table: foundationsTable)
            static let variableOption1 = String(localized: "Sometimes treat", table: foundationsTable)
            static let variableOption2 = String(localized: "Sometimes just praise", table: foundationsTable)
            static let variableOption3 = String(localized: "Sometimes a bigger treat (jackpot!)", table: foundationsTable)
            static let variableWarning = String(localized: "But never stop rewarding entirely. Variable doesn't mean zero. Throughout your dog's life, behaviors that get rewarded persist. Behaviors that don't, fade.", table: foundationsTable)

            // Page 4: Adolescent Regression
            static let adolescentTitle = String(localized: "The Adolescent Regression", table: foundationsTable)
            static let adolescentWarning = String(localized: "A warning for the road ahead:", table: foundationsTable)
            static let adolescentPara1 = String(localized: "Between 6-18 months, your dog will likely \"forget\" things they knew perfectly as a puppy.", table: foundationsTable)
            static let adolescentPara2 = String(localized: "They'll ignore recalls. Blow off sits. Act like they've never heard their name.", table: foundationsTable)
            static let adolescentHighlight = String(localized: "This is not failure. This is adolescence.", table: foundationsTable)
            static let adolescentPara3 = String(localized: "Their brain is rewiring. Hormones are surging. Independence is asserting itself. It's the dog equivalent of a teenager rolling their eyes at you.", table: foundationsTable)

            static let whatToDoTitle = String(localized: "What to do:", table: foundationsTable)
            static let whatToDo1 = String(localized: "Stay patient. Stay consistent.", table: foundationsTable)
            static let whatToDo2 = String(localized: "Go back to basics. Refresh skills from step 1.", table: foundationsTable)
            static let whatToDo3 = String(localized: "Don't take it personally.", table: foundationsTable)
            static let adolescentClosing = String(localized: "It passes. The foundation you've built will return — often stronger than before.", table: foundationsTable)
        }
    }
}
