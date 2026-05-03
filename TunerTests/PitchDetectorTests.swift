import XCTest
@testable import Tuner

final class PitchDetectorTests: XCTestCase {
    let detector = PitchDetector()

    func testDetect440Hz() {
        let buffer = TestHelpers.generateSineWave(frequency: 440)
        let result = detector.detectPitch(in: buffer)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.frequency, 440, accuracy: 2.0)
        XCTAssertGreaterThan(result!.confidence, 0.5)
    }

    func testDetectMiddleC() {
        let buffer = TestHelpers.generateSineWave(frequency: 261.63)
        let result = detector.detectPitch(in: buffer)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.frequency, 261.63, accuracy: 2.0)
    }

    func testDetectLowE2() {
        let buffer = TestHelpers.generateSineWave(frequency: 82.41)
        let result = detector.detectPitch(in: buffer)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.frequency, 82.41, accuracy: 3.0)
    }

    func testDetectHighA5() {
        let buffer = TestHelpers.generateSineWave(frequency: 880)
        let result = detector.detectPitch(in: buffer)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.frequency, 880, accuracy: 2.0)
    }

    func testSilenceReturnsNil() {
        let buffer = TestHelpers.generateSilence()
        let result = detector.detectPitch(in: buffer)
        XCTAssertNil(result)
    }

    func testLowAmplitudeNoiseReturnsNil() {
        let buffer = (0..<4096).map { _ in Float.random(in: -0.001...0.001) }
        let result = detector.detectPitch(in: buffer)
        XCTAssertNil(result)
    }

    func testConfidenceIsHighForCleanSignal() {
        let buffer = TestHelpers.generateSineWave(frequency: 440)
        let result = detector.detectPitch(in: buffer)
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.confidence, 0.8)
    }
}
