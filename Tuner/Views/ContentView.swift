import SwiftUI

struct ContentView: View {
    @State private var tunerViewModel = TunerViewModel()
    @State private var metronomeViewModel = MetronomeViewModel()
    @State private var showSettings = false

    var body: some View {
        TabView {
            NavigationStack {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    TunerDisplayView(style: tunerViewModel.tunerStyle, data: tunerViewModel.tunerData)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .tabItem {
                Label("Tuner", systemImage: "tuningfork")
            }

            NavigationStack {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    MetronomeView(viewModel: metronomeViewModel)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .tabItem {
                Label("Metronome", systemImage: "metronome")
            }
        }
        .onAppear { tunerViewModel.start() }
        .onDisappear { tunerViewModel.stop() }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(tunerViewModel: tunerViewModel, metronomeViewModel: metronomeViewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
    }
}
