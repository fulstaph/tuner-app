// Tuner/Views/Styles/MetronomeMinimalView.swift
import SwiftUI

struct MetronomeMinimalView: View {
    @Bindable var viewModel: MetronomeViewModel

    var body: some View {
        VStack(spacing: 40) {
            beatIndicators

            VStack(spacing: 4) {
                Text("\(viewModel.bpm)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(2)
            }

            VStack(spacing: 20) {
                Slider(value: bpmBinding, in: 40...240, step: 1)
                    .tint(viewModel.isPlaying ? .green : .accentColor)

                controlRow
            }
            .padding(.horizontal)
        }
    }

    private var beatIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<viewModel.timeSignature.beatsPerMeasure, id: \.self) { beat in
                Circle()
                    .fill(beat == viewModel.currentBeat && viewModel.isPlaying ? Color.green : Color(.systemGray4))
                    .frame(width: 20, height: 20)
                    .animation(.easeOut(duration: 0.15), value: viewModel.currentBeat)
            }
        }
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
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }

            Button(action: { viewModel.toggle() }) {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.isPlaying ? .white : .white)
                    .frame(width: 52, height: 52)
                    .background(viewModel.isPlaying ? Color.red : Color.green, in: Circle())
            }

            Button(action: { viewModel.tapTempo() }) {
                Text("TAP")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var bpmBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.bpm) },
            set: { viewModel.setBPM(Int($0)) }
        )
    }
}
