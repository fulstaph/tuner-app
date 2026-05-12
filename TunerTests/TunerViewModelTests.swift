import SwiftData
import XCTest
@testable import Tuner

final class TunerViewModelTests: XCTestCase {
    var mockEngine: MockAudioEngine!
    var viewModel: TunerViewModel!
    var container: ModelContainer!
    var context: ModelContext!
    var preset: Preset!

    @MainActor
    override func setUp() {
        super.setUp()
        container = PersistenceTestHelpers.makeInMemoryContainer()
        context = container.mainContext
        preset = PersistenceTestHelpers.seedDefaultPreset(in: context)
        mockEngine = MockAudioEngine()
        viewModel = TunerViewModel(
            audioEngine: mockEngine,
            modelContext: context,
            activePreset: preset
        )
    }

    @MainActor
    override func tearDown() {
        viewModel = nil
        mockEngine = nil
        preset = nil
        context = nil
        container = nil
        super.tearDown()
    }

    @MainActor
    func testStartCallsAudioEngine() {
        viewModel.start()
        XCTAssertTrue(mockEngine.didStart)
    }

    @MainActor
    func testStopCallsAudioEngine() {
        viewModel.start()
        viewModel.stop()
        XCTAssertTrue(mockEngine.didStop)
    }

    @MainActor
    func testProcesses440HzBuffer() async {
        viewModel.start()
        let buffer = TestHelpers.generateSineWave(frequency: 440)
        for _ in 0..<3 {
            mockEngine.simulateBuffer(buffer)
            try? await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertTrue(viewModel.tunerData.isActive)
        XCTAssertEqual(viewModel.tunerData.note, "A")
        XCTAssertEqual(viewModel.tunerData.octave, 4)
    }

    @MainActor
    func testSilenceProducesInactiveState() async {
        viewModel.start()
        let buffer = TestHelpers.generateSilence()
        mockEngine.simulateBuffer(buffer)
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(viewModel.tunerData.isActive)
    }

    @MainActor
    func testDefaultReferencePitch() {
        XCTAssertEqual(viewModel.referencePitch, 440.0)
    }

    @MainActor
    func testDefaultInstrumentPreset() {
        XCTAssertEqual(viewModel.instrumentPreset, .concert)
    }

    @MainActor
    func testDefaultTunerStyle() {
        XCTAssertEqual(viewModel.tunerStyle, .needle)
    }

    @MainActor
    func testTranspositionAffectsDisplayedNote() async {
        viewModel.instrumentPreset = .bFlat
        viewModel.start()
        let buffer = TestHelpers.generateSineWave(frequency: 466.16)
        for _ in 0..<3 {
            mockEngine.simulateBuffer(buffer)
            try? await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertEqual(viewModel.tunerData.note, "C")
    }

    @MainActor
    func testReferencePitchAffectsCents() async {
        viewModel.referencePitch = 442.0
        viewModel.start()
        let buffer = TestHelpers.generateSineWave(frequency: 440)
        for _ in 0..<3 {
            mockEngine.simulateBuffer(buffer)
            try? await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertTrue(viewModel.tunerData.isActive)
        XCTAssertLessThan(viewModel.tunerData.cents, 0)
    }

    @MainActor
    func testTunerStyleChangePersistsToActivePreset() throws {
        viewModel.tunerStyle = .minimalist
        XCTAssertEqual(preset.tunerStyle, .minimalist)
    }

    @MainActor
    func testInstrumentPresetChangePersistsToActivePreset() {
        viewModel.instrumentPreset = .eFlat
        XCTAssertEqual(preset.instrumentPreset, .eFlat)
    }

    @MainActor
    func testReferencePitchChangePersistsToActivePreset() {
        viewModel.referencePitch = 444.0
        XCTAssertEqual(preset.referencePitch, 444.0)
    }

    @MainActor
    func testInitLoadsExistingPresetValues() {
        preset.tunerStyle = .linearBar
        preset.instrumentPreset = .f
        preset.referencePitch = 441.5
        try? context.save()

        let restored = TunerViewModel(
            audioEngine: MockAudioEngine(),
            modelContext: context,
            activePreset: preset
        )
        XCTAssertEqual(restored.tunerStyle, .linearBar)
        XCTAssertEqual(restored.instrumentPreset, .f)
        XCTAssertEqual(restored.referencePitch, 441.5)
    }
}
