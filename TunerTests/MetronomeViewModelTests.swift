// TunerTests/MetronomeViewModelTests.swift
import XCTest
@testable import Tuner

final class MetronomeViewModelTests: XCTestCase {
    var viewModel: MetronomeViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "metronomeBPM")
        UserDefaults.standard.removeObject(forKey: "metronomeTimeSignature")
        UserDefaults.standard.removeObject(forKey: "metronomeStyle")
        UserDefaults.standard.removeObject(forKey: "metronomeSubdivision")
        UserDefaults.standard.removeObject(forKey: "metronomeSubdivision")
        viewModel = MetronomeViewModel()
    }

    @MainActor
    override func tearDown() {
        viewModel.stop()
        viewModel = nil
        super.tearDown()
    }

    @MainActor
    func testDefaultBPM() {
        XCTAssertEqual(viewModel.bpm, 120)
    }

    @MainActor
    func testDefaultTimeSignature() {
        XCTAssertEqual(viewModel.timeSignature, .fourFour)
    }

    @MainActor
    func testDefaultStyle() {
        XCTAssertEqual(viewModel.style, .minimal)
    }

    @MainActor
    func testDefaultNotPlaying() {
        XCTAssertFalse(viewModel.isPlaying)
    }

    @MainActor
    func testSetBPMClampsLow() {
        viewModel.setBPM(10)
        XCTAssertEqual(viewModel.bpm, 40)
    }

    @MainActor
    func testSetBPMClampsHigh() {
        viewModel.setBPM(300)
        XCTAssertEqual(viewModel.bpm, 240)
    }

    @MainActor
    func testSetBPMPersists() {
        viewModel.setBPM(160)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "metronomeBPM"), 160)
    }

    @MainActor
    func testSetTimeSignaturePersists() {
        viewModel.setTimeSignature(.sevenEight)
        let stored = UserDefaults.standard.string(forKey: "metronomeTimeSignature")
        XCTAssertEqual(stored, "7/8")
    }

    @MainActor
    func testToggleStartsPlayback() {
        viewModel.toggle()
        XCTAssertTrue(viewModel.isPlaying)
    }

    @MainActor
    func testToggleStopsPlayback() {
        viewModel.toggle()
        viewModel.toggle()
        XCTAssertFalse(viewModel.isPlaying)
    }

    @MainActor
    func testTapTempoWithFourTaps() {
        // Simulate 4 taps at 120 BPM = 500ms intervals
        let baseTime = Date()
        viewModel.tapTempo(at: baseTime)
        viewModel.tapTempo(at: baseTime.addingTimeInterval(0.5))
        viewModel.tapTempo(at: baseTime.addingTimeInterval(1.0))
        viewModel.tapTempo(at: baseTime.addingTimeInterval(1.5))
        XCTAssertEqual(viewModel.bpm, 120)
    }

    @MainActor
    func testTapTempoResetsAfterTimeout() {
        let baseTime = Date()
        viewModel.tapTempo(at: baseTime)
        viewModel.tapTempo(at: baseTime.addingTimeInterval(0.5))
        // Gap > 2 seconds
        viewModel.tapTempo(at: baseTime.addingTimeInterval(3.0))
        // Only one tap in history now, BPM shouldn't change from single tap
        XCTAssertEqual(viewModel.bpm, 120) // stays at default
    }

    @MainActor
    func testStopSetsNotPlaying() {
        viewModel.toggle() // start
        XCTAssertTrue(viewModel.isPlaying)
        viewModel.stop()
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.currentBeat, 0)
    }

    @MainActor
    func testDefaultSubdivision() {
        XCTAssertEqual(viewModel.subdivision, .none)
    }

    @MainActor
    func testSetSubdivisionPersists() {
        viewModel.setSubdivision(.triplets)
        let stored = UserDefaults.standard.string(forKey: "metronomeSubdivision")
        XCTAssertEqual(stored, "Triplets")
    }

    @MainActor
    func testSubdivisionRestoredFromUserDefaults() {
        UserDefaults.standard.set("Eighths", forKey: "metronomeSubdivision")
        let restored = MetronomeViewModel()
        XCTAssertEqual(restored.subdivision, .eighths)
        restored.stop()
    }
}
