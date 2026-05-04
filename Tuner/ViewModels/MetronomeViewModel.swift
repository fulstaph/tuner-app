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
