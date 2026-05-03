import SwiftUI

struct TunerDisplayView: View {
    let style: TunerStyle
    let data: TunerData

    var body: some View {
        switch style {
        case .needle:
            NeedleGaugeView(data: data)
        case .linearBar:
            LinearBarView(data: data)
        case .minimalist:
            MinimalistView(data: data)
        }
    }
}
