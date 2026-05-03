import SwiftUI

struct ContentView: View {
    @State private var viewModel = TunerViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                TunerDisplayView(style: viewModel.tunerStyle, data: viewModel.tunerData)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView(viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
            }
            .onAppear { viewModel.start() }
            .onDisappear { viewModel.stop() }
        }
    }
}
