import XCTest
@testable import Tuner

final class NoteMapperTests: XCTestCase {

    func testA4at440Hz() {
        let result = NoteMapper.map(frequency: 440.0)
        XCTAssertEqual(result.note, "A")
        XCTAssertEqual(result.octave, 4)
        XCTAssertEqual(result.cents, 0, accuracy: 0.1)
        XCTAssertTrue(result.isActive)
    }

    func testMiddleC() {
        let result = NoteMapper.map(frequency: 261.63)
        XCTAssertEqual(result.note, "C")
        XCTAssertEqual(result.octave, 4)
        XCTAssertEqual(result.cents, 0, accuracy: 1.0)
    }

    func testE2LowGuitar() {
        let result = NoteMapper.map(frequency: 82.41)
        XCTAssertEqual(result.note, "E")
        XCTAssertEqual(result.octave, 2)
        XCTAssertEqual(result.cents, 0, accuracy: 1.0)
    }

    func testC8High() {
        let result = NoteMapper.map(frequency: 4186.0)
        XCTAssertEqual(result.note, "C")
        XCTAssertEqual(result.octave, 8)
        XCTAssertEqual(result.cents, 0, accuracy: 1.5)
    }

    func testSlightlySharp() {
        let result = NoteMapper.map(frequency: 445.0)
        XCTAssertEqual(result.note, "A")
        XCTAssertEqual(result.octave, 4)
        XCTAssertGreaterThan(result.cents, 0)
        XCTAssertLessThanOrEqual(result.cents, 50)
    }

    func testSlightlyFlat() {
        let result = NoteMapper.map(frequency: 435.0)
        XCTAssertEqual(result.note, "A")
        XCTAssertEqual(result.octave, 4)
        XCTAssertLessThan(result.cents, 0)
        XCTAssertGreaterThanOrEqual(result.cents, -50)
    }

    func testHalfwayBetweenNotes() {
        let halfwayFreq = 440.0 * pow(2.0, 0.5 / 12.0)
        let result = NoteMapper.map(frequency: halfwayFreq)
        XCTAssertEqual(abs(result.cents), 50, accuracy: 1.0)
    }

    func testZeroFrequencyReturnsInactive() {
        let result = NoteMapper.map(frequency: 0)
        XCTAssertFalse(result.isActive)
        XCTAssertEqual(result.note, "--")
    }

    func testNegativeFrequencyReturnsInactive() {
        let result = NoteMapper.map(frequency: -100)
        XCTAssertFalse(result.isActive)
    }

    func testBFlatTransposition() {
        let result = NoteMapper.map(frequency: 466.16, transposition: 2)
        XCTAssertEqual(result.note, "C")
        XCTAssertEqual(result.octave, 5)
    }

    func testEFlatTransposition() {
        let result = NoteMapper.map(frequency: 311.13, transposition: -3)
        XCTAssertEqual(result.note, "C")
    }

    func testFTransposition() {
        let result = NoteMapper.map(frequency: 349.23, transposition: 7)
        XCTAssertEqual(result.note, "C")
    }

    func testConcertPitchNoTransposition() {
        let result = NoteMapper.map(frequency: 440.0, transposition: 0)
        XCTAssertEqual(result.note, "A")
        XCTAssertEqual(result.octave, 4)
    }

    func testReferencePitch442() {
        let result = NoteMapper.map(frequency: 440.0, referencePitch: 442.0)
        XCTAssertEqual(result.note, "A")
        XCTAssertEqual(result.octave, 4)
        XCTAssertLessThan(result.cents, 0)
    }

    func testReferencePitch442Exact() {
        let result = NoteMapper.map(frequency: 442.0, referencePitch: 442.0)
        XCTAssertEqual(result.note, "A")
        XCTAssertEqual(result.cents, 0, accuracy: 0.1)
    }

    func testBaroqueReference415() {
        let result = NoteMapper.map(frequency: 415.0, referencePitch: 415.0)
        XCTAssertEqual(result.note, "A")
        XCTAssertEqual(result.octave, 4)
        XCTAssertEqual(result.cents, 0, accuracy: 0.1)
    }
}
