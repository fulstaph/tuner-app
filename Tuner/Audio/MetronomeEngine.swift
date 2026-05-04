// Tuner/Audio/MetronomeEngine.swift
import AVFoundation

final class MetronomeEngine {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var scheduler: DispatchSourceTimer?
    private let schedulerQueue = DispatchQueue(label: "com.tunerapp.metronome.scheduler", qos: .userInteractive)

    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?
    private var sampleRate: Double = 44100

    // All fields below are only accessed on schedulerQueue after start()
    private var samplesPerBeat: Double = 0
    private var nextBeatSampleTime: AVAudioFramePosition = -1
    private var currentBeat: Int = 0
    private var beatsPerMeasure: Int = 4

    private(set) var isPlaying = false
    var onBeat: ((Int) -> Void)?

    @discardableResult
    func start(bpm: Int, beatsPerMeasure: Int) -> Bool {
        stop()

        let sessionRate = AVAudioSession.sharedInstance().sampleRate
        sampleRate = sessionRate > 0 ? sessionRate : 44100

        let accent = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: sampleRate)
        let normal = ToneGenerator.makeClickBuffer(frequency: 660, duration: 0.03, sampleRate: sampleRate)
        accentBuffer = accent
        normalBuffer = normal

        self.beatsPerMeasure = beatsPerMeasure
        samplesPerBeat = sampleRate * 60.0 / Double(bpm)
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
            guard let self else { return }
            samplesPerBeat = sampleRate * 60.0 / Double(bpm)
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

        if nextBeatSampleTime < 0 {
            nextBeatSampleTime = nodeTime.sampleTime
        }

        let lookAheadSamples = AVAudioFramePosition(sampleRate * 0.1) // 100ms
        let deadline = nodeTime.sampleTime + lookAheadSamples

        while nextBeatSampleTime < deadline {
            let buffer = currentBeat == 0 ? accentBuf : normalBuf
            let beatTime = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: sampleRate)
            player.scheduleBuffer(buffer, at: beatTime, options: [])

            let beat = currentBeat
            let delaySeconds = Double(nextBeatSampleTime - nodeTime.sampleTime) / sampleRate
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delaySeconds)) { [weak self] in
                self?.onBeat?(beat)
            }

            currentBeat = (currentBeat + 1) % beatsPerMeasure
            nextBeatSampleTime += AVAudioFramePosition(samplesPerBeat)
        }
    }
}
