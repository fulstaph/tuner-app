import AVFoundation
import os.log

private let audioLog = Logger(subsystem: "com.tunerapp", category: "AudioEngine")

protocol AudioEngineProtocol: AnyObject {
    var onBuffer: (([Float]) -> Void)? { get set }
    var sampleRate: Float { get }
    var avAudioEngine: AVAudioEngine? { get }
    func start() throws
    func stop()
}

final class AudioEngine: AudioEngineProtocol {
    private let engine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 4096

    var onBuffer: (([Float]) -> Void)?

    var sampleRate: Float {
        Float(engine.inputNode.inputFormat(forBus: 0).sampleRate)
    }

    var avAudioEngine: AVAudioEngine? { engine }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true)

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        // Force lazy creation of the output graph (mixer → output) so the
        // metronome can later attach a player to the already-running engine.
        _ = engine.mainMixerNode

        audioLog.info("AudioEngine: category=\(session.category.rawValue, privacy: .public) sampleRate=\(session.sampleRate) inputFormat=\(format, privacy: .public)")

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = Int(buffer.frameLength)
            guard frames >= 2048 else { return }
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frames))
            self?.onBuffer?(samples)
        }

        do {
            try engine.start()
            audioLog.info("AudioEngine: engine started successfully, isRunning=\(self.engine.isRunning)")
        } catch {
            audioLog.error("AudioEngine: engine.start() failed: \(error, privacy: .public)")
            throw error
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}
