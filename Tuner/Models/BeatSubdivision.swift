enum BeatSubdivision: String, CaseIterable, Identifiable {
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

    var sfSymbolName: String {
        switch self {
        case .none: "1.circle"
        case .eighths: "2.circle"
        case .triplets: "3.circle"
        case .sixteenths: "4.circle"
        }
    }
}
