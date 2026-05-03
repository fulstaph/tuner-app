enum TimeSignature: String, CaseIterable, Identifiable, Codable {
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case fiveFour = "5/4"
    case sixEight = "6/8"
    case sevenEight = "7/8"

    var id: String { rawValue }

    var beatsPerMeasure: Int {
        switch self {
        case .twoFour: 2
        case .threeFour: 3
        case .fourFour: 4
        case .fiveFour: 5
        case .sixEight: 6
        case .sevenEight: 7
        }
    }

    var displayName: String { rawValue }
}
