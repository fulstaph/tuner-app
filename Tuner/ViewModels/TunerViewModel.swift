import AVFoundation
import SwiftUI

@Observable
final class TunerViewModel {
    var tunerData = TunerData()

    var tunerStyle: TunerStyle {
        didSet { UserDefaults.standard.set(tunerStyle.rawValue, forKey: "tunerStyle") }
    }

    var instrumentPreset: InstrumentPreset {
        didSet { UserDefaults.standard.set(instrumentPreset.rawValue, forKey: "instrumentPreset") }
    }

    var referencePitch: Double {
        didSet { UserDefaults.standard.set(referencePitch, forKey: "referencePitch") }
    }

    private let audioEngine: AudioEngineProtocol
    private let pitchDetector: PitchDetector
    private var isRunning = false

    var avAudioEngine: AVAudioEngine? { audioEngine.avAudioEngine }

    private var smoothedCents: Double = 0
    private let smoothingFactor: Double = 0.3

    private var recentNotes: [(String, Int)] = []
    private let debounceCount = 3

    init(audioEngine: AudioEngineProtocol = AudioEngine()) {
        self.audioEngine = audioEngine

        let storedStyle = UserDefaults.standard.string(forKey: "tunerStyle")
        self.tunerStyle = storedStyle.flatMap(TunerStyle.init(rawValue:)) ?? .needle

        let storedPreset = UserDefaults.standard.string(forKey: "instrumentPreset")
        self.instrumentPreset = storedPreset.flatMap(InstrumentPreset.init(rawValue:)) ?? .concert

        let storedPitch = UserDefaults.standard.double(forKey: "referencePitch")
        self.referencePitch = storedPitch > 0 ? storedPitch : 440.0

        self.pitchDetector = PitchDetector(sampleRate: audioEngine.sampleRate)

        self.audioEngine.onBuffer = { [weak self] buffer in
            self?.processBuffer(buffer)
        }
    }

    func start() {
        guard !isRunning else { return }
        do {
            try audioEngine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        audioEngine.stop()
    }

    private func processBuffer(_ buffer: [Float]) {
        guard let result = pitchDetector.detectPitch(in: buffer) else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.tunerData = TunerData()
                self.recentNotes.removeAll()
                self.smoothedCents = 0
            }
            return
        }

        let mapped = NoteMapper.map(
            frequency: result.frequency,
            referencePitch: referencePitch,
            transposition: instrumentPreset.semitoneShift
        )

        let smoothed = applySmoothing(mapped.cents)
        let (note, octave) = applyDebouncing(mapped.note, octave: mapped.octave)

        DispatchQueue.main.async { [weak self] in
            self?.tunerData = TunerData(
                frequency: mapped.frequency,
                note: note,
                octave: octave,
                cents: smoothed,
                isActive: true
            )
        }
    }

    private func applySmoothing(_ cents: Double) -> Double {
        smoothedCents = smoothedCents * (1 - smoothingFactor) + cents * smoothingFactor
        return smoothedCents
    }

    private func applyDebouncing(_ note: String, octave: Int) -> (String, Int) {
        recentNotes.append((note, octave))
        if recentNotes.count > debounceCount { recentNotes.removeFirst() }

        let allMatch = recentNotes.count >= debounceCount
            && recentNotes.allSatisfy({ $0.0 == note && $0.1 == octave })

        if allMatch { return (note, octave) }
        if tunerData.isActive { return (tunerData.note, tunerData.octave) }
        return (note, octave)
    }
}
