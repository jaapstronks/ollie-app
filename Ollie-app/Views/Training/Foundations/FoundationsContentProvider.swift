//
//  FoundationsContentProvider.swift
//  Ollie-app
//
//  Provides the content for all three training foundations modules.
//  Module 1: Getting Started (required)
//  Module 2: How Dogs Learn (after 2-3 skills)
//  Module 3: Taking It Further (before proofing phases)
//

import Foundation

/// Provides content for training foundations modules
enum FoundationsContentProvider {

    // MARK: - Module 1: Getting Started

    static func gettingStartedModule() -> FoundationsModule {
        FoundationsModule(
            id: "gettingStarted",
            name: Strings.Training.Foundations.module1Name,
            subtitle: Strings.Training.Foundations.module1Subtitle,
            icon: "sparkles",
            pages: [
                welcomePage(),
                quizPage(),
                bigSecretPage(),
                harderForYouPage(),
                toolkitPage(),
                letsBeginPage()
            ]
        )
    }

    private static func welcomePage() -> FoundationsPage {
        FoundationsPage(
            id: "welcome",
            title: Strings.Training.Foundations.Welcome.title,
            icon: "sparkles",
            content: [
                .heading(Strings.Training.Foundations.Welcome.heading),
                .paragraph(Strings.Training.Foundations.Welcome.para1),
                .highlight(Strings.Training.Foundations.Welcome.para2),
                .paragraph(Strings.Training.Foundations.Welcome.para3),
                .paragraph(Strings.Training.Foundations.Welcome.para4),
                .note(
                    title: Strings.Training.Foundations.Welcome.noteTitle,
                    text: Strings.Training.Foundations.Welcome.noteText
                )
            ]
        )
    }

    private static func quizPage() -> FoundationsPage {
        FoundationsPage(
            id: "quiz",
            title: Strings.Training.Foundations.Welcome.quizTitle,
            icon: "questionmark.circle",
            content: [
                .paragraph(Strings.Training.Foundations.Welcome.quizIntro),
                .spacer(height: 8),
                .quiz(MiniQuizQuestion(
                    id: "lookAtMe",
                    question: Strings.Training.Foundations.Welcome.quiz1Question,
                    options: [
                        .init(id: "true", text: Strings.Training.Foundations.quizTrue),
                        .init(id: "false", text: Strings.Training.Foundations.quizFalse)
                    ],
                    correctOptionId: "false",
                    explanation: Strings.Training.Foundations.Welcome.quiz1Explanation,
                    explanationTitle: Strings.Training.Foundations.heresWhy
                )),
                .spacer(height: 16),
                .quiz(MiniQuizQuestion(
                    id: "letGo",
                    question: Strings.Training.Foundations.Welcome.quiz2Question,
                    options: [
                        .init(id: "true", text: Strings.Training.Foundations.quizTrue),
                        .init(id: "false", text: Strings.Training.Foundations.quizFalse)
                    ],
                    correctOptionId: "false",
                    explanation: Strings.Training.Foundations.Welcome.quiz2Explanation,
                    explanationTitle: Strings.Training.Foundations.heresWhy
                ))
            ]
        )
    }

    private static func bigSecretPage() -> FoundationsPage {
        FoundationsPage(
            id: "bigSecret",
            title: Strings.Training.Foundations.Welcome.secretTitle,
            icon: "lightbulb",
            content: [
                .heading(Strings.Training.Foundations.Welcome.secretHeading),
                .paragraph(Strings.Training.Foundations.Welcome.secretPara1),
                .highlight(Strings.Training.Foundations.Welcome.secretHighlight),
                .paragraph(Strings.Training.Foundations.Welcome.secretPara2),
                .paragraph(Strings.Training.Foundations.Welcome.secretPara3),
                .numberedList([
                    Strings.Training.Foundations.Welcome.rule1,
                    Strings.Training.Foundations.Welcome.rule2,
                    Strings.Training.Foundations.Welcome.rule3,
                    Strings.Training.Foundations.Welcome.rule4
                ]),
                .paragraph(Strings.Training.Foundations.Welcome.secretClosing)
            ]
        )
    }

    private static func harderForYouPage() -> FoundationsPage {
        FoundationsPage(
            id: "harderForYou",
            title: Strings.Training.Foundations.Welcome.harderTitle,
            icon: "person.fill.questionmark",
            content: [
                .heading(Strings.Training.Foundations.Welcome.harderHeading),
                .paragraph(Strings.Training.Foundations.Welcome.harderPara1),
                .paragraph(Strings.Training.Foundations.Welcome.harderPara2),
                .highlight(Strings.Training.Foundations.Welcome.harderHighlight),
                .paragraph(Strings.Training.Foundations.Welcome.harderPara3),
                .spacer(height: 8),
                .heading(Strings.Training.Foundations.Welcome.counterintuitiveTitle),
                .bulletList([
                    Strings.Training.Foundations.Welcome.counterintuitive1,
                    Strings.Training.Foundations.Welcome.counterintuitive2,
                    Strings.Training.Foundations.Welcome.counterintuitive3
                ]),
                .paragraph(Strings.Training.Foundations.Welcome.harderClosing),
                .highlight(Strings.Training.Foundations.Welcome.harderRemember)
            ]
        )
    }

    private static func toolkitPage() -> FoundationsPage {
        FoundationsPage(
            id: "toolkit",
            title: Strings.Training.Foundations.Welcome.toolkitTitle,
            icon: "tray.full",
            content: [
                .paragraph(Strings.Training.Foundations.Welcome.toolkitIntro),
                .toolItem(
                    icon: "hand.tap.fill",
                    title: Strings.Training.Foundations.Welcome.toolMarkerTitle,
                    description: Strings.Training.Foundations.Welcome.toolMarkerDesc
                ),
                .toolItem(
                    icon: "fork.knife",
                    title: Strings.Training.Foundations.Welcome.toolKibbleTitle,
                    description: Strings.Training.Foundations.Welcome.toolKibbleDesc
                ),
                .toolItem(
                    icon: "dog.fill",
                    title: Strings.Training.Foundations.Welcome.toolLeashTitle,
                    description: Strings.Training.Foundations.Welcome.toolLeashDesc
                ),
                .toolItem(
                    icon: "house.fill",
                    title: Strings.Training.Foundations.Welcome.toolSpaceTitle,
                    description: Strings.Training.Foundations.Welcome.toolSpaceDesc
                ),
                .paragraph(Strings.Training.Foundations.Welcome.toolkitClosing)
            ]
        )
    }

    private static func letsBeginPage() -> FoundationsPage {
        FoundationsPage(
            id: "letsBegin",
            title: Strings.Training.Foundations.Welcome.beginTitle,
            icon: "flag.checkered",
            content: [
                .heading(Strings.Training.Foundations.Welcome.beginHeading),
                .paragraph(Strings.Training.Foundations.Welcome.beginPara1),
                .paragraph(Strings.Training.Foundations.Welcome.beginPara2),
                .highlight(Strings.Training.Foundations.Welcome.beginHighlight),
                .paragraph(Strings.Training.Foundations.Welcome.beginClosing)
            ]
        )
    }

    // MARK: - Module 2: How Dogs Learn

    static func howDogsLearnModule() -> FoundationsModule {
        FoundationsModule(
            id: "howDogsLearn",
            name: Strings.Training.Foundations.module2Name,
            subtitle: Strings.Training.Foundations.module2Subtitle,
            icon: "brain.head.profile",
            pages: [
                twoWaysPage(),
                wordTrapPage(),
                stepBackPage(),
                sessionStructurePage()
            ]
        )
    }

    private static func twoWaysPage() -> FoundationsPage {
        FoundationsPage(
            id: "twoWays",
            title: Strings.Training.Foundations.HowDogsLearn.twoWaysTitle,
            icon: "arrow.triangle.branch",
            content: [
                .paragraph(Strings.Training.Foundations.HowDogsLearn.twoWaysIntro),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.twoWaysPara),
                .spacer(height: 8),
                .heading(Strings.Training.Foundations.HowDogsLearn.operantTitle),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.operantDesc),
                .highlight(Strings.Training.Foundations.HowDogsLearn.operantExample),
                .spacer(height: 12),
                .heading(Strings.Training.Foundations.HowDogsLearn.classicalTitle),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.classicalDesc),
                .highlight(Strings.Training.Foundations.HowDogsLearn.classicalExample),
                .spacer(height: 12),
                .heading(Strings.Training.Foundations.HowDogsLearn.whenToUseTitle),
                .bulletList([
                    Strings.Training.Foundations.HowDogsLearn.whenOperant,
                    Strings.Training.Foundations.HowDogsLearn.whenClassical
                ]),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.whenMix)
            ]
        )
    }

    private static func wordTrapPage() -> FoundationsPage {
        FoundationsPage(
            id: "wordTrap",
            title: Strings.Training.Foundations.HowDogsLearn.wordTrapTitle,
            icon: "exclamationmark.triangle",
            content: [
                .quiz(MiniQuizQuestion(
                    id: "sitLouder",
                    question: Strings.Training.Foundations.HowDogsLearn.wordTrapQuizQuestion,
                    options: [
                        .init(id: "a", text: Strings.Training.Foundations.HowDogsLearn.wordTrapOptionA),
                        .init(id: "b", text: Strings.Training.Foundations.HowDogsLearn.wordTrapOptionB),
                        .init(id: "c", text: Strings.Training.Foundations.HowDogsLearn.wordTrapOptionC)
                    ],
                    correctOptionId: "b",
                    explanation: Strings.Training.Foundations.HowDogsLearn.wordTrapExplanation,
                    explanationTitle: Strings.Training.Foundations.theTruth
                ))
            ]
        )
    }

    private static func stepBackPage() -> FoundationsPage {
        FoundationsPage(
            id: "stepBack",
            title: Strings.Training.Foundations.HowDogsLearn.stepBackTitle,
            icon: "arrow.uturn.backward",
            content: [
                .highlight(Strings.Training.Foundations.HowDogsLearn.stepBackHighlight),
                .heading(Strings.Training.Foundations.HowDogsLearn.stepBackRule),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.stepBackAction),
                .spacer(height: 8),
                .heading(Strings.Training.Foundations.HowDogsLearn.signsTitle),
                .bulletList([
                    Strings.Training.Foundations.HowDogsLearn.sign1,
                    Strings.Training.Foundations.HowDogsLearn.sign2,
                    Strings.Training.Foundations.HowDogsLearn.sign3,
                    Strings.Training.Foundations.HowDogsLearn.sign4
                ]),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.stepBackResponse),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.stepBackClosing),
                .highlight(Strings.Training.Foundations.HowDogsLearn.stepBackGoal)
            ]
        )
    }

    private static func sessionStructurePage() -> FoundationsPage {
        FoundationsPage(
            id: "sessionStructure",
            title: Strings.Training.Foundations.HowDogsLearn.sessionTitle,
            icon: "clock",
            content: [
                .heading(Strings.Training.Foundations.HowDogsLearn.howLongTitle),
                .highlight(Strings.Training.Foundations.HowDogsLearn.howLongAnswer),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.howLongWhy),
                .spacer(height: 12),
                .heading(Strings.Training.Foundations.HowDogsLearn.howOftenTitle),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.howOftenAnswer),
                .spacer(height: 12),
                .heading(Strings.Training.Foundations.HowDogsLearn.howEndTitle),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.howEndAnswer),
                .spacer(height: 12),
                .heading(Strings.Training.Foundations.HowDogsLearn.walksTitle),
                .paragraph(Strings.Training.Foundations.HowDogsLearn.walksAnswer)
            ]
        )
    }

    // MARK: - Module 3: Taking It Further

    static func takingFurtherModule() -> FoundationsModule {
        FoundationsModule(
            id: "takingFurther",
            name: Strings.Training.Foundations.module3Name,
            subtitle: Strings.Training.Foundations.module3Subtitle,
            icon: "arrow.up.right",
            pages: [
                threeDsPage(),
                whyForgetPage(),
                variableRewardsPage(),
                adolescentRegressionPage()
            ]
        )
    }

    private static func threeDsPage() -> FoundationsPage {
        FoundationsPage(
            id: "threeDs",
            title: Strings.Training.Foundations.TakingFurther.threeDsTitle,
            icon: "dial.medium",
            content: [
                .paragraph(Strings.Training.Foundations.TakingFurther.threeDsIntro),
                .paragraph(Strings.Training.Foundations.TakingFurther.threeDsPara),
                .spacer(height: 8),
                .toolItem(
                    icon: "timer",
                    title: Strings.Training.Foundations.TakingFurther.durationTitle,
                    description: Strings.Training.Foundations.TakingFurther.durationDesc
                ),
                .toolItem(
                    icon: "arrow.left.and.right",
                    title: Strings.Training.Foundations.TakingFurther.distanceTitle,
                    description: Strings.Training.Foundations.TakingFurther.distanceDesc
                ),
                .toolItem(
                    icon: "eye",
                    title: Strings.Training.Foundations.TakingFurther.distractionTitle,
                    description: Strings.Training.Foundations.TakingFurther.distractionDesc
                ),
                .spacer(height: 8),
                .highlight(Strings.Training.Foundations.TakingFurther.goldenRule),
                .spacer(height: 12),
                .quiz(MiniQuizQuestion(
                    id: "threeDs",
                    question: Strings.Training.Foundations.TakingFurther.threeDsQuizQuestion,
                    options: [
                        .init(id: "a", text: Strings.Training.Foundations.TakingFurther.threeDsOptionA),
                        .init(id: "b", text: Strings.Training.Foundations.TakingFurther.threeDsOptionB),
                        .init(id: "c", text: Strings.Training.Foundations.TakingFurther.threeDsOptionC)
                    ],
                    correctOptionId: "c",
                    explanation: Strings.Training.Foundations.TakingFurther.threeDsExplanation,
                    explanationTitle: Strings.Training.Foundations.theTruth
                ))
            ]
        )
    }

    private static func whyForgetPage() -> FoundationsPage {
        FoundationsPage(
            id: "whyForget",
            title: Strings.Training.Foundations.TakingFurther.forgetTitle,
            icon: "questionmark.app",
            content: [
                .paragraph(Strings.Training.Foundations.TakingFurther.forgetScenario),
                .highlight(Strings.Training.Foundations.TakingFurther.forgetHighlight),
                .paragraph(Strings.Training.Foundations.TakingFurther.forgetPara1),
                .paragraph(Strings.Training.Foundations.TakingFurther.forgetPara2),
                .highlight(Strings.Training.Foundations.TakingFurther.forgetReassure),
                .spacer(height: 12),
                .heading(Strings.Training.Foundations.TakingFurther.solutionTitle),
                .paragraph(Strings.Training.Foundations.TakingFurther.solutionPara),
                .spacer(height: 8),
                .heading(Strings.Training.Foundations.TakingFurther.progressionTitle),
                .numberedList([
                    Strings.Training.Foundations.TakingFurther.progression1,
                    Strings.Training.Foundations.TakingFurther.progression2,
                    Strings.Training.Foundations.TakingFurther.progression3,
                    Strings.Training.Foundations.TakingFurther.progression4,
                    Strings.Training.Foundations.TakingFurther.progression5,
                    Strings.Training.Foundations.TakingFurther.progression6,
                    Strings.Training.Foundations.TakingFurther.progression7
                ]),
                .paragraph(Strings.Training.Foundations.TakingFurther.progressionRule)
            ]
        )
    }

    private static func variableRewardsPage() -> FoundationsPage {
        FoundationsPage(
            id: "variableRewards",
            title: Strings.Training.Foundations.TakingFurther.variableTitle,
            icon: "dice",
            content: [
                .paragraph(Strings.Training.Foundations.TakingFurther.variableIntro),
                .paragraph(Strings.Training.Foundations.TakingFurther.variablePara1),
                .paragraph(Strings.Training.Foundations.TakingFurther.variablePara2),
                .highlight(Strings.Training.Foundations.TakingFurther.variableHighlight),
                .paragraph(Strings.Training.Foundations.TakingFurther.variablePara3),
                .spacer(height: 8),
                .heading(Strings.Training.Foundations.TakingFurther.variableMeansTitle),
                .paragraph(Strings.Training.Foundations.TakingFurther.variableMeans),
                .bulletList([
                    Strings.Training.Foundations.TakingFurther.variableOption1,
                    Strings.Training.Foundations.TakingFurther.variableOption2,
                    Strings.Training.Foundations.TakingFurther.variableOption3
                ]),
                .note(
                    title: Strings.Training.Foundations.Welcome.noteTitle,
                    text: Strings.Training.Foundations.TakingFurther.variableWarning
                )
            ]
        )
    }

    private static func adolescentRegressionPage() -> FoundationsPage {
        FoundationsPage(
            id: "adolescence",
            title: Strings.Training.Foundations.TakingFurther.adolescentTitle,
            icon: "exclamationmark.bubble",
            content: [
                .highlight(Strings.Training.Foundations.TakingFurther.adolescentWarning),
                .paragraph(Strings.Training.Foundations.TakingFurther.adolescentPara1),
                .paragraph(Strings.Training.Foundations.TakingFurther.adolescentPara2),
                .heading(Strings.Training.Foundations.TakingFurther.adolescentHighlight),
                .paragraph(Strings.Training.Foundations.TakingFurther.adolescentPara3),
                .spacer(height: 12),
                .heading(Strings.Training.Foundations.TakingFurther.whatToDoTitle),
                .bulletList([
                    Strings.Training.Foundations.TakingFurther.whatToDo1,
                    Strings.Training.Foundations.TakingFurther.whatToDo2,
                    Strings.Training.Foundations.TakingFurther.whatToDo3
                ]),
                .highlight(Strings.Training.Foundations.TakingFurther.adolescentClosing)
            ]
        )
    }

    // MARK: - All Modules

    static func allModules() -> [FoundationsModule] {
        [
            gettingStartedModule(),
            howDogsLearnModule(),
            takingFurtherModule()
        ]
    }

    static func module(withId id: String) -> FoundationsModule? {
        allModules().first { $0.id == id }
    }
}
