enum InstrumentPreset: String, CaseIterable, Identifiable, Codable {
    case concert
    case bFlat
    case eFlat
    case f
    case a

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .concert: "Concert Pitch (C)"
        case .bFlat: "B♭ (Clarinet, Trumpet)"
        case .eFlat: "E♭ (Alto Sax)"
        case .f: "F (French Horn)"
        case .a: "A (Oboe d'amore)"
        }
    }

    var semitoneShift: Int {
        switch self {
        case .concert: 0
        case .bFlat: 2
        case .eFlat: -3
        case .f: 7
        case .a: 3
        }
    }
}
