# Metronome Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone metronome feature with sample-accurate timing, two visual styles, and tab-based navigation.

**Architecture:** New MetronomeEngine owns a private AVAudioEngine with AVAudioPlayerNode for output. A look-ahead scheduler pre-renders sine wave click buffers and schedules them at precise sample times. MetronomeViewModel (@Observable) drives the engine and exposes state to SwiftUI views. Navigation restructures from NavigationStack to TabView.

**Tech Stack:** AVFoundation (AVAudioEngine, AVAudioPlayerNode, AVAudioPCMBuffer), SwiftUI, XCTest

---

### Task 1: TimeSignature and MetronomeStyle Models

**Files:**
- Create: `Tuner/Models/TimeSignature.swift`
- Create: `Tuner/Models/MetronomeStyle.swift`
- Test: `TunerTests/MetronomeModelTests.swift`

- [ ] **Step 1: Write the test file**

```swift
// TunerTests/MetronomeModelTests.swift
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests/MetronomeModelTests 2>&1 | tail -20`
Expected: Build failure — `TimeSignature` and `MetronomeStyle` not found.

- [ ] **Step 3: Create TimeSignature.swift**

```swift
// Tuner/Models/TimeSignature.swift
enum TimeSignature: String, CaseIterable, Identifiable, Codable {
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case fiveFour = "5/4"
    case sixEight = "6/8"
    case sevenEight = "7/8"

    var id: String { rawValue }

    var beatsPerMeasure: Int {
        switch self {
        case .twoFour: 2
        case .threeFour: 3
        case .fourFour: 4
        case .fiveFour: 5
        case .sixEight: 6
        case .sevenEight: 7
        }
    }

    var displayName: String { rawValue }
}
```

- [ ] **Step 4: Create MetronomeStyle.swift**

```swift
// Tuner/Models/MetronomeStyle.swift
enum MetronomeStyle: String, CaseIterable, Identifiable {
    case minimal
    case circularGauge

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal: "Minimal"
        case .circularGauge: "Circular Gauge"
        }
    }
}
```

- [ ] **Step 5: Regenerate Xcode project and run tests**

Run: `cd /Users/fulstaph/coding/projects/tuner-app && xcodegen && xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests/MetronomeModelTests 2>&1 | tail -20`
Expected: All 5 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add Tuner/Models/TimeSignature.swift Tuner/Models/MetronomeStyle.swift TunerTests/MetronomeModelTests.swift
git commit -m "feat(metronome): add TimeSignature and MetronomeStyle models"
```

---

### Task 2: ToneGenerator

**Files:**
- Create: `Tuner/Audio/ToneGenerator.swift`
- Test: `TunerTests/ToneGeneratorTests.swift`

- [ ] **Step 1: Write the test file**

```swift
// TunerTests/ToneGeneratorTests.swift
import XCTest
import AVFoundation
@testable import Tuner

final class ToneGeneratorTests: XCTestCase {
    func testGeneratesBufferWithCorrectFrameCount() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: 44100)
        // 0.03s * 44100 = 1323 frames
        XCTAssertEqual(Int(buffer.frameLength), 1323)
    }

    func testGeneratesNonSilentBuffer() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: 44100)
        let channelData = buffer.floatChannelData![0]
        let maxAmplitude = (0..<Int(buffer.frameLength)).map { abs(channelData[$0]) }.max() ?? 0
        XCTAssertGreaterThan(maxAmplitude, 0.1)
    }

    func testEnvelopeStartsNearZero() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: 44100)
        let channelData = buffer.floatChannelData![0]
        XCTAssertLessThan(abs(channelData[0]), 0.01)
    }

    func testEnvelopeEndsNearZero() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: 44100)
        let channelData = buffer.floatChannelData![0]
        let lastSample = channelData[Int(buffer.frameLength) - 1]
        XCTAssertLessThan(abs(lastSample), 0.05)
    }

    func testBufferFormatIsMono44100() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 660, duration: 0.03, sampleRate: 44100)
        XCTAssertEqual(buffer.format.channelCount, 1)
        XCTAssertEqual(buffer.format.sampleRate, 44100)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests/ToneGeneratorTests 2>&1 | tail -20`
Expected: Build failure — `ToneGenerator` not found.

- [ ] **Step 3: Implement ToneGenerator.swift**

```swift
// Tuner/Audio/ToneGenerator.swift
import AVFoundation

enum ToneGenerator {
    static func makeClickBuffer(frequency: Float, duration: Double, sampleRate: Double = 44100) -> AVAudioPCMBuffer {
        let frameCount = Int(duration * sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)

        let channelData = buffer.floatChannelData![0]
        let attackSamples = Int(0.002 * sampleRate) // 2ms attack

        for i in 0..<frameCount {
            let sine = sinf(2.0 * .pi * frequency * Float(i) / Float(sampleRate))

            let envelope: Float
            if i < attackSamples {
                envelope = Float(i) / Float(attackSamples)
            } else {
                let decayProgress = Float(i - attackSamples) / Float(frameCount - attackSamples)
                envelope = powf(1.0 - decayProgress, 3.0)
            }

            channelData[i] = sine * envelope
        }

        return buffer
    }
}
```

- [ ] **Step 4: Regenerate project and run tests**

Run: `cd /Users/fulstaph/coding/projects/tuner-app && xcodegen && xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests/ToneGeneratorTests 2>&1 | tail -20`
Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Tuner/Audio/ToneGenerator.swift TunerTests/ToneGeneratorTests.swift
git commit -m "feat(metronome): add ToneGenerator for synthesized click buffers"
```

---

### Task 3: MetronomeEngine

**Files:**
- Create: `Tuner/Audio/MetronomeEngine.swift`
- Test: `TunerTests/MetronomeEngineTests.swift`

- [ ] **Step 1: Write the test file**

```swift
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests/MetronomeEngineTests 2>&1 | tail -20`
Expected: Build failure — `MetronomeEngine` not found.

- [ ] **Step 3: Implement MetronomeEngine.swift**

```swift
// Tuner/Audio/MetronomeEngine.swift
import AVFoundation

final class MetronomeEngine {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var scheduler: DispatchSourceTimer?
    private let schedulerQueue = DispatchQueue(label: "com.tunerapp.metronome.scheduler", qos: .userInteractive)

    private var accentBuffer: AVAudioPCMBuffer!
    private var normalBuffer: AVAudioPCMBuffer!

    private var samplesPerBeat: Double = 0
    private var nextBeatSampleTime: AVAudioFramePosition = 0
    private var currentBeat: Int = 0
    private var beatsPerMeasure: Int = 4
    private let sampleRate: Double = 44100

    private(set) var isPlaying = false
    var onBeat: ((Int) -> Void)?

    init() {
        accentBuffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: sampleRate)
        normalBuffer = ToneGenerator.makeClickBuffer(frequency: 660, duration: 0.03, sampleRate: sampleRate)
    }

    func start(bpm: Int, beatsPerMeasure: Int) {
        stop()

        self.beatsPerMeasure = beatsPerMeasure
        self.samplesPerBeat = sampleRate * 60.0 / Double(bpm)
        self.currentBeat = 0

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: accentBuffer.format)

        do {
            try engine.start()
        } catch {
            return
        }

        player.play()
        self.audioEngine = engine
        self.playerNode = player
        self.isPlaying = true

        guard let nodeTime = player.lastRenderTime else { return }
        nextBeatSampleTime = nodeTime.sampleTime

        startScheduler()
    }

    func stop() {
        scheduler?.cancel()
        scheduler = nil
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        isPlaying = false
    }

    func updateTempo(bpm: Int) {
        samplesPerBeat = sampleRate * 60.0 / Double(bpm)
    }

    func updateBeatsPerMeasure(_ count: Int) {
        beatsPerMeasure = count
    }

    private func startScheduler() {
        let timer = DispatchSource.makeTimerSource(queue: schedulerQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            self?.scheduleBeats()
        }
        timer.resume()
        scheduler = timer
    }

    private func scheduleBeats() {
        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }
        guard let nodeTime = player.lastRenderTime else { return }

        let lookAheadSamples = AVAudioFramePosition(sampleRate * 0.1) // 100ms
        let deadline = nodeTime.sampleTime + lookAheadSamples

        while nextBeatSampleTime < deadline {
            let buffer = currentBeat == 0 ? accentBuffer! : normalBuffer!
            let beatTime = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: sampleRate)
            player.scheduleBuffer(buffer, at: beatTime, options: [])

            let beat = currentBeat
            DispatchQueue.main.async { [weak self] in
                self?.onBeat?(beat)
            }

            currentBeat = (currentBeat + 1) % beatsPerMeasure
            nextBeatSampleTime += AVAudioFramePosition(samplesPerBeat)
        }
    }
}
```

- [ ] **Step 4: Regenerate project and run tests**

Run: `cd /Users/fulstaph/coding/projects/tuner-app && xcodegen && xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests/MetronomeEngineTests 2>&1 | tail -20`
Expected: All 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Tuner/Audio/MetronomeEngine.swift TunerTests/MetronomeEngineTests.swift
git commit -m "feat(metronome): add MetronomeEngine with look-ahead scheduling"
```

---

### Task 4: MetronomeViewModel

**Files:**
- Create: `Tuner/ViewModels/MetronomeViewModel.swift`
- Test: `TunerTests/MetronomeViewModelTests.swift`

- [ ] **Step 1: Write the test file**

```swift
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests/MetronomeViewModelTests 2>&1 | tail -20`
Expected: Build failure — `MetronomeViewModel` not found.

- [ ] **Step 3: Implement MetronomeViewModel.swift**

```swift
// Tuner/ViewModels/MetronomeViewModel.swift
import SwiftUI

@Observable
final class MetronomeViewModel {
    var bpm: Int = 120
    var timeSignature: TimeSignature = .fourFour
    var style: MetronomeStyle = .minimal
    var isPlaying: Bool = false
    var currentBeat: Int = 0

    private let engine = MetronomeEngine()
    private var tapTimestamps: [Date] = []

    init() {
        let storedBPM = UserDefaults.standard.integer(forKey: "metronomeBPM")
        if storedBPM > 0 { self.bpm = storedBPM }

        let storedTS = UserDefaults.standard.string(forKey: "metronomeTimeSignature")
        if let ts = storedTS.flatMap(TimeSignature.init(rawValue:)) { self.timeSignature = ts }

        let storedStyle = UserDefaults.standard.string(forKey: "metronomeStyle")
        if let s = storedStyle.flatMap(MetronomeStyle.init(rawValue:)) { self.style = s }

        engine.onBeat = { [weak self] beat in
            self?.currentBeat = beat
        }
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func start() {
        engine.start(bpm: bpm, beatsPerMeasure: timeSignature.beatsPerMeasure)
        isPlaying = true
        currentBeat = 0
    }

    func stop() {
        engine.stop()
        isPlaying = false
        currentBeat = 0
    }

    func setBPM(_ newBPM: Int) {
        bpm = min(240, max(40, newBPM))
        UserDefaults.standard.set(bpm, forKey: "metronomeBPM")
        if isPlaying { engine.updateTempo(bpm: bpm) }
    }

    func setTimeSignature(_ ts: TimeSignature) {
        timeSignature = ts
        UserDefaults.standard.set(ts.rawValue, forKey: "metronomeTimeSignature")
        if isPlaying { engine.updateBeatsPerMeasure(ts.beatsPerMeasure) }
    }

    func setStyle(_ newStyle: MetronomeStyle) {
        style = newStyle
        UserDefaults.standard.set(newStyle.rawValue, forKey: "metronomeStyle")
    }

    func tapTempo(at date: Date = Date()) {
        if let last = tapTimestamps.last, date.timeIntervalSince(last) > 2.0 {
            tapTimestamps.removeAll()
        }

        tapTimestamps.append(date)
        if tapTimestamps.count > 4 { tapTimestamps.removeFirst() }

        guard tapTimestamps.count >= 2 else { return }

        let intervals = zip(tapTimestamps, tapTimestamps.dropFirst()).map { $1.timeIntervalSince($0) }
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let computedBPM = Int(round(60.0 / averageInterval))
        setBPM(computedBPM)
    }
}
```

- [ ] **Step 4: Regenerate project and run tests**

Run: `cd /Users/fulstaph/coding/projects/tuner-app && xcodegen && xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests/MetronomeViewModelTests 2>&1 | tail -20`
Expected: All 12 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Tuner/ViewModels/MetronomeViewModel.swift TunerTests/MetronomeViewModelTests.swift
git commit -m "feat(metronome): add MetronomeViewModel with tap tempo and persistence"
```

---

### Task 5: Audio Session Change

**Files:**
- Modify: `Tuner/Audio/AudioEngine.swift:21-22`

- [ ] **Step 1: Update AudioEngine audio session category**

In `Tuner/Audio/AudioEngine.swift`, change lines 21-22 from:

```swift
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement)
```

to:

```swift
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
```

- [ ] **Step 2: Run existing tuner tests to ensure no regression**

Run: `xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerTests 2>&1 | tail -20`
Expected: All existing tests still PASS.

- [ ] **Step 3: Commit**

```bash
git add Tuner/Audio/AudioEngine.swift
git commit -m "feat(metronome): change audio session to playAndRecord for output support"
```

---

### Task 6: MetronomeMinimalView

**Files:**
- Create: `Tuner/Views/Styles/MetronomeMinimalView.swift`

- [ ] **Step 1: Create MetronomeMinimalView.swift**

```swift
// Tuner/Views/Styles/MetronomeMinimalView.swift
import SwiftUI

struct MetronomeMinimalView: View {
    @Bindable var viewModel: MetronomeViewModel

    var body: some View {
        VStack(spacing: 40) {
            beatIndicators

            VStack(spacing: 4) {
                Text("\(viewModel.bpm)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(2)
            }

            VStack(spacing: 20) {
                Slider(value: bpmBinding, in: 40...240, step: 1)
                    .tint(viewModel.isPlaying ? .green : .accentColor)

                controlRow
            }
            .padding(.horizontal)
        }
    }

    private var beatIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<viewModel.timeSignature.beatsPerMeasure, id: \.self) { beat in
                Circle()
                    .fill(beat == viewModel.currentBeat && viewModel.isPlaying ? Color.green : Color(.systemGray4))
                    .frame(width: 20, height: 20)
                    .animation(.easeOut(duration: 0.15), value: viewModel.currentBeat)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 24) {
            Menu {
                ForEach(TimeSignature.allCases) { ts in
                    Button(ts.displayName) { viewModel.setTimeSignature(ts) }
                }
            } label: {
                Text(viewModel.timeSignature.displayName)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }

            Button(action: { viewModel.toggle() }) {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.isPlaying ? .white : .white)
                    .frame(width: 52, height: 52)
                    .background(viewModel.isPlaying ? Color.red : Color.green, in: Circle())
            }

            Button(action: { viewModel.tapTempo() }) {
                Text("TAP")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var bpmBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.bpm) },
            set: { viewModel.setBPM(Int($0)) }
        )
    }
}
```

- [ ] **Step 2: Verify it builds**

Run: `cd /Users/fulstaph/coding/projects/tuner-app && xcodegen && xcodebuild build -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Tuner/Views/Styles/MetronomeMinimalView.swift
git commit -m "feat(metronome): add MetronomeMinimalView with beat dots and slider"
```

---

### Task 7: MetronomeCircularView

**Files:**
- Create: `Tuner/Views/Styles/MetronomeCircularView.swift`

- [ ] **Step 1: Create MetronomeCircularView.swift**

```swift
// Tuner/Views/Styles/MetronomeCircularView.swift
import SwiftUI

struct MetronomeCircularView: View {
    @Bindable var viewModel: MetronomeViewModel

    private var bpmProgress: Double {
        Double(viewModel.bpm - 40) / 200.0 // 40–240 range
    }

    var body: some View {
        VStack(spacing: 32) {
            bpmRing

            beatSquares

            controlRow
        }
        .padding(.horizontal)
    }

    private var bpmRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 8)

            Circle()
                .trim(from: 0, to: bpmProgress)
                .stroke(
                    viewModel.isPlaying ? Color.green : Color.accentColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: bpmProgress)

            VStack(spacing: 2) {
                Text("\(viewModel.bpm)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(2)
            }
        }
        .frame(width: 180, height: 180)
    }

    private var beatSquares: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.timeSignature.beatsPerMeasure, id: \.self) { beat in
                RoundedRectangle(cornerRadius: 6)
                    .fill(beat == viewModel.currentBeat && viewModel.isPlaying ? Color.green : Color(.systemGray5))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("\(beat + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(beat == viewModel.currentBeat && viewModel.isPlaying ? .white : .primary)
                    }
                    .animation(.easeOut(duration: 0.15), value: viewModel.currentBeat)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(TimeSignature.allCases) { ts in
                    Button(ts.displayName) { viewModel.setTimeSignature(ts) }
                }
            } label: {
                Text(viewModel.timeSignature.displayName)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }

            Button(action: { viewModel.setBPM(viewModel.bpm - 1) }) {
                Image(systemName: "minus")
                    .font(.body.weight(.medium))
                    .padding(10)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }

            Button(action: { viewModel.toggle() }) {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(viewModel.isPlaying ? Color.red : Color.green, in: Circle())
            }

            Button(action: { viewModel.setBPM(viewModel.bpm + 1) }) {
                Image(systemName: "plus")
                    .font(.body.weight(.medium))
                    .padding(10)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }

            Button(action: { viewModel.tapTempo() }) {
                Text("TAP")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
```

- [ ] **Step 2: Verify it builds**

Run: `cd /Users/fulstaph/coding/projects/tuner-app && xcodegen && xcodebuild build -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Tuner/Views/Styles/MetronomeCircularView.swift
git commit -m "feat(metronome): add MetronomeCircularView with BPM ring and beat squares"
```

---

### Task 8: MetronomeView Adapter and Navigation Restructure

**Files:**
- Create: `Tuner/Views/MetronomeView.swift`
- Modify: `Tuner/Views/ContentView.swift` (full rewrite)
- Modify: `Tuner/Views/SettingsView.swift`

- [ ] **Step 1: Create MetronomeView.swift**

```swift
// Tuner/Views/MetronomeView.swift
import SwiftUI

struct MetronomeView: View {
    @Bindable var viewModel: MetronomeViewModel

    var body: some View {
        switch viewModel.style {
        case .minimal:
            MetronomeMinimalView(viewModel: viewModel)
        case .circularGauge:
            MetronomeCircularView(viewModel: viewModel)
        }
    }
}
```

- [ ] **Step 2: Rewrite ContentView.swift to use TabView**

Replace the entire content of `Tuner/Views/ContentView.swift` with:

```swift
// Tuner/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var tunerViewModel = TunerViewModel()
    @State private var metronomeViewModel = MetronomeViewModel()
    @State private var showSettings = false

    var body: some View {
        TabView {
            Tab("Tuner", systemImage: "tuningfork") {
                NavigationStack {
                    ZStack {
                        Color(.systemBackground)
                            .ignoresSafeArea()
                        TunerDisplayView(style: tunerViewModel.tunerStyle, data: tunerViewModel.tunerData)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                    .onAppear { tunerViewModel.start() }
                    .onDisappear { tunerViewModel.stop() }
                }
            }

            Tab("Metronome", systemImage: "metronome") {
                NavigationStack {
                    ZStack {
                        Color(.systemBackground)
                            .ignoresSafeArea()
                        MetronomeView(viewModel: metronomeViewModel)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(tunerViewModel: tunerViewModel, metronomeViewModel: metronomeViewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
    }
}
```

- [ ] **Step 3: Update SettingsView to accept both view models**

Replace the entire content of `Tuner/Views/SettingsView.swift` with:

```swift
// Tuner/Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Bindable var tunerViewModel: TunerViewModel
    @Bindable var metronomeViewModel: MetronomeViewModel

    var body: some View {
        Form {
            Section("Tuner Display") {
                Picker("Tuner Style", selection: $tunerViewModel.tunerStyle) {
                    ForEach(TunerStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            }

            Section("Instrument") {
                Picker("Transposition", selection: $tunerViewModel.instrumentPreset) {
                    ForEach(InstrumentPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
            }

            Section("Reference Pitch") {
                VStack(alignment: .leading) {
                    Text("A4 = \(Int(tunerViewModel.referencePitch)) Hz")
                        .font(.headline)
                    Slider(value: $tunerViewModel.referencePitch, in: 415...460, step: 1)
                    HStack {
                        Text("415")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset to 440") {
                            tunerViewModel.referencePitch = 440
                        }
                        .font(.caption)
                        Spacer()
                        Text("460")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Metronome Display") {
                Picker("Metronome Style", selection: Binding(
                    get: { metronomeViewModel.style },
                    set: { metronomeViewModel.setStyle($0) }
                )) {
                    ForEach(MetronomeStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
```

- [ ] **Step 4: Regenerate project and build**

Run: `cd /Users/fulstaph/coding/projects/tuner-app && xcodegen && xcodebuild build -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10`
Expected: Build succeeds.

- [ ] **Step 5: Run all tests**

Run: `xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test Suite|Tests|PASS|FAIL)" | tail -20`
Expected: All tests pass. Note: `TunerViewModelTests` may need the SettingsView initializer update acknowledged — the tests don't use SettingsView directly so they should still pass.

- [ ] **Step 6: Commit**

```bash
git add Tuner/Views/MetronomeView.swift Tuner/Views/ContentView.swift Tuner/Views/SettingsView.swift
git commit -m "feat(metronome): add MetronomeView, restructure to TabView navigation, update Settings"
```

---

### Task 9: UI Tests Update

**Files:**
- Modify: `TunerUITests/TunerUITests.swift`

- [ ] **Step 1: Read the existing UI test file for context**

Read `TunerUITests/TunerUITests.swift` to understand what assertions exist. The tab bar change may affect navigation in UI tests (e.g., finding the settings gear button may need tab context).

- [ ] **Step 2: Add metronome UI tests**

Add to the existing UI test file (or create new tests within it) covering:
- App launches and shows Tuner tab by default
- Tapping Metronome tab shows metronome view
- Play button exists and is tappable
- Tap tempo button exists
- Time signature menu is accessible
- Settings shows metronome style picker

The exact assertions depend on what the existing file contains — adapt to match its patterns.

- [ ] **Step 3: Run UI tests**

Run: `xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TunerUITests 2>&1 | tail -20`
Expected: All UI tests pass.

- [ ] **Step 4: Commit**

```bash
git add TunerUITests/TunerUITests.swift
git commit -m "test(metronome): update UI tests for tab navigation and metronome controls"
```

---

### Task 10: Manual Verification

- [ ] **Step 1: Build and run on simulator**

Run: `xcodebuild build -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Boot the simulator and install the app to verify:

- [ ] **Step 2: Verify metronome features**

Test the following manually (or via Xcode's simulator):
1. Tab bar shows "Tuner" and "Metronome" tabs
2. Metronome tab displays the minimal style view by default
3. Pressing play produces audible clicks
4. BPM slider adjusts tempo in real time
5. Tap tempo button calculates BPM from taps
6. Time signature menu changes beat count
7. Beat dots animate in sync with audio
8. Switching to Settings → changing metronome style → returning shows circular gauge
9. Switch to Tuner tab — tuner still detects pitch
10. Metronome keeps playing when switching to Tuner tab

- [ ] **Step 3: Run full test suite one final time**

Run: `xcodebuild test -project Tuner.xcodeproj -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test Suite|Executed|PASS|FAIL)" | tail -10`
Expected: All tests pass.

- [ ] **Step 4: Final commit (if any fixups needed)**

```bash
git log --oneline -8
```

Verify the commit history looks clean.
