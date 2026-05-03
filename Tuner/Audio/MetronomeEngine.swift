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
