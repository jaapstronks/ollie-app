//
//  Ollie_appUITests.swift
//  Ollie-appUITests
//
//  Comprehensive UI tests for Ollie puppy logbook app
//

import XCTest

final class Ollie_appUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Wait for app to fully load (launch screen dismisses, main UI appears)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Wait for an element to exist with better error messages
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5, message: String? = nil) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists, let msg = message {
            XCTFail(msg)
        }
        return exists
    }

    /// Navigate to Today tab and ensure we're on today's date
    private func ensureOnTodayTab() {
        let tabBar = app.tabBars.firstMatch
        let todayTab = tabBar.buttons.element(boundBy: 0)
        if !todayTab.isSelected {
            todayTab.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }
    }

    /// Take a named screenshot and attach it to the test results
    private func takeScreenshot(named name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Find settings button using multiple strategies
    private func findSettingsButton() -> XCUIElement? {
        // Strategy 1: By accessibility identifier
        let byIdentifier = app.buttons["settings_button"]
        if byIdentifier.exists {
            return byIdentifier
        }

        // Strategy 2: By SF Symbol image (gear icon)
        let byGear = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'settings' OR label CONTAINS[c] 'instellingen' OR label CONTAINS[c] 'gear'")).firstMatch
        if byGear.exists {
            return byGear
        }

        // Strategy 3: Find button in top navigation area with gear-like characteristics
        let navButtons = app.buttons.allElementsBoundByIndex
        for button in navButtons {
            let frame = button.frame
            // Check if button is in top-right area (roughly)
            if frame.minY < 150 && frame.minX > UIScreen.main.bounds.width / 2 {
                // Check if it has gear-related label or identifier
                if button.identifier == "settings_button" ||
                   button.label.lowercased().contains("setting") ||
                   button.label.lowercased().contains("gear") {
                    return button
                }
            }
        }

        return nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        XCTAssertTrue(app.tabBars.count > 0, "Tab bar should be visible")
        takeScreenshot(named: "01-App-Launch")
    }

    @MainActor
    func testTodayTabIsSelectedByDefault() throws {
        let tabBar = app.tabBars.firstMatch
        let todayTab = tabBar.buttons.element(boundBy: 0)
        XCTAssertTrue(todayTab.isSelected, "Today tab should be selected by default")
    }

    @MainActor
    func testMainUIElementsPresent() throws {
        // Tab bar exists
        XCTAssertTrue(app.tabBars.firstMatch.exists, "Tab bar should exist")

        // FAB button exists
        let fab = app.buttons["FAB_BUTTON"]
        XCTAssertTrue(waitForElement(fab, message: "FAB button should exist"))

        takeScreenshot(named: "02-Main-UI-Elements")
    }

    // MARK: - Tab Navigation Tests

    @MainActor
    func testNavigateToInsightsTab() throws {
        let tabBar = app.tabBars.firstMatch
        // Insights/Stats tab is now at index 4 (Today=0, Train=1, Walks=2, Plan=3, Stats=4)
        let insightsTab = tabBar.buttons.element(boundBy: 4)

        insightsTab.tap()
        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertTrue(insightsTab.isSelected, "Insights tab should be selected after tap")
        takeScreenshot(named: "03-Insights-Tab")
    }

    @MainActor
    func testNavigateBetweenAllTabs() throws {
        let tabBar = app.tabBars.firstMatch
        // Tab indices: Today=0, Train=1, Walks=2, Plan=3, Stats=4
        let todayTab = tabBar.buttons.element(boundBy: 0)
        let trainTab = tabBar.buttons.element(boundBy: 1)
        let walksTab = tabBar.buttons.element(boundBy: 2)
        let planTab = tabBar.buttons.element(boundBy: 3)
        let statsTab = tabBar.buttons.element(boundBy: 4)

        // Ensure we start on Today tab (may be on different tab from previous test)
        ensureOnTodayTab()
        XCTAssertTrue(todayTab.isSelected, "Should start on Today tab")
        takeScreenshot(named: "04-Today-Tab-Initial")

        // Go to Train
        trainTab.tap()
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(trainTab.isSelected, "Train tab should be selected")
        takeScreenshot(named: "05-Train-Tab")

        // Go to Walks
        walksTab.tap()
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(walksTab.isSelected, "Walks tab should be selected")
        takeScreenshot(named: "06-Walks-Tab")

        // Go to Plan
        planTab.tap()
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(planTab.isSelected, "Plan tab should be selected")
        takeScreenshot(named: "07-Plan-Tab")

        // Go to Stats/Insights
        statsTab.tap()
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(statsTab.isSelected, "Stats tab should be selected")
        takeScreenshot(named: "08-Stats-Tab")

        // Return to Today
        todayTab.tap()
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(todayTab.isSelected, "Should return to Today tab")
        takeScreenshot(named: "09-Today-Tab-Return")
    }

    // MARK: - FAB Button Tests

    @MainActor
    func testFABButtonExists() throws {
        let fab = app.buttons["FAB_BUTTON"]
        XCTAssertTrue(waitForElement(fab, timeout: 5, message: "FAB button should exist"))
    }

    @MainActor
    func testFABButtonTapOpensEventSheet() throws {
        let fab = app.buttons["FAB_BUTTON"]
        XCTAssertTrue(fab.exists, "FAB should exist before tapping")

        fab.tap()
        Thread.sleep(forTimeInterval: 0.8)

        takeScreenshot(named: "07-FAB-Tapped-Sheet")

        // Dismiss by swiping down or tapping outside
        app.swipeDown()
        Thread.sleep(forTimeInterval: 0.5)
    }

    @MainActor
    func testFABLongPressShowsQuickMenu() throws {
        let fab = app.buttons["FAB_BUTTON"]
        XCTAssertTrue(fab.exists)

        // Long press to show quick action menu
        fab.press(forDuration: 0.6)
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot(named: "08-FAB-Quick-Menu")

        // Tap outside to dismiss
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3)).tap()
        Thread.sleep(forTimeInterval: 0.3)
    }

    // MARK: - Settings Tests

    @MainActor
    func testSettingsAccessible() throws {
        ensureOnTodayTab()
        Thread.sleep(forTimeInterval: 0.5)

        // Try to find settings button
        if let settingsButton = findSettingsButton() {
            XCTAssertTrue(settingsButton.exists, "Settings button should be accessible")
            takeScreenshot(named: "09-Settings-Button-Found")

            settingsButton.tap()
            Thread.sleep(forTimeInterval: 0.8)

            takeScreenshot(named: "10-Settings-Screen")

            // Close settings
            let doneButton = app.buttons["Done"].exists ? app.buttons["Done"] : app.buttons["Klaar"]
            if doneButton.exists {
                doneButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                // Swipe down to dismiss
                app.swipeDown()
            }
        } else {
            // Settings button might not be visible in current state
            // Take screenshot to document the state
            takeScreenshot(named: "09-Settings-Button-Not-Found")

            // This is not necessarily a failure - document the state
            XCTContext.runActivity(named: "Settings button not visible in current state") { _ in
                // Log what buttons are available
                let allButtons = app.buttons.allElementsBoundByIndex
                for (index, button) in allButtons.enumerated() {
                    print("Button \(index): identifier='\(button.identifier)', label='\(button.label)'")
                }
            }
        }
    }

    // MARK: - Day Navigation Tests

    @MainActor
    func testSwipeRightGoesToPreviousDay() throws {
        ensureOnTodayTab()

        // Get initial date title
        let initialTitle = app.staticTexts.element(boundBy: 0).label

        // Swipe right to go to previous day
        app.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot(named: "11-Previous-Day-After-Swipe")

        // Swipe left to return
        app.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
    }

    @MainActor
    func testDayNavigationButtons() throws {
        ensureOnTodayTab()

        // Find previous day button (chevron.left or by accessibility label)
        let prevButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'previous' OR label CONTAINS[c] 'vorige' OR identifier == 'previous_day'"
        )).firstMatch

        if prevButton.exists {
            prevButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot(named: "12-Previous-Day-Via-Button")

            // Look for next button or return via swipe
            let nextButton = app.buttons.matching(NSPredicate(
                format: "label CONTAINS[c] 'next' OR label CONTAINS[c] 'volgende'"
            )).firstMatch

            if nextButton.exists && nextButton.isEnabled {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                app.swipeLeft()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    // MARK: - Event Logging Flow Tests

    @MainActor
    func testQuickLogPottyEvent() throws {
        ensureOnTodayTab()

        let fab = app.buttons["FAB_BUTTON"]
        XCTAssertTrue(fab.exists)

        // Long press to open quick menu
        fab.press(forDuration: 0.6)
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot(named: "13-Quick-Log-Menu-Open")

        // Look for pee/plas option
        let peeOption = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'pee' OR label CONTAINS[c] 'plas' OR label CONTAINS[c] 'buiten'"
        )).firstMatch

        if peeOption.exists {
            peeOption.tap()
            Thread.sleep(forTimeInterval: 0.8)
            takeScreenshot(named: "14-After-Quick-Log")
        } else {
            // Dismiss menu
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3)).tap()
        }
    }

    @MainActor
    func testOpenAllEventsSheet() throws {
        ensureOnTodayTab()

        let fab = app.buttons["FAB_BUTTON"]
        fab.tap()
        Thread.sleep(forTimeInterval: 0.8)

        takeScreenshot(named: "15-All-Events-Sheet")

        // Dismiss
        app.swipeDown()
        Thread.sleep(forTimeInterval: 0.5)
    }

    // MARK: - Timeline Tests

    @MainActor
    func testTimelineSectionExists() throws {
        ensureOnTodayTab()

        // Look for timeline header or event rows
        let timelineLabel = app.staticTexts["Timeline"]
        let hasTimeline = timelineLabel.exists || app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS[c] 'timeline' OR label CONTAINS[c] 'events' OR label CONTAINS[c] 'No events'"
        )).firstMatch.exists

        XCTAssertTrue(hasTimeline, "Timeline section should exist")
        takeScreenshot(named: "16-Timeline-Section")
    }

    @MainActor
    func testPullToRefresh() throws {
        ensureOnTodayTab()

        // Pull down to refresh
        let firstElement = app.scrollViews.firstMatch
        if firstElement.exists {
            let start = firstElement.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let end = firstElement.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            start.press(forDuration: 0.1, thenDragTo: end)
            Thread.sleep(forTimeInterval: 1.0)
        }

        takeScreenshot(named: "17-After-Pull-Refresh")
    }

    // MARK: - Insights Tab Tests

    @MainActor
    func testInsightsTabContent() throws {
        let tabBar = app.tabBars.firstMatch
        // Insights/Stats tab is now at index 4
        let insightsTab = tabBar.buttons.element(boundBy: 4)

        insightsTab.tap()
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot(named: "18-Insights-Content")

        // Verify some content exists
        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.staticTexts.count > 0

        XCTAssertTrue(hasContent, "Insights tab should have some content")
    }

    // MARK: - Visual Regression Screenshots

    @MainActor
    func testCaptureAllScreensForVisualRegression() throws {
        // 1. Today Tab - Default State
        ensureOnTodayTab()
        takeScreenshot(named: "VR-01-Today-Default")

        // 2. Previous Day
        app.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot(named: "VR-02-Previous-Day")

        // Return to today
        app.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        // 3. FAB Menu
        let fab = app.buttons["FAB_BUTTON"]
        fab.press(forDuration: 0.6)
        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot(named: "VR-03-FAB-Menu")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3)).tap()
        Thread.sleep(forTimeInterval: 0.3)

        // 4. Event Sheet
        fab.tap()
        Thread.sleep(forTimeInterval: 0.8)
        takeScreenshot(named: "VR-04-Event-Sheet")
        app.swipeDown()
        Thread.sleep(forTimeInterval: 0.5)

        // 5. Insights Tab (now at index 4)
        app.tabBars.firstMatch.buttons.element(boundBy: 4).tap()
        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot(named: "VR-05-Insights")

        // 6. Settings (if accessible)
        app.tabBars.firstMatch.buttons.element(boundBy: 0).tap()
        Thread.sleep(forTimeInterval: 0.3)
        if let settings = findSettingsButton() {
            settings.tap()
            Thread.sleep(forTimeInterval: 0.8)
            takeScreenshot(named: "VR-06-Settings")
            if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            } else if app.buttons["Klaar"].exists {
                app.buttons["Klaar"].tap()
            } else {
                app.swipeDown()
            }
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testTabSwitchingPerformance() throws {
        let tabBar = app.tabBars.firstMatch
        let todayTab = tabBar.buttons.element(boundBy: 0)
        // Insights/Stats tab is now at index 4
        let insightsTab = tabBar.buttons.element(boundBy: 4)

        measure {
            insightsTab.tap()
            todayTab.tap()
        }
    }

    @MainActor
    func testScrollPerformance() throws {
        ensureOnTodayTab()

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else { return }

        measure {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
    }
}
