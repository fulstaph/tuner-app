enum BeatSubdivision: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case eighths = "Eighths"
    case triplets = "Triplets"
    case sixteenths = "Sixteenths"

    var id: String { rawValue }

    var subdivisionsPerBeat: Int {
        switch self {
        case .none: 1
        case .eighths: 2
        case .triplets: 3
        case .sixteenths: 4
        }
    }

    var displayName: String { rawValue }
}
