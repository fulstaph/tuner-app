import Foundation
import SwiftData

@Model
final class Preset {
    @Attribute(.unique) var id: UUID
    var name: String

    var bpm: Int
    var timeSignature: TimeSignature
    var accentPattern: [AccentLevel]

    var referencePitch: Double
    var instrumentPreset: InstrumentPreset
    var customTuning: CustomTuning?

    var tempoRamp: TempoRamp?

    var tunerStyle: TunerStyle
    var metronomeStyle: MetronomeStyle

    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        bpm: Int = 120,
        timeSignature: TimeSignature = .fourFour,
        accentPattern: [AccentLevel]? = nil,
        referencePitch: Double = 440,
        instrumentPreset: InstrumentPreset = .concert,
        customTuning: CustomTuning? = nil,
        tempoRamp: TempoRamp? = nil,
        tunerStyle: TunerStyle = .needle,
        metronomeStyle: MetronomeStyle = .minimal,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.bpm = bpm
        self.timeSignature = timeSignature
        self.accentPattern = accentPattern ?? Preset.defaultAccentPattern(for: timeSignature)
        self.referencePitch = referencePitch
        self.instrumentPreset = instrumentPreset
        self.customTuning = customTuning
        self.tempoRamp = tempoRamp
        self.tunerStyle = tunerStyle
        self.metronomeStyle = metronomeStyle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }

    static func defaultAccentPattern(for timeSignature: TimeSignature) -> [AccentLevel] {
        let beats = timeSignature.beatsPerMeasure
        guard beats > 0 else { return [] }
        var pattern = [AccentLevel](repeating: .medium, count: beats)
        pattern[0] = .strong
        return pattern
    }
}
