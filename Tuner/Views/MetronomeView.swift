// Tuner/Views/MetronomeView.swift
import SwiftUI

struct MetronomeView: View {
    @Bindable var viewModel: MetronomeViewModel

    var body: some View {
        switch viewModel.style {
        case .minimal:
            MetronomeMinimalView(viewModel: viewModel)
        case .circularGauge:
            MetronomeCircularView(viewModel: viewModel)
        }
    }
}
