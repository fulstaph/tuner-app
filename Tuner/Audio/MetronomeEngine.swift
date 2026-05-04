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
        metLog.info("start: bpm=\(bpm) beats=\(beatsPerMeasure) externalEngine=\(externalEngine != nil ? "provided" : "nil", privacy: .public)")
        metLog.info("start: session.category=\(session.category.rawValue, privacy: .public) sampleRate=\(session.sampleRate)")

        let engine: AVAudioEngine
        if let ext = externalEngine, ext.isRunning {
            metLog.info("start: using borrowed engine")
            engine = ext
            borrowedEngine = ext
            ownedEngine = nil
        } else {
            if externalEngine != nil {
                metLog.warning("start: external engine not running — falling back to owned engine")
            }
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
        metLog.info("start: bufferRate=\(bufferRate) accent frameLength=\(accent.frameLength)")
        accentBuffer = accent
        normalBuffer = normal

        let player = AVAudioPlayerNode()

        if let ext = externalEngine, ext.isRunning {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: accent.format)
            player.play()
            metLog.info("start: player attached to borrowed engine, isPlaying=\(player.isPlaying)")
        } else if let owned = ownedEngine {
            owned.attach(player)
            owned.connect(player, to: owned.mainMixerNode, format: accent.format)
            do {
                try owned.start()
            } catch {
                metLog.error("start: owned engine failed: \(error, privacy: .public)")
                ownedEngine = nil
                return false
            }
            player.play()
            metLog.info("start: player attached to owned engine, isPlaying=\(player.isPlaying)")
        } else {
            metLog.error("start: no engine available")
            return false
        }

        playerNode = player

        self.bpm = bpm
        self.beatsPerMeasure = beatsPerMeasure
        currentBeat = 0
        nextBeatSampleTime = -1
        scheduleCallCount = 0
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

        guard let player = playerNode else { return }
        let engine = ownedEngine ?? borrowedEngine
        guard let engine, engine.isRunning else { return }
        guard let accentBuf = accentBuffer, let normalBuf = normalBuffer else { return }

        // First call: always play immediately with at:nil so the user hears a click instantly
        if nextBeatSampleTime < 0 {
            let buffer = currentBeat == 0 ? accentBuf : normalBuf
            player.scheduleBuffer(buffer, at: nil, options: [])
            metLog.info("scheduleBeats[\(callNum)]: first beat scheduled with at:nil")

            let beat = currentBeat
            DispatchQueue.main.async { [weak self] in self?.onBeat?(beat) }
            currentBeat = (currentBeat + 1) % beatsPerMeasure

            if let nodeTime = player.lastRenderTime, nodeTime.isSampleTimeValid {
                let rate = nodeTime.sampleRate
                let samplesPerBeat = AVAudioFramePosition(rate * 60.0 / Double(bpm))
                nextBeatSampleTime = nodeTime.sampleTime + samplesPerBeat
                metLog.info("scheduleBeats[\(callNum)]: anchored nextBeat=\(self.nextBeatSampleTime) rate=\(rate)")
            } else {
                nextBeatSampleTime = 0
                metLog.info("scheduleBeats[\(callNum)]: lastRenderTime not yet valid, will anchor on next tick")
            }
            return
        }

        guard let nodeTime = player.lastRenderTime, nodeTime.isSampleTimeValid else {
            return
        }

        let rate = nodeTime.sampleRate
        let samplesPerBeat = AVAudioFramePosition(rate * 60.0 / Double(bpm))

        // Anchor if we were bootstrapped without a valid render time
        if nextBeatSampleTime == 0 {
            nextBeatSampleTime = nodeTime.sampleTime + samplesPerBeat
        }

        // Skip past beats — never schedule in the past
        var skipped = 0
        while nextBeatSampleTime < nodeTime.sampleTime {
            currentBeat = (currentBeat + 1) % beatsPerMeasure
            nextBeatSampleTime += samplesPerBeat
            skipped += 1
        }
        if skipped > 0 && callNum <= 10 {
            metLog.warning("scheduleBeats[\(callNum)]: skipped \(skipped) past beat(s)")
        }

        let lookAheadSamples = AVAudioFramePosition(rate * 0.1)
        let deadline = nodeTime.sampleTime + lookAheadSamples

        var scheduled = 0
        while nextBeatSampleTime < deadline {
            let buffer = currentBeat == 0 ? accentBuf : normalBuf
            let beatSampleTime = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: rate)

            if let beatTime = beatSampleTime.extrapolateTime(fromAnchor: nodeTime) {
                player.scheduleBuffer(buffer, at: beatTime, options: [])
            } else {
                metLog.warning("scheduleBeats[\(callNum)]: extrapolateTime returned nil, using at:nil")
                player.scheduleBuffer(buffer, at: nil, options: [])
            }

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
            metLog.info("scheduleBeats[\(callNum)]: scheduled \(scheduled) beat(s), bpm=\(self.bpm)")
        }
    }
}
