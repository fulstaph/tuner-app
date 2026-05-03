import XCTest

final class TunerUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }

    func testAppLaunches() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testSettingsOpensAndCloses() {
        let settingsButton = app.buttons["gearshape"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))

        app.buttons["Done"].tap()
        XCTAssertFalse(app.navigationBars["Settings"].exists)
    }

    func testSettingsContainsExpectedControls() {
        let settingsButton = app.buttons["gearshape"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()

        // Wait for sheet and Form to fully render (iOS 26 sheet presentation can be slow)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        // Section headers are static texts
        XCTAssertTrue(app.staticTexts["Display"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Instrument"].exists)

        // In iOS 26, Form Pickers render as buttons with combined label
        XCTAssertTrue(app.buttons["Tuner Style, Needle Gauge"].exists)
        XCTAssertTrue(app.buttons["Transposition, B\u{266D} (Clarinet, Trumpet)"].exists)

        // Reference pitch reset button
        XCTAssertTrue(app.buttons["Reset to 440"].exists)

        // Reference pitch slider
        XCTAssertTrue(app.sliders.firstMatch.exists)
    }
}
