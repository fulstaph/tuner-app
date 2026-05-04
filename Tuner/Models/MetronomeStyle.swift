enum MetronomeStyle: String, CaseIterable, Identifiable, Codable {
    case minimal
    case circularGauge

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal: "Minimal"
        case .circularGauge: "Circular Gauge"
        }
    }
}
