// Tuner/Audio/MetronomeEngine.swift
import AVFoundation

final class MetronomeEngine {
    private var playerNode: AVAudioPlayerNode?
    private var scheduler: DispatchSourceTimer?
    private let schedulerQueue = DispatchQueue(label: "com.tunerapp.metronome.scheduler", qos: .userInteractive)

    // Retained only when we created the engine ourselves
    private var ownedEngine: AVAudioEngine?
    // Weak reference when we borrowed the tuner's engine
    private weak var borrowedEngine: AVAudioEngine?

    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?

    // Written on main before scheduler starts, then only on schedulerQueue
    private var bpm: Int = 120
    private var nextBeatSampleTime: AVAudioFramePosition = -1
    private var currentBeat: Int = 0
    private var beatsPerMeasure: Int = 4

    private(set) var isPlaying = false
    var onBeat: ((Int) -> Void)?

    @discardableResult
    func start(bpm: Int, beatsPerMeasure: Int, externalEngine: AVAudioEngine? = nil) -> Bool {
        stop()

        let session = AVAudioSession.sharedInstance()

        // Prefer the tuner's already-running engine to avoid two-engine conflicts on device.
        let engine: AVAudioEngine
        if let ext = externalEngine, ext.isRunning {
            engine = ext
            borrowedEngine = ext
            ownedEngine = nil
        } else {
            // Fallback: own engine (e.g. mic permission denied, tuner not started yet).
            // Ensure the session supports output — the default .soloAmbient is silenced
            // by the hardware ringer switch.
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
        let accent = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: bufferRate)
        let normal = ToneGenerator.makeClickBuffer(frequency: 660, duration: 0.03, sampleRate: bufferRate)
        accentBuffer = accent
        normalBuffer = normal

        let player = AVAudioPlayerNode()

        if let ext = externalEngine, ext.isRunning {
            // External engine already running: attach and start immediately
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: accent.format)
            player.play()
        } else if let owned = ownedEngine {
            // Own engine: wire graph before starting so the engine sees the full graph
            owned.attach(player)
            owned.connect(player, to: owned.mainMixerNode, format: accent.format)
            do {
                try owned.start()
            } catch {
                ownedEngine = nil
                return false
            }
            player.play()
        } else {
            return false
        }

        playerNode = player

        self.bpm = bpm
        self.beatsPerMeasure = beatsPerMeasure
        currentBeat = 0
        nextBeatSampleTime = -1
        isPlaying = true

        startScheduler()
        return true
    }

    func stop() {
        scheduler?.cancel()
        scheduler = nil

        if let player = playerNode {
            player.stop()
            // Detach from whichever engine holds the player
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
        let timer = DispatchSource.makeTimerSource(queue: schedulerQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            self?.scheduleBeats()
        }
        timer.resume()
        scheduler = timer
    }

    private func scheduleBeats() {
        guard let player = playerNode else { return }
        let engine = ownedEngine ?? borrowedEngine
        guard let engine, engine.isRunning else { return }
        guard let nodeTime = player.lastRenderTime, nodeTime.isSampleTimeValid else { return }
        guard let accentBuf = accentBuffer, let normalBuf = normalBuffer else { return }

        let rate = nodeTime.sampleRate

        if nextBeatSampleTime < 0 {
            nextBeatSampleTime = nodeTime.sampleTime
        }

        let lookAheadSamples = AVAudioFramePosition(rate * 0.1) // 100ms
        let deadline = nodeTime.sampleTime + lookAheadSamples
        let samplesPerBeat = AVAudioFramePosition(rate * 60.0 / Double(bpm))

        while nextBeatSampleTime < deadline {
            let buffer = currentBeat == 0 ? accentBuf : normalBuf
            let beatSampleTime = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: rate)
            let beatTime = beatSampleTime.extrapolateTime(fromAnchor: nodeTime) ?? beatSampleTime
            player.scheduleBuffer(buffer, at: beatTime, options: [])

            let beat = currentBeat
            let delaySeconds = Double(nextBeatSampleTime - nodeTime.sampleTime) / rate
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delaySeconds)) { [weak self] in
                self?.onBeat?(beat)
            }

            currentBeat = (currentBeat + 1) % beatsPerMeasure
            nextBeatSampleTime += samplesPerBeat
        }
    }
}
