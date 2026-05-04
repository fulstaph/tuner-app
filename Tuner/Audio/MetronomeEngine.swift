// Tuner/Audio/MetronomeEngine.swift
import AVFoundation
import os.log

private let metLog = Logger(subsystem: "com.tunerapp", category: "MetronomeEngine")

final class MetronomeEngine {
    private var playerNode: AVAudioPlayerNode?
    private var scheduler: DispatchSourceTimer?
    private let schedulerQueue = DispatchQueue(label: "com.tunerapp.metronome.scheduler", qos: .userInteractive)

    private var ownedEngine: AVAudioEngine?
    private weak var borrowedEngine: AVAudioEngine?

    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?

    private var bpm: Int = 120
    private var currentBeat: Int = 0
    private var beatsPerMeasure: Int = 4
    private var beatCount = 0
    private var lastBeatTime: CFAbsoluteTime = 0

    private(set) var isPlaying = false
    var onBeat: ((Int) -> Void)?

    @discardableResult
    func start(bpm: Int, beatsPerMeasure: Int, externalEngine: AVAudioEngine? = nil) -> Bool {
        stop()

        let session = AVAudioSession.sharedInstance()

        let engine: AVAudioEngine
        if let ext = externalEngine, ext.isRunning {
            engine = ext
            borrowedEngine = ext
            ownedEngine = nil
        } else {
            if session.category != .playAndRecord {
                try? session.setCategory(.playback, mode: .default)
                try? session.setActive(true)
            }
            let newEngine = AVAudioEngine()
            ownedEngine = newEngine
            borrowedEngine = nil
            engine = newEngine
        }

        let bufferRate = session.sampleRate > 0 ? session.sampleRate : 44100
        let accent = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.06, sampleRate: bufferRate, gain: 0.9)
        let normal = ToneGenerator.makeClickBuffer(frequency: 660, duration: 0.06, sampleRate: bufferRate, gain: 0.75)
        accentBuffer = accent
        normalBuffer = normal

        let player = AVAudioPlayerNode()

        var audioReady = false
        if let ext = externalEngine, ext.isRunning {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: accent.format)
            player.play()
            audioReady = true
        } else if let owned = ownedEngine {
            owned.attach(player)
            owned.connect(player, to: owned.mainMixerNode, format: accent.format)
            do {
                try owned.start()
                player.play()
                audioReady = true
            } catch {
                metLog.error("start: owned engine failed: \(error, privacy: .public)")
                ownedEngine = nil
            }
        }

        if audioReady {
            playerNode = player
        }
        self.bpm = bpm
        self.beatsPerMeasure = beatsPerMeasure
        currentBeat = 0
        beatCount = 0
        lastBeatTime = 0
        isPlaying = true

        startScheduler()
        return true
    }

    func stop() {
        scheduler?.cancel()
        scheduler = nil

        if let player = playerNode {
            player.stop()
            (ownedEngine ?? borrowedEngine)?.detach(player)
        }
        playerNode = nil

        ownedEngine?.stop()
        ownedEngine = nil
        borrowedEngine = nil

        isPlaying = false
    }

    func updateTempo(bpm: Int) {
        schedulerQueue.async { [weak self] in
            self?.bpm = bpm
        }
    }

    func updateBeatsPerMeasure(_ count: Int) {
        schedulerQueue.async { [weak self] in
            self?.beatsPerMeasure = count
        }
    }

    private func startScheduler() {
        schedulerQueue.async { [weak self] in
            self?.playBeat()
        }
    }

    private func playBeat() {
        beatCount += 1
        let now = CFAbsoluteTimeGetCurrent()
        let beatInterval = 60.0 / Double(bpm)

        if lastBeatTime > 0 && (now - lastBeatTime) > beatInterval * 4 {
            lastBeatTime = now
            currentBeat = 0
            scheduleNextBeat()
            return
        }
        lastBeatTime = now

        if let player = playerNode,
           let engine = ownedEngine ?? borrowedEngine, engine.isRunning,
           let accentBuf = accentBuffer, let normalBuf = normalBuffer {
            let buffer = currentBeat == 0 ? accentBuf : normalBuf
            player.scheduleBuffer(buffer, at: nil, options: [])
        }

        let beat = currentBeat
        DispatchQueue.main.async { [weak self] in self?.onBeat?(beat) }
        currentBeat = (currentBeat + 1) % beatsPerMeasure

        scheduleNextBeat()
    }

    private func scheduleNextBeat() {
        let interval = 60.0 / Double(bpm)
        let timer = DispatchSource.makeTimerSource(queue: schedulerQueue)
        timer.schedule(deadline: .now() + interval, leeway: .milliseconds(1))
        timer.setEventHandler { [weak self] in
            self?.playBeat()
        }
        timer.resume()
        scheduler = timer
    }
}
