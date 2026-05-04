import XCTest
@testable import Tuner

final class MetronomeModelTests: XCTestCase {
    func testTimeSignatureBeatsPerMeasure() {
        XCTAssertEqual(TimeSignature.twoFour.beatsPerMeasure, 2)
        XCTAssertEqual(TimeSignature.threeFour.beatsPerMeasure, 3)
        XCTAssertEqual(TimeSignature.fourFour.beatsPerMeasure, 4)
        XCTAssertEqual(TimeSignature.fiveFour.beatsPerMeasure, 5)
        XCTAssertEqual(TimeSignature.sixEight.beatsPerMeasure, 6)
        XCTAssertEqual(TimeSignature.sevenEight.beatsPerMeasure, 7)
    }

    func testTimeSignatureRawValues() {
        XCTAssertEqual(TimeSignature.fourFour.rawValue, "4/4")
        XCTAssertEqual(TimeSignature.sevenEight.rawValue, "7/8")
    }

    func testTimeSignatureCaseIterable() {
        XCTAssertEqual(TimeSignature.allCases.count, 6)
    }

    func testMetronomeStyleDisplayName() {
        XCTAssertEqual(MetronomeStyle.minimal.displayName, "Minimal")
        XCTAssertEqual(MetronomeStyle.circularGauge.displayName, "Circular Gauge")
    }

    func testMetronomeStyleCaseIterable() {
        XCTAssertEqual(MetronomeStyle.allCases.count, 2)
    }
}
