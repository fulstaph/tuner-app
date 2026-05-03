// Tuner/Audio/ToneGenerator.swift
import AVFoundation

enum ToneGenerator {
    static func makeClickBuffer(frequency: Float, duration: Double, sampleRate: Double = 44100) -> AVAudioPCMBuffer {
        let frameCount = Int(duration * sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)

        let channelData = buffer.floatChannelData![0]
        let attackSamples = Int(0.002 * sampleRate) // 2ms attack

        for i in 0..<frameCount {
            let sine = sinf(2.0 * .pi * frequency * Float(i) / Float(sampleRate))

            let envelope: Float
            if i < attackSamples {
                envelope = Float(i) / Float(attackSamples)
            } else {
                let decayProgress = Float(i - attackSamples) / Float(frameCount - attackSamples)
                envelope = powf(1.0 - decayProgress, 3.0)
            }

            channelData[i] = sine * envelope
        }

        return buffer
    }
}
