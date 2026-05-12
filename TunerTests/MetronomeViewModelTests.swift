// TunerTests/MetronomeViewModelTests.swift
import SwiftData
import XCTest
@testable import Tuner

final class MetronomeViewModelTests: XCTestCase {
    var viewModel: MetronomeViewModel!
    var container: ModelContainer!
    var context: ModelContext!
    var preset: Preset!

    @MainActor
    override func setUp() {
        super.setUp()
        container = PersistenceTestHelpers.makeInMemoryContainer()
        context = container.mainContext
        preset = PersistenceTestHelpers.seedDefaultPreset(in: context)
        viewModel = MetronomeViewModel(modelContext: context, activePreset: preset)
    }

    @MainActor
    override func tearDown() {
        viewModel.stop()
        viewModel = nil
        preset = nil
        context = nil
        container = nil
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
    func testSetBPMPersistsToActivePreset() {
        viewModel.setBPM(160)
        XCTAssertEqual(preset.bpm, 160)
    }

    @MainActor
    func testSetTimeSignaturePersistsToActivePreset() {
        viewModel.setTimeSignature(.sevenEight)
        XCTAssertEqual(preset.timeSignature, .sevenEight)
        XCTAssertEqual(preset.accentPattern.count, 7)
    }

    @MainActor
    func testSetStylePersistsToActivePreset() {
        viewModel.setStyle(.circularGauge)
        XCTAssertEqual(preset.metronomeStyle, .circularGauge)
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
    func testInitLoadsExistingPresetValues() {
        preset.bpm = 180
        preset.timeSignature = .threeFour
        preset.metronomeStyle = .circularGauge
        try? context.save()

        let restored = MetronomeViewModel(modelContext: context, activePreset: preset)
        XCTAssertEqual(restored.bpm, 180)
        XCTAssertEqual(restored.timeSignature, .threeFour)
        XCTAssertEqual(restored.style, .circularGauge)
    }
}
