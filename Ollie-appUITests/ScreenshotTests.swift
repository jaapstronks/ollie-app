//
//  ScreenshotTests.swift
//  Ollie-appUITests
//
//  App Store screenshot capture tests for all supported languages.
//  Run with: fastlane screenshots
//
//  Note: The app automatically creates a test profile and skips onboarding
//  when launched with --uitesting flag.
//

import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Capture Test

    /// Main test that captures the Today view screenshot
    func testCaptureAllScreenshots() throws {
        // Wait for the tab bar to appear (indicates main app is loaded)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear - app should skip onboarding in UI testing mode")

        // Give the UI time to fully render
        Thread.sleep(forTimeInterval: 2.0)

        // Capture Today view
        snapshot("01_Today")
    }
}
