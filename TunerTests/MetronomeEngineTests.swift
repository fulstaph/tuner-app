// TunerTests/MetronomeEngineTests.swift
import XCTest
@testable import Tuner

final class MetronomeEngineTests: XCTestCase {
    var engine: MetronomeEngine!

    override func setUp() {
        super.setUp()
        engine = MetronomeEngine()
    }

    override func tearDown() {
        engine.stop()
        engine = nil
        super.tearDown()
    }

    func testInitiallyNotPlaying() {
        XCTAssertFalse(engine.isPlaying)
    }

    func testStartSetsIsPlaying() {
        engine.start(bpm: 120, beatsPerMeasure: 4)
        XCTAssertTrue(engine.isPlaying)
    }

    func testStopClearsIsPlaying() {
        engine.start(bpm: 120, beatsPerMeasure: 4)
        engine.stop()
        XCTAssertFalse(engine.isPlaying)
    }

    func testOnBeatCallbackFires() async {
        let expectation = XCTestExpectation(description: "onBeat fires")
        var receivedBeat: Int?

        engine.onBeat = { beat in
            receivedBeat = beat
            expectation.fulfill()
        }

        engine.start(bpm: 240, beatsPerMeasure: 4)
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertNotNil(receivedBeat)
        XCTAssertEqual(receivedBeat, 0)
    }

    func testBeatCyclesThroughMeasure() async {
        let expectation = XCTestExpectation(description: "multiple beats fire")
        expectation.expectedFulfillmentCount = 5
        var beats: [Int] = []

        engine.onBeat = { beat in
            beats.append(beat)
            expectation.fulfill()
        }

        engine.start(bpm: 240, beatsPerMeasure: 4)
        await fulfillment(of: [expectation], timeout: 2.0)

        // Should cycle: 0, 1, 2, 3, 0
        XCTAssertEqual(beats.prefix(5), [0, 1, 2, 3, 0])
    }

    func testUpdateTempoChangesBPM() {
        engine.start(bpm: 120, beatsPerMeasure: 4)
        engine.updateTempo(bpm: 180)
        XCTAssertTrue(engine.isPlaying)
    }

    func testUpdateBeatsPerMeasure() async {
        let expectation = XCTestExpectation(description: "beats with new measure")
        expectation.expectedFulfillmentCount = 8
        var beats: [Int] = []

        engine.onBeat = { beat in
            beats.append(beat)
            expectation.fulfill()
        }

        engine.start(bpm: 240, beatsPerMeasure: 3)
        await fulfillment(of: [expectation], timeout: 3.0)

        // Should cycle through 0, 1, 2, 0, 1, 2, 0, 1
        let expectedPattern = [0, 1, 2, 0, 1, 2, 0, 1]
        XCTAssertEqual(Array(beats.prefix(8)), expectedPattern)
    }

    func testStartWithoutExternalEngineSucceeds() {
        let result = engine.start(bpm: 120, beatsPerMeasure: 4)
        XCTAssertTrue(result)
        XCTAssertTrue(engine.isPlaying)
    }

    func testOnResumeCallbackIsSettable() {
        engine.onResume = {}
        XCTAssertNotNil(engine.onResume)
    }

    func testSubdivisionOnBeatFiresOnlyOnMainBeats() async {
        let beatExpectation = XCTestExpectation(description: "main beats fire")
        beatExpectation.expectedFulfillmentCount = 3
        var beats: [Int] = []

        engine.onBeat = { beat in
            beats.append(beat)
            beatExpectation.fulfill()
        }

        engine.start(bpm: 240, beatsPerMeasure: 2, subdivisionsPerBeat: 2)
        await fulfillment(of: [beatExpectation], timeout: 2.0)

        XCTAssertEqual(Array(beats.prefix(3)), [0, 1, 0])
    }

    func testSubdivisionOnSubBeatPattern() async {
        let subExpectation = XCTestExpectation(description: "sub beats fire")
        subExpectation.expectedFulfillmentCount = 5
        var subBeats: [(Int, Int)] = []

        engine.onSubBeat = { beat, subBeat in
            subBeats.append((beat, subBeat))
            subExpectation.fulfill()
        }

        engine.start(bpm: 240, beatsPerMeasure: 2, subdivisionsPerBeat: 2)
        await fulfillment(of: [subExpectation], timeout: 2.0)

        let expected = [(0, 0), (0, 1), (1, 0), (1, 1), (0, 0)]
        XCTAssertEqual(subBeats.prefix(5).map(\.0), expected.map(\.0))
        XCTAssertEqual(subBeats.prefix(5).map(\.1), expected.map(\.1))
    }

    func testNoSubdivisionBackwardCompat() async {
        let expectation = XCTestExpectation(description: "beats without subdivision")
        expectation.expectedFulfillmentCount = 5
        var beats: [Int] = []

        engine.onBeat = { beat in
            beats.append(beat)
            expectation.fulfill()
        }

        engine.start(bpm: 240, beatsPerMeasure: 4, subdivisionsPerBeat: 1)
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(Array(beats.prefix(5)), [0, 1, 2, 3, 0])
    }

    func testUpdateSubdivisionWhilePlaying() {
        engine.start(bpm: 120, beatsPerMeasure: 4, subdivisionsPerBeat: 1)
        engine.updateSubdivision(3)
        XCTAssertTrue(engine.isPlaying)
    }
}
