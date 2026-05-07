// Tuner/Views/Styles/MetronomeMinimalView.swift
import SwiftUI

struct MetronomeMinimalView: View {
    @Bindable var viewModel: MetronomeViewModel

    var body: some View {
        VStack(spacing: 40) {
            beatIndicators

            BPMEditField(bpm: bpmBinding, fontSize: 64, fieldWidth: 140)

            VStack(spacing: 20) {
                Slider(value: sliderBinding, in: 40...240, step: 1)
                    .tint(viewModel.isPlaying ? .green : .accentColor)

                controlRow
            }
            .padding(.horizontal)
        }
    }

    private var beatIndicators: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.timeSignature.beatsPerMeasure, id: \.self) { beat in
                Circle()
                    .fill(beatColor(beat))
                    .frame(width: 20, height: 20)
                    .animation(.easeOut(duration: 0.15), value: viewModel.currentBeat)

                if viewModel.subdivision != .none
                    && beat < viewModel.timeSignature.beatsPerMeasure - 1 {
                    ForEach(1..<viewModel.subdivision.subdivisionsPerBeat, id: \.self) { sub in
                        Circle()
                            .fill(subBeatColor(
                                beat: beat, subBeat: sub,
                                currentBeat: viewModel.currentBeat,
                                currentSubBeat: viewModel.currentSubBeat,
                                isPlaying: viewModel.isPlaying
                            ))
                            .frame(width: 6, height: 6)
                            .animation(.easeOut(duration: 0.1), value: viewModel.currentSubBeat)
                    }
                }
            }
        }
    }

    private func beatColor(_ beat: Int) -> Color {
        beat == viewModel.currentBeat && viewModel.isPlaying
            ? Color.green : Color(.systemGray4)
    }

    private var controlRow: some View {
        HStack(spacing: 24) {
            Menu {
                ForEach(TimeSignature.allCases) { ts in
                    Button(ts.displayName) { viewModel.setTimeSignature(ts) }
                }
            } label: {
                Text(viewModel.timeSignature.displayName)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Color(.systemGray5),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }

            Menu {
                ForEach(BeatSubdivision.allCases) { sub in
                    Button(sub.displayName) { viewModel.setSubdivision(sub) }
                }
            } label: {
                Image(systemName: viewModel.subdivision.sfSymbolName)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Color(.systemGray5),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
            .accessibilityLabel("Subdivision: \(viewModel.subdivision.displayName)")

            Button(action: { viewModel.toggle() }) {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        viewModel.isPlaying ? Color.red : Color.green,
                        in: Circle()
                    )
            }

            Button(action: { viewModel.tapTempo() }) {
                Text("TAP")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Color(.systemGray5),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
        }
    }

    private var bpmBinding: Binding<Int> {
        Binding(
            get: { viewModel.bpm },
            set: { viewModel.setBPM($0) }
        )
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.bpm) },
            set: { viewModel.setBPM(Int($0)) }
        )
    }

}
