import Foundation

enum AccentLevel: String, Codable, CaseIterable, Identifiable {
    case silent, weak, medium, strong

    var id: String { rawValue }
}

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case tuning, metronome, earTraining, combined

    var id: String { rawValue }
}

enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case noteIdentification, intervalIdentification

    var id: String { rawValue }
}

enum Interval: String, Codable, CaseIterable, Identifiable {
    case minor2nd, major2nd
    case minor3rd, major3rd
    case perfect4th, tritone, perfect5th
    case minor6th, major6th
    case minor7th, major7th
    case octave

    var id: String { rawValue }

    var semitones: Int {
        switch self {
        case .minor2nd: 1
        case .major2nd: 2
        case .minor3rd: 3
        case .major3rd: 4
        case .perfect4th: 5
        case .tritone: 6
        case .perfect5th: 7
        case .minor6th: 8
        case .major6th: 9
        case .minor7th: 10
        case .major7th: 11
        case .octave: 12
        }
    }
}

struct TuningNote: Codable, Hashable {
    var noteName: String
    var octave: Int
    var centOffset: Double?
}

struct CustomTuning: Codable, Hashable {
    var instrumentName: String
    var notes: [TuningNote]
}

struct TempoRamp: Codable, Hashable {
    var bpmIncrease: Int
    var everyNBars: Int
    var maxBPM: Int
}
