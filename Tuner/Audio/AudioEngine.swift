import AVFoundation

protocol AudioEngineProtocol: AnyObject {
    var onBuffer: (([Float]) -> Void)? { get set }
    var sampleRate: Float { get }
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

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true)

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = Int(buffer.frameLength)
            guard frames >= 2048 else { return }
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frames))
            self?.onBuffer?(samples)
        }

        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}
