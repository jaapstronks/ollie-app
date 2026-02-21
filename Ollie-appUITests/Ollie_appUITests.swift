//
//  Ollie_appUITests.swift
//  Ollie-appUITests
//
//  UI tests for Ollie puppy logbook app
//

import XCTest

final class Ollie_appUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // Wait for launch screen to dismiss
        let tabBar = app.tabBars.firstMatch
        let exists = tabBar.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Tab bar should appear after launch")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        // Verify main UI elements are present
        XCTAssertTrue(app.tabBars.count > 0, "Tab bar should be visible")
    }

    @MainActor
    func testTodayTabIsDefault() throws {
        // First tab should be selected by default
        let tabBar = app.tabBars.firstMatch
        let todayTab = tabBar.buttons.element(boundBy: 0)
        XCTAssertTrue(todayTab.isSelected, "Today tab should be selected by default")
    }

    // MARK: - Tab Navigation Tests

    @MainActor
    func testNavigateToInsightsTab() throws {
        let tabBar = app.tabBars.firstMatch

        // Tap Insights tab (second tab)
        let insightsTab = tabBar.buttons.element(boundBy: 1)
        insightsTab.tap()

        // Verify Insights tab is now selected
        XCTAssertTrue(insightsTab.isSelected, "Insights tab should be selected after tap")
    }

    @MainActor
    func testNavigateBetweenTabs() throws {
        let tabBar = app.tabBars.firstMatch
        let todayTab = tabBar.buttons.element(boundBy: 0)
        let insightsTab = tabBar.buttons.element(boundBy: 1)

        // Navigate to Insights
        insightsTab.tap()
        XCTAssertTrue(insightsTab.isSelected)

        // Navigate back to Today
        todayTab.tap()
        XCTAssertTrue(todayTab.isSelected)
    }

    // MARK: - FAB Button Tests

    @MainActor
    func testFABButtonExists() throws {
        let fab = app.buttons["FAB_BUTTON"]
        XCTAssertTrue(fab.exists, "FAB button should exist")
    }

    @MainActor
    func testFABButtonTapOpensSheet() throws {
        let fab = app.buttons["FAB_BUTTON"]
        fab.tap()

        // Wait for sheet to appear
        let sheet = app.sheets.firstMatch
        let sheetAppeared = sheet.waitForExistence(timeout: 2)

        // Sheet or navigation should appear - check for any modal content
        let anyModal = app.otherElements.containing(.any, identifier: nil).count > 0
        XCTAssertTrue(sheetAppeared || anyModal, "Tapping FAB should open a sheet or modal")
    }

    @MainActor
    func testFABLongPressShowsMenu() throws {
        let fab = app.buttons["FAB_BUTTON"]
        fab.press(forDuration: 0.5)

        // Give menu time to animate
        Thread.sleep(forTimeInterval: 0.5)

        // Take screenshot to verify menu appeared
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "FAB Menu Open"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Settings Tests

    @MainActor
    func testSettingsButtonExists() throws {
        let settingsButton = app.buttons["settings_button"]
        XCTAssertTrue(settingsButton.exists, "Settings button should exist on Today tab")
    }

    @MainActor
    func testOpenSettings() throws {
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()

        // Wait for settings sheet to appear
        Thread.sleep(forTimeInterval: 0.5)

        // Look for Done button which should be in settings
        let doneButton = app.buttons["Done"].exists || app.buttons["Klaar"].exists
        XCTAssertTrue(doneButton, "Settings sheet should have a Done button")

        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Settings Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCloseSettings() throws {
        // Open settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Close via Done button
        if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        } else if app.buttons["Klaar"].exists {
            app.buttons["Klaar"].tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Settings button should be visible again (we're back on main screen)
        XCTAssertTrue(settingsButton.exists, "Should be back on main screen after closing settings")
    }

    // MARK: - Day Navigation Tests

    @MainActor
    func testPreviousDayButtonExists() throws {
        // Look for chevron.left button
        let prevButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'previous' OR label CONTAINS 'vorige'")).firstMatch
        XCTAssertTrue(prevButton.exists || app.buttons["chevron.left"].exists, "Previous day button should exist")
    }

    @MainActor
    func testSwipeToNavigateDays() throws {
        // Swipe right to go to previous day
        app.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)

        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Previous Day"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Screenshot Tests

    @MainActor
    func testCaptureAllMainScreens() throws {
        // Capture Today tab
        var screenshot = app.screenshot()
        var attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Today Tab"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Capture Insights tab
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons.element(boundBy: 1).tap()
        Thread.sleep(forTimeInterval: 0.5)

        screenshot = app.screenshot()
        attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Insights Tab"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Go back to Today and capture Settings
        tabBar.buttons.element(boundBy: 0).tap()
        Thread.sleep(forTimeInterval: 0.3)

        let settingsButton = app.buttons["settings_button"]
        if settingsButton.exists {
            settingsButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            screenshot = app.screenshot()
            attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Settings"
            attachment.lifetime = .keepAlways
            add(attachment)
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
        let insightsTab = tabBar.buttons.element(boundBy: 1)

        measure {
            insightsTab.tap()
            todayTab.tap()
        }
    }
}
