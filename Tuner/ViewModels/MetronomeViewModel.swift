// Tuner/ViewModels/MetronomeViewModel.swift
import SwiftData
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

    private let modelContext: ModelContext?
    private var activePreset: Preset?

    init(modelContext: ModelContext? = nil, activePreset: Preset? = nil) {
        self.modelContext = modelContext
        self.activePreset = activePreset

        if let activePreset {
            self.bpm = activePreset.bpm
            self.timeSignature = activePreset.timeSignature
            self.style = activePreset.metronomeStyle
        }

        engine.onBeat = { [weak self] beat in
            self?.currentBeat = beat
        }
        engine.onStop = { [weak self] in
            self?.isPlaying = false
            self?.currentBeat = 0
        }
        engine.onResume = { [weak self] in
            self?.isPlaying = true
            self?.currentBeat = 0
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
        let started = engine.start(
            bpm: bpm,
            beatsPerMeasure: timeSignature.beatsPerMeasure
        )
        guard started else { return }
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
        persist { $0.bpm = bpm }
        if isPlaying { engine.updateTempo(bpm: bpm) }
    }

    func setTimeSignature(_ ts: TimeSignature) {
        timeSignature = ts
        persist {
            $0.timeSignature = ts
            if $0.accentPattern.count != ts.beatsPerMeasure {
                $0.accentPattern = Preset.defaultAccentPattern(for: ts)
            }
        }
        if isPlaying { engine.updateBeatsPerMeasure(ts.beatsPerMeasure) }
    }

    func setStyle(_ newStyle: MetronomeStyle) {
        style = newStyle
        persist { $0.metronomeStyle = newStyle }
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

    private func persist(_ mutate: (Preset) -> Void) {
        guard let preset = activePreset, let context = modelContext else { return }
        mutate(preset)
        preset.updatedAt = Date()
        try? context.save()
    }
}
