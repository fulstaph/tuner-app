import AVFoundation
import SwiftData
import SwiftUI

@Observable
final class TunerViewModel {
    var tunerData = TunerData()

    var tunerStyle: TunerStyle {
        didSet { persist { $0.tunerStyle = tunerStyle } }
    }

    var instrumentPreset: InstrumentPreset {
        didSet { persist { $0.instrumentPreset = instrumentPreset } }
    }

    var referencePitch: Double {
        didSet { persist { $0.referencePitch = referencePitch } }
    }

    private let audioEngine: AudioEngineProtocol
    private let pitchDetector: PitchDetector
    private var isRunning = false

    private let modelContext: ModelContext?
    private var activePreset: Preset?

    var avAudioEngine: AVAudioEngine? { audioEngine.avAudioEngine }

    private var smoothedCents: Double = 0
    private let smoothingFactor: Double = 0.3

    private var recentNotes: [(String, Int)] = []
    private let debounceCount = 3

    init(
        audioEngine: AudioEngineProtocol = AudioEngine(),
        modelContext: ModelContext? = nil,
        activePreset: Preset? = nil
    ) {
        self.audioEngine = audioEngine
        self.modelContext = modelContext
        self.activePreset = activePreset

        self.tunerStyle = activePreset?.tunerStyle ?? .needle
        self.instrumentPreset = activePreset?.instrumentPreset ?? .concert
        self.referencePitch = activePreset?.referencePitch ?? 440.0

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

    private func persist(_ mutate: (Preset) -> Void) {
        guard let preset = activePreset, let context = modelContext else { return }
        mutate(preset)
        preset.updatedAt = Date()
        try? context.save()
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
