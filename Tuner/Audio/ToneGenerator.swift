// Tuner/Audio/ToneGenerator.swift
import AVFoundation

enum ToneGenerator {
    static func makeClickBuffer(
        frequency: Float,
        duration: Double,
        sampleRate: Double = 44100,
        gain: Float = 1.0
    ) -> AVAudioPCMBuffer {
        let frameCount = Int(duration * sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)

        let channelData = buffer.floatChannelData![0]
        let attackSamples = Int(0.002 * sampleRate)
        let sustainSamples = Int(0.015 * sampleRate)
        let decaySamples = max(1, frameCount - attackSamples - sustainSamples)

        for i in 0..<frameCount {
            let phase = 2.0 * Float.pi * frequency * Float(i) / Float(sampleRate)
            let wave = (sinf(phase) + 0.3 * sinf(phase * 2) + 0.15 * sinf(phase * 3)) / 1.45

            let envelope: Float
            if i < attackSamples {
                envelope = Float(i) / Float(max(1, attackSamples))
            } else if i < attackSamples + sustainSamples {
                envelope = 1.0
            } else {
                let decayProgress = Float(i - attackSamples - sustainSamples) / Float(decaySamples)
                envelope = powf(1.0 - decayProgress, 2.0)
            }

            channelData[i] = min(max(wave * envelope * gain, -1.0), 1.0)
        }

        return buffer
    }
}
