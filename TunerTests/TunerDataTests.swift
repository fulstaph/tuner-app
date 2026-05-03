import XCTest
@testable import Tuner

final class TunerDataTests: XCTestCase {
    func testDefaultValues() {
        let data = TunerData()
        XCTAssertEqual(data.frequency, 0)
        XCTAssertEqual(data.note, "--")
        XCTAssertEqual(data.octave, 0)
        XCTAssertEqual(data.cents, 0)
        XCTAssertFalse(data.isActive)
    }

    func testCustomInitialization() {
        let data = TunerData(frequency: 440.0, note: "A", octave: 4, cents: 3.5, isActive: true)
        XCTAssertEqual(data.frequency, 440.0)
        XCTAssertEqual(data.note, "A")
        XCTAssertEqual(data.octave, 4)
        XCTAssertEqual(data.cents, 3.5)
        XCTAssertTrue(data.isActive)
    }

    func testEquatable() {
        let a = TunerData(frequency: 440, note: "A", octave: 4, cents: 0, isActive: true)
        let b = TunerData(frequency: 440, note: "A", octave: 4, cents: 0, isActive: true)
        XCTAssertEqual(a, b)
    }
}

final class InstrumentPresetTests: XCTestCase {
    func testConcertShift() { XCTAssertEqual(InstrumentPreset.concert.semitoneShift, 0) }
    func testBFlatShift() { XCTAssertEqual(InstrumentPreset.bFlat.semitoneShift, 2) }
    func testEFlatShift() { XCTAssertEqual(InstrumentPreset.eFlat.semitoneShift, -3) }
    func testFShift() { XCTAssertEqual(InstrumentPreset.f.semitoneShift, 7) }
    func testAShift() { XCTAssertEqual(InstrumentPreset.a.semitoneShift, 3) }
    func testAllPresetsHaveDisplayName() {
        for preset in InstrumentPreset.allCases { XCTAssertFalse(preset.displayName.isEmpty) }
    }
}

final class TunerStyleTests: XCTestCase {
    func testAllStylesHaveDisplayName() {
        for style in TunerStyle.allCases { XCTAssertFalse(style.displayName.isEmpty) }
    }
    func testRawValues() {
        XCTAssertEqual(TunerStyle.needle.rawValue, "needle")
        XCTAssertEqual(TunerStyle.linearBar.rawValue, "linearBar")
        XCTAssertEqual(TunerStyle.minimalist.rawValue, "minimalist")
    }
}
