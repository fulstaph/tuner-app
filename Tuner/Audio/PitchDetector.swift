import Accelerate

struct PitchDetector {
    struct Result {
        let frequency: Double
        let confidence: Double
    }

    let sampleRate: Float
    let confidenceThreshold: Float
    let minFrequency: Float
    let maxFrequency: Float

    init(
        sampleRate: Float = 44100,
        confidenceThreshold: Float = 0.15,
        minFrequency: Float = 32,
        maxFrequency: Float = 4186
    ) {
        self.sampleRate = sampleRate
        self.confidenceThreshold = confidenceThreshold
        self.minFrequency = minFrequency
        self.maxFrequency = maxFrequency
    }

    func detectPitch(in buffer: [Float]) -> Result? {
        let n = buffer.count
        let halfN = n / 2
        let minLag = max(2, Int(sampleRate / maxFrequency))
        let maxLag = min(halfN - 1, Int(sampleRate / minFrequency))

        guard maxLag > minLag, n >= 64 else { return nil }

        var cmndf = [Float](repeating: 1.0, count: halfN)
        var runningSum: Float = 0

        buffer.withUnsafeBufferPointer { bufPtr in
            guard let base = bufPtr.baseAddress else { return }
            var diff = [Float](repeating: 0, count: halfN)

            for tau in 1..<halfN {
                vDSP_vsub(base + tau, 1, base, 1, &diff, 1, vDSP_Length(halfN))
                var sum: Float = 0
                vDSP_dotpr(diff, 1, diff, 1, &sum, vDSP_Length(halfN))

                runningSum += sum
                cmndf[tau] = runningSum > 0 ? sum * Float(tau) / runningSum : 1.0
            }
        }

        var bestTau = -1
        for tau in minLag...maxLag where cmndf[tau] < confidenceThreshold {
            var localTau = tau
            while localTau + 1 <= maxLag, cmndf[localTau + 1] < cmndf[localTau] {
                localTau += 1
            }
            bestTau = localTau
            break
        }

        guard bestTau > 0 else { return nil }

        let refinedTau = parabolicInterpolation(cmndf: cmndf, tau: bestTau)
        let frequency = Double(sampleRate) / refinedTau
        let confidence = Double(1.0 - cmndf[bestTau])

        return Result(frequency: frequency, confidence: confidence)
    }

    private func parabolicInterpolation(cmndf: [Float], tau: Int) -> Double {
        guard tau > 0, tau < cmndf.count - 1 else { return Double(tau) }
        let s0 = Double(cmndf[tau - 1])
        let s1 = Double(cmndf[tau])
        let s2 = Double(cmndf[tau + 1])
        let denominator = 2.0 * s1 - s2 - s0
        guard abs(denominator) > 1e-10 else { return Double(tau) }
        return Double(tau) + (s2 - s0) / (2.0 * denominator)
    }
}
