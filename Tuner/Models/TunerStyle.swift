enum TunerStyle: String, CaseIterable, Identifiable {
    case needle
    case linearBar
    case minimalist

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .needle: "Needle Gauge"
        case .linearBar: "Linear Bar"
        case .minimalist: "Minimalist"
        }
    }
}
