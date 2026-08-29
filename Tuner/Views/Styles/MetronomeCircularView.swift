// Tuner/Views/Styles/MetronomeCircularView.swift
import SwiftUI

struct MetronomeCircularView: View {
    @Bindable var viewModel: MetronomeViewModel

    private var bpmProgress: Double {
        Double(viewModel.bpm - 40) / 200.0
    }

    var body: some View {
        VStack(spacing: 32) {
            bpmRing

            beatSquares

            controlRow
        }
        .padding(.horizontal)
    }

    private var bpmRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 8)

            Circle()
                .trim(from: 0, to: bpmProgress)
                .stroke(
                    viewModel.isPlaying ? Color.green : Color.accentColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: bpmProgress)

            BPMEditField(bpm: bpmBinding, fontSize: 48, fieldWidth: 120)
        }
        .frame(width: 180, height: 180)
    }

    private var beatSquares: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.timeSignature.beatsPerMeasure, id: \.self) { beat in
                RoundedRectangle(cornerRadius: 6)
                    .fill(beatColor(beat))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("\(beat + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(beatTextColor(beat))
                    }
                    .animation(.easeOut(duration: 0.15), value: viewModel.currentBeat)

                if viewModel.subdivision != .none
                    && beat < viewModel.timeSignature.beatsPerMeasure - 1 {
                    ForEach(1..<viewModel.subdivision.subdivisionsPerBeat, id: \.self) { sub in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(subBeatColor(
                                beat: beat, subBeat: sub,
                                currentBeat: viewModel.currentBeat,
                                currentSubBeat: viewModel.currentSubBeat,
                                isPlaying: viewModel.isPlaying
                            ))
                            .frame(width: 8, height: 8)
                            .animation(.easeOut(duration: 0.1), value: viewModel.currentSubBeat)
                    }
                }
            }
        }
    }

    private func beatColor(_ beat: Int) -> Color {
        beat == viewModel.currentBeat && viewModel.isPlaying
            ? Color.green : Color(.systemGray5)
    }

    private func beatTextColor(_ beat: Int) -> Color {
        beat == viewModel.currentBeat && viewModel.isPlaying
            ? .white : .primary
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(TimeSignature.allCases) { ts in
                    Button(ts.displayName) { viewModel.setTimeSignature(ts) }
                }
            } label: {
                Text(viewModel.timeSignature.displayName)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }

            Menu {
                ForEach(BeatSubdivision.allCases) { sub in
                    Button(sub.displayName) { viewModel.setSubdivision(sub) }
                }
            } label: {
                Image(systemName: viewModel.subdivision.sfSymbolName)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityLabel("Subdivision: \(viewModel.subdivision.displayName)")

            Button(action: { viewModel.setBPM(viewModel.bpm - 1) }) {
                Image(systemName: "minus")
                    .font(.body.weight(.medium))
                    .padding(10)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }

            Button(action: { viewModel.toggle() }) {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        viewModel.isPlaying ? Color.red : Color.green,
                        in: Circle()
                    )
            }

            Button(action: { viewModel.setBPM(viewModel.bpm + 1) }) {
                Image(systemName: "plus")
                    .font(.body.weight(.medium))
                    .padding(10)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }

            Button(action: { viewModel.tapTempo() }) {
                Text("TAP")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var bpmBinding: Binding<Int> {
        Binding(
            get: { viewModel.bpm },
            set: { viewModel.setBPM($0) }
        )
    }

}
