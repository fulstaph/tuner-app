import Foundation

enum PersistenceKeys {
    static let hasMigratedToSwiftData = "hasMigratedToSwiftData"
    static let activePresetID = "activePresetID"

    enum Legacy {
        static let tunerStyle = "tunerStyle"
        static let instrumentPreset = "instrumentPreset"
        static let referencePitch = "referencePitch"
        static let metronomeBPM = "metronomeBPM"
        static let metronomeTimeSignature = "metronomeTimeSignature"
        static let metronomeStyle = "metronomeStyle"

        static let all: [String] = [
            tunerStyle, instrumentPreset, referencePitch,
            metronomeBPM, metronomeTimeSignature, metronomeStyle
        ]
    }
}
