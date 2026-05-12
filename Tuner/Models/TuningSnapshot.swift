import Foundation
import SwiftData

@Model
final class TuningSnapshot {
    var timestamp: Date
    var noteName: String
    var octave: Int
    var centsDeviation: Double
    var frequency: Double

    init(
        timestamp: Date = Date(),
        noteName: String,
        octave: Int,
        centsDeviation: Double,
        frequency: Double
    ) {
        self.timestamp = timestamp
        self.noteName = noteName
        self.octave = octave
        self.centsDeviation = centsDeviation
        self.frequency = frequency
    }
}
