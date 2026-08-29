import SwiftUI

struct SettingsView: View {
    @Bindable var tunerViewModel: TunerViewModel
    @Bindable var metronomeViewModel: MetronomeViewModel

    var body: some View {
        Form {
            Section("Tuner Display") {
                Picker("Tuner Style", selection: $tunerViewModel.tunerStyle) {
                    ForEach(TunerStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            }

            Section("Instrument") {
                Picker("Transposition", selection: $tunerViewModel.instrumentPreset) {
                    ForEach(InstrumentPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
            }

            Section("Reference Pitch") {
                VStack(alignment: .leading) {
                    Text("A4 = \(Int(tunerViewModel.referencePitch)) Hz")
                        .font(.headline)
                    Slider(value: $tunerViewModel.referencePitch, in: 415...460, step: 1)
                    HStack {
                        Text("415")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset to 440") {
                            tunerViewModel.referencePitch = 440
                        }
                        .font(.caption)
                        Spacer()
                        Text("460")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Metronome Display") {
                Picker("Metronome Style", selection: Binding(
                    get: { metronomeViewModel.style },
                    set: { metronomeViewModel.setStyle($0) }
                )) {
                    ForEach(MetronomeStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                Picker("Subdivision", selection: Binding(
                    get: { metronomeViewModel.subdivision },
                    set: { metronomeViewModel.setSubdivision($0) }
                )) {
                    ForEach(BeatSubdivision.allCases) { sub in
                        Text(sub.displayName).tag(sub)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
