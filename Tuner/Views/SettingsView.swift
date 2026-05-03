import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: TunerViewModel

    var body: some View {
        Form {
            Section("Display") {
                Picker("Tuner Style", selection: $viewModel.tunerStyle) {
                    ForEach(TunerStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            }

            Section("Instrument") {
                Picker("Transposition", selection: $viewModel.instrumentPreset) {
                    ForEach(InstrumentPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
            }

            Section("Reference Pitch") {
                VStack(alignment: .leading) {
                    Text("A4 = \(Int(viewModel.referencePitch)) Hz")
                        .font(.headline)
                    Slider(value: $viewModel.referencePitch, in: 415...460, step: 1)
                    HStack {
                        Text("415")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset to 440") {
                            viewModel.referencePitch = 440
                        }
                        .font(.caption)
                        Spacer()
                        Text("460")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
