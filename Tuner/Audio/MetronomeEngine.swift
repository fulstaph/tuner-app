// Tuner/Audio/MetronomeEngine.swift
import AVFoundation
import os.log

private let metLog = Logger(subsystem: "com.tunerapp", category: "MetronomeEngine")

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

    private var scheduleCallCount = 0

    private(set) var isPlaying = false
    var onBeat: ((Int) -> Void)?

    @discardableResult
    func start(bpm: Int, beatsPerMeasure: Int, externalEngine: AVAudioEngine? = nil) -> Bool {
        stop()

        let session = AVAudioSession.sharedInstance()
        metLog.info("MetronomeEngine.start: bpm=\(bpm) beats=\(beatsPerMeasure) externalEngine=\(externalEngine != nil ? "provided" : "nil", privacy: .public)")
        metLog.info("MetronomeEngine.start: session.category=\(session.category.rawValue, privacy: .public) sampleRate=\(session.sampleRate)")

        // Prefer the tuner's already-running engine to avoid two-engine conflicts on device.
        let engine: AVAudioEngine
        if let ext = externalEngine, ext.isRunning {
            metLog.info("MetronomeEngine.start: using external (borrowed) engine, isRunning=\(ext.isRunning)")
            engine = ext
            borrowedEngine = ext
            ownedEngine = nil
        } else {
            if let ext = externalEngine {
                metLog.warning("MetronomeEngine.start: external engine provided but isRunning=false — falling back to owned engine")
            } else {
                metLog.info("MetronomeEngine.start: no external engine — creating owned engine")
            }
            // Fallback: own engine (e.g. mic permission denied, tuner not started yet).
            // Ensure the session supports output — the default .soloAmbient is silenced
            // by the hardware ringer switch.
            if session.category != .playAndRecord {
                metLog.info("MetronomeEngine.start: setting session category to .playback")
                try? session.setCategory(.playback, mode: .default)
                try? session.setActive(true)
            }
            let newEngine = AVAudioEngine()
            ownedEngine = newEngine
            borrowedEngine = nil
            engine = newEngine
        }

        let bufferRate = session.sampleRate > 0 ? session.sampleRate : 44100
        metLog.info("MetronomeEngine.start: bufferRate=\(bufferRate)")
        let accent = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: bufferRate)
        let normal = ToneGenerator.makeClickBuffer(frequency: 660, duration: 0.03, sampleRate: bufferRate)
        metLog.info("MetronomeEngine.start: accent buffer frameLength=\(accent.frameLength) format=\(accent.format, privacy: .public)")
        accentBuffer = accent
        normalBuffer = normal

        let player = AVAudioPlayerNode()

        if let ext = externalEngine, ext.isRunning {
            // External engine already running: attach and start immediately
            metLog.info("MetronomeEngine.start: attaching player to borrowed engine")
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: accent.format)
            player.play()
            metLog.info("MetronomeEngine.start: player.play() called on borrowed engine, player.isPlaying=\(player.isPlaying)")
        } else if let owned = ownedEngine {
            // Own engine: wire graph before starting so the engine sees the full graph
            metLog.info("MetronomeEngine.start: attaching player to owned engine")
            owned.attach(player)
            owned.connect(player, to: owned.mainMixerNode, format: accent.format)
            do {
                try owned.start()
                metLog.info("MetronomeEngine.start: owned engine started, isRunning=\(owned.isRunning)")
            } catch {
                metLog.error("MetronomeEngine.start: owned engine.start() failed: \(error, privacy: .public)")
                ownedEngine = nil
                return false
            }
            player.play()
            metLog.info("MetronomeEngine.start: player.play() called on owned engine, player.isPlaying=\(player.isPlaying)")
        } else {
            metLog.error("MetronomeEngine.start: no engine available — aborting")
            return false
        }

        playerNode = player

        self.bpm = bpm
        self.beatsPerMeasure = beatsPerMeasure
        currentBeat = 0
        nextBeatSampleTime = -1
        scheduleCallCount = 0
        isPlaying = true

        metLog.info("MetronomeEngine.start: starting scheduler")
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
        metLog.info("MetronomeEngine.stop: stopped")
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
        scheduleCallCount += 1
        let callNum = scheduleCallCount

        guard let player = playerNode else {
            if callNum <= 3 { metLog.warning("MetronomeEngine.scheduleBeats[\(callNum)]: playerNode is nil — returning") }
            return
        }
        let engine = ownedEngine ?? borrowedEngine
        guard let engine, engine.isRunning else {
            if callNum <= 3 { metLog.warning("MetronomeEngine.scheduleBeats[\(callNum)]: engine nil or not running (isRunning=\(engine?.isRunning ?? false)) — returning") }
            return
        }
        guard let accentBuf = accentBuffer, let normalBuf = normalBuffer else {
            if callNum <= 3 { metLog.warning("MetronomeEngine.scheduleBeats[\(callNum)]: buffers nil — returning") }
            return
        }

        guard let nodeTime = player.lastRenderTime, nodeTime.isSampleTimeValid else {
            if callNum <= 5 {
                metLog.info("MetronomeEngine.scheduleBeats[\(callNum)]: lastRenderTime invalid (isSampleTimeValid=false), nextBeatSampleTime=\(self.nextBeatSampleTime)")
            }
            // lastRenderTime not valid yet — bootstrap by playing the first beat immediately
            if nextBeatSampleTime < 0 {
                metLog.info("MetronomeEngine.scheduleBeats[\(callNum)]: BOOTSTRAP — scheduling first beat with at:nil")
                let buffer = currentBeat == 0 ? accentBuf : normalBuf
                player.scheduleBuffer(buffer, at: nil, options: [])
                let beat = currentBeat
                DispatchQueue.main.async { [weak self] in self?.onBeat?(beat) }
                currentBeat = (currentBeat + 1) % beatsPerMeasure
                nextBeatSampleTime = 0
            }
            return
        }

        let rate = nodeTime.sampleRate

        // After bootstrap, anchor next beat one interval from current position
        if nextBeatSampleTime <= 0 {
            let samplesPerBeat = AVAudioFramePosition(rate * 60.0 / Double(bpm))
            nextBeatSampleTime = nodeTime.sampleTime + samplesPerBeat
            metLog.info("MetronomeEngine.scheduleBeats[\(callNum)]: anchoring after bootstrap, rate=\(rate) sampleTime=\(nodeTime.sampleTime) nextBeat=\(self.nextBeatSampleTime)")
        }

        let lookAheadSamples = AVAudioFramePosition(rate * 0.1) // 100ms
        let deadline = nodeTime.sampleTime + lookAheadSamples
        let samplesPerBeat = AVAudioFramePosition(rate * 60.0 / Double(bpm))

        var scheduled = 0
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
            scheduled += 1
        }

        if scheduled > 0 && callNum <= 10 {
            metLog.info("MetronomeEngine.scheduleBeats[\(callNum)]: scheduled \(scheduled) beat(s), rate=\(rate) bpm=\(self.bpm)")
        }
    }
}
