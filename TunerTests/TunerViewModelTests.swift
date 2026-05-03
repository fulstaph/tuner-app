import XCTest
@testable import Tuner

final class TunerViewModelTests: XCTestCase {
    var mockEngine: MockAudioEngine!
    var viewModel: TunerViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        // Clear persisted settings so defaults are used on every run
        UserDefaults.standard.removeObject(forKey: "tunerStyle")
        UserDefaults.standard.removeObject(forKey: "instrumentPreset")
        UserDefaults.standard.removeObject(forKey: "referencePitch")
        mockEngine = MockAudioEngine()
        viewModel = TunerViewModel(audioEngine: mockEngine)
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
}
