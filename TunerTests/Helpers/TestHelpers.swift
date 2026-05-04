import AVFoundation
import Foundation
@testable import Tuner

enum TestHelpers {
    static func generateSineWave(
        frequency: Float,
        sampleRate: Float = 44100,
        count: Int = 4096,
        amplitude: Float = 1.0
    ) -> [Float] {
        (0..<count).map { i in
            amplitude * sinf(2.0 * .pi * frequency * Float(i) / sampleRate)
        }
    }

    static func generateSilence(count: Int = 4096) -> [Float] {
        [Float](repeating: 0, count: count)
    }
}

final class MockAudioEngine: AudioEngineProtocol {
    var onBuffer: (([Float]) -> Void)?
    let sampleRate: Float = 44100
    var avAudioEngine: AVAudioEngine? { nil }
    var didStart = false
    var didStop = false

    func start() throws {
        didStart = true
    }

    func stop() {
        didStop = true
    }

    func simulateBuffer(_ buffer: [Float]) {
        onBuffer?(buffer)
    }
}
