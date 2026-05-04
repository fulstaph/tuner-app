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
        XCTAssertTrue(app.staticTexts["Tuner Display"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Instrument"].exists)

        // In iOS 26, Form Pickers render as buttons with combined label
        XCTAssertTrue(app.buttons["Tuner Style, Needle Gauge"].exists)
        // Transposition picker value depends on stored UserDefaults — match by prefix
        let transpositionButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Transposition,'")
        ).firstMatch
        XCTAssertTrue(transpositionButton.exists)

        // Reference pitch reset button
        XCTAssertTrue(app.buttons["Reset to 440"].exists)

        // Reference pitch slider
        XCTAssertTrue(app.sliders.firstMatch.exists)

        // Metronome Display section
        XCTAssertTrue(app.staticTexts["Metronome Display"].exists)
    }

    func testTabBarShowsTunerAndMetronome() {
        XCTAssertTrue(app.tabBars.buttons["Tuner"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["Metronome"].exists)
    }

    func testMetronomeTabShowsControls() {
        let metronomeTab = app.tabBars.buttons["Metronome"]
        XCTAssertTrue(metronomeTab.waitForExistence(timeout: 3))
        metronomeTab.tap()

        // Play button (SF Symbol "play.fill") should exist on the metronome view
        XCTAssertTrue(app.buttons["play.fill"].waitForExistence(timeout: 3))

        // TAP button for tap tempo
        XCTAssertTrue(app.buttons["TAP"].exists)
    }

    func testSettingsShowsMetronomeStylePicker() {
        let settingsButton = app.buttons["gearshape"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        // Metronome Display section with style picker (default style is Minimal)
        XCTAssertTrue(app.staticTexts["Metronome Display"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Metronome Style, Minimal"].exists)
    }
}
