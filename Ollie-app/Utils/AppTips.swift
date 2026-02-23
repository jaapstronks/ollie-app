//
//  AppTips.swift
//  Ollie-app
//
//  TipKit integration for contextual feature discovery

import TipKit

// MARK: - Tips Configuration

/// Configure TipKit for the app
func configureTips() {
    try? Tips.configure([
        .displayFrequency(.immediate),
        .datastoreLocation(.applicationDefault)
    ])
}

// MARK: - Tips

/// Tip: Swipe left to delete an event
struct SwipeToDeleteTip: Tip {
    var title: Text {
        Text(Strings.Tips.swipeToDeleteTitle)
    }

    var message: Text? {
        Text(Strings.Tips.swipeToDeleteMessage)
    }

    var image: Image? {
        Image(systemName: "hand.draw")
    }
}

/// Tip: Tap and hold for more options
struct LongPressOptionsTip: Tip {
    var title: Text {
        Text(Strings.Tips.longPressTitle)
    }

    var message: Text? {
        Text(Strings.Tips.longPressMessage)
    }

    var image: Image? {
        Image(systemName: "hand.tap")
    }
}

/// Tip: Set up meal reminders
struct MealRemindersTip: Tip {
    var title: Text {
        Text(Strings.Tips.mealRemindersTitle)
    }

    var message: Text? {
        Text(Strings.Tips.mealRemindersMessage)
    }

    var image: Image? {
        Image(systemName: "bell.badge")
    }

    // Only show after user has logged a few meals
    @Parameter
    static var mealCount: Int = 0

    var rules: [Rule] {
        #Rule(Self.$mealCount) { count in
            count >= 3
        }
    }
}

/// Tip: Use quick log bar for fast logging
struct QuickLogBarTip: Tip {
    var title: Text {
        Text(Strings.Tips.quickLogTitle)
    }

    var message: Text? {
        Text(Strings.Tips.quickLogMessage)
    }

    var image: Image? {
        Image(systemName: "bolt")
    }
}

/// Tip: Check stats for patterns
struct StatsPatternsTip: Tip {
    var title: Text {
        Text(Strings.Tips.patternsTitle)
    }

    var message: Text? {
        Text(Strings.Tips.patternsMessage)
    }

    var image: Image? {
        Image(systemName: "chart.bar")
    }

    // Show after user has logged enough events
    @Parameter
    static var eventCount: Int = 0

    var rules: [Rule] {
        #Rule(Self.$eventCount) { count in
            count >= 10
        }
    }
}

/// Tip: Potty prediction based on patterns
struct PottyPredictionTip: Tip {
    var title: Text {
        Text(Strings.Tips.predictionTitle)
    }

    var message: Text? {
        Text(Strings.Tips.predictionMessage)
    }

    var image: Image? {
        Image(systemName: "sparkles")
    }

    // Show after user has a streak going
    @Parameter
    static var hasStreak: Bool = false

    var rules: [Rule] {
        #Rule(Self.$hasStreak) { $0 == true }
    }
}
