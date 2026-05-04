// Tuner/Audio/MetronomeEngine.swift
import AVFoundation

final class MetronomeEngine {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var scheduler: DispatchSourceTimer?
    private let schedulerQueue = DispatchQueue(label: "com.tunerapp.metronome.scheduler", qos: .userInteractive)

    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?

    // All fields below are only accessed on schedulerQueue after start()
    private var bpm: Int = 120
    private var nextBeatSampleTime: AVAudioFramePosition = -1
    private var currentBeat: Int = 0
    private var beatsPerMeasure: Int = 4

    private(set) var isPlaying = false
    var onBeat: ((Int) -> Void)?

    @discardableResult
    func start(bpm: Int, beatsPerMeasure: Int) -> Bool {
        stop()

        // Ensure the session supports output, regardless of whether the tuner has started.
        // .playAndRecord bypasses the ringer switch; .soloAmbient (the default) does not.
        let session = AVAudioSession.sharedInstance()
        if session.category != .playAndRecord {
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
        }

        let bufferRate = session.sampleRate > 0 ? session.sampleRate : 44100
        let accent = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: bufferRate)
        let normal = ToneGenerator.makeClickBuffer(frequency: 660, duration: 0.03, sampleRate: bufferRate)
        accentBuffer = accent
        normalBuffer = normal

        self.bpm = bpm
        self.beatsPerMeasure = beatsPerMeasure
        currentBeat = 0
        nextBeatSampleTime = -1

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: accent.format)

        do {
            try engine.start()
        } catch {
            return false
        }

        player.play()
        audioEngine = engine
        playerNode = player
        isPlaying = true

        startScheduler()
        return true
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
        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }
        guard let nodeTime = player.lastRenderTime, nodeTime.isSampleTimeValid else { return }
        guard let accentBuf = accentBuffer, let normalBuf = normalBuffer else { return }

        // Use the hardware sample rate from the render clock, not the buffer rate.
        // On iPhones this is often 48000 Hz; on the simulator it matches the buffer rate.
        let rate = nodeTime.sampleRate

        if nextBeatSampleTime < 0 {
            nextBeatSampleTime = nodeTime.sampleTime
        }

        let lookAheadSamples = AVAudioFramePosition(rate * 0.1) // 100ms
        let deadline = nodeTime.sampleTime + lookAheadSamples
        let samplesPerBeat = AVAudioFramePosition(rate * 60.0 / Double(bpm))

        while nextBeatSampleTime < deadline {
            let buffer = currentBeat == 0 ? accentBuf : normalBuf

            // extrapolateTime produces an AVAudioTime with a valid host time, which the
            // player node can compare against its render clock without any rate ambiguity.
            // Fall back to a sample-time-only AVAudioTime if host time isn't available.
            let beatSampleTime = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: rate)
            let beatTime = beatSampleTime.extrapolateTime(fromAnchor: nodeTime)
                ?? beatSampleTime
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
