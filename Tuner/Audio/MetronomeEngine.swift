// Tuner/Audio/MetronomeEngine.swift
import AVFoundation
import os.log

private let metLog = Logger(subsystem: "com.tunerapp", category: "MetronomeEngine")

final class MetronomeEngine {
    private var playerNode: AVAudioPlayerNode?
    private var scheduler: DispatchSourceTimer?
    private let schedulerQueue = DispatchQueue(
        label: "com.tunerapp.metronome.scheduler",
        qos: .userInteractive
    )

    private var audioEngine: AVAudioEngine?

    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?
    private var subdivisionBuffer: AVAudioPCMBuffer?

    private var bpm: Int = 120
    private var currentBeat: Int = 0
    private var beatsPerMeasure: Int = 4
    private var subdivisionsPerBeat: Int = 1
    private var currentSubBeat: Int = 0
    private var lastBeatTime: CFAbsoluteTime = 0

    // isPlaying is read on schedulerQueue and written from any thread,
    // so accesses are serialised with a lock to prevent a data race.
    private let stateLock = NSLock()
    private var _isPlaying = false
    private(set) var isPlaying: Bool {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _isPlaying
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            _isPlaying = newValue
        }
    }

    var onBeat: ((Int) -> Void)?
    var onSubBeat: ((Int, Int) -> Void)?
    var onStop: (() -> Void)?
    var onResume: (() -> Void)?

    private var interruptedWhilePlaying = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @discardableResult
    func start(bpm: Int, beatsPerMeasure: Int, subdivisionsPerBeat: Int = 1) -> Bool {
        stop()

        let audioReady = setupAudio()
        self.bpm = bpm
        self.beatsPerMeasure = beatsPerMeasure
        self.subdivisionsPerBeat = subdivisionsPerBeat
        currentBeat = 0
        currentSubBeat = 0
        lastBeatTime = 0
        isPlaying = audioReady

        if audioReady {
            startScheduler()
        }
        return audioReady
    }

    func stop() {
        scheduler?.cancel()
        scheduler = nil

        if let player = playerNode {
            player.stop()
            audioEngine?.detach(player)
        }
        playerNode = nil

        audioEngine?.stop()
        audioEngine = nil

        isPlaying = false
        interruptedWhilePlaying = false

        let session = AVAudioSession.sharedInstance()
        if session.category != .playAndRecord {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
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

    func updateSubdivision(_ count: Int) {
        schedulerQueue.async { [weak self] in
            self?.subdivisionsPerBeat = count
            self?.currentSubBeat = 0
        }
    }

    // MARK: - Private

    private func setupAudio() -> Bool {
        let session = AVAudioSession.sharedInstance()

        if session.category != .playAndRecord {
            try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try? session.setActive(true)
        }

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let bufferRate = session.sampleRate > 0 ? session.sampleRate : 44100
        let accent = ToneGenerator.makeClickBuffer(
            frequency: 880, duration: 0.06, sampleRate: bufferRate, gain: 0.9
        )
        let normal = ToneGenerator.makeClickBuffer(
            frequency: 660, duration: 0.06, sampleRate: bufferRate, gain: 0.75
        )
        let subdivision = ToneGenerator.makeClickBuffer(
            frequency: 1100, duration: 0.04, sampleRate: bufferRate, gain: 0.45
        )
        accentBuffer = accent
        normalBuffer = normal
        subdivisionBuffer = subdivision

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: accent.format)

        do {
            try engine.start()
            player.play()
            playerNode = player
            return true
        } catch {
            metLog.error("start: engine failed: \(error, privacy: .public)")
            audioEngine = nil
            return false
        }
    }

    private func startScheduler() {
        schedulerQueue.async { [weak self] in
            self?.playBeat()
        }
    }

    private func playBeat() {
        let now = CFAbsoluteTimeGetCurrent()

        if lastBeatTime > 0 && (now - lastBeatTime) > 2.0 {
            lastBeatTime = now
            currentBeat = 0
            currentSubBeat = 0
            if isPlaying { scheduleNextBeat() }
            return
        }
        lastBeatTime = now

        if let player = playerNode,
           let engine = audioEngine, engine.isRunning {
            if currentSubBeat == 0 {
                let buffer = currentBeat == 0 ? accentBuffer : normalBuffer
                if let buf = buffer { player.scheduleBuffer(buf, at: nil, options: []) }
            } else {
                if let buf = subdivisionBuffer {
                    player.scheduleBuffer(buf, at: nil, options: [])
                }
            }
        }

        let beat = currentBeat
        let subBeat = currentSubBeat
        if currentSubBeat == 0 {
            DispatchQueue.main.async { [weak self] in self?.onBeat?(beat) }
        }
        DispatchQueue.main.async { [weak self] in self?.onSubBeat?(beat, subBeat) }

        currentSubBeat += 1
        if currentSubBeat >= subdivisionsPerBeat {
            currentSubBeat = 0
            currentBeat = (currentBeat + 1) % beatsPerMeasure
        }

        guard isPlaying else { return }
        scheduleNextBeat()
    }

    private func scheduleNextBeat() {
        let interval = 60.0 / (Double(bpm) * Double(subdivisionsPerBeat))
        let timer = DispatchSource.makeTimerSource(queue: schedulerQueue)
        timer.schedule(deadline: .now() + interval, leeway: .milliseconds(1))
        timer.setEventHandler { [weak self] in
            self?.playBeat()
        }
        timer.resume()
        scheduler = timer
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeRaw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }

        let optionsRaw = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0

        schedulerQueue.async { [weak self] in
            guard let self else { return }
            switch type {
            case .began:
                self.interruptedWhilePlaying = self.isPlaying
                // Stop audio without clearing the interrupted flag
                self.scheduler?.cancel()
                self.scheduler = nil
                if let player = self.playerNode {
                    player.stop()
                    self.audioEngine?.detach(player)
                }
                self.playerNode = nil
                self.audioEngine?.stop()
                self.audioEngine = nil
                self.isPlaying = false
                DispatchQueue.main.async { [weak self] in self?.onStop?() }

            case .ended:
                let shouldResume = self.interruptedWhilePlaying
                self.interruptedWhilePlaying = false

                guard shouldResume else { return }

                let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
                guard options.contains(.shouldResume) else { return }

                self.start(bpm: self.bpm, beatsPerMeasure: self.beatsPerMeasure, subdivisionsPerBeat: self.subdivisionsPerBeat)
                DispatchQueue.main.async { [weak self] in self?.onResume?() }

            @unknown default:
                break
            }
        }
    }
}
