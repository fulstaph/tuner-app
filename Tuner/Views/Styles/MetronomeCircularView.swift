// Tuner/Views/Styles/MetronomeCircularView.swift
import SwiftUI

struct MetronomeCircularView: View {
    @Bindable var viewModel: MetronomeViewModel
    @State private var isEditingBPM = false
    @State private var bpmText = ""

    private var bpmProgress: Double {
        Double(viewModel.bpm - 40) / 200.0 // 40–240 range
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

            VStack(spacing: 2) {
                bpmDisplay
                Text("BPM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(2)
            }
        }
        .frame(width: 180, height: 180)
    }

    @ViewBuilder
    private var bpmDisplay: some View {
        if isEditingBPM {
            TextField("BPM", text: $bpmText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 120)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { commitBPM() }
                    }
                }
        } else {
            Text("\(viewModel.bpm)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .onTapGesture {
                    bpmText = "\(viewModel.bpm)"
                    isEditingBPM = true
                }
        }
    }

    private func commitBPM() {
        if let value = Int(bpmText) { viewModel.setBPM(value) }
        isEditingBPM = false
    }

    private var beatSquares: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.timeSignature.beatsPerMeasure, id: \.self) { beat in
                RoundedRectangle(cornerRadius: 6)
                    .fill(beat == viewModel.currentBeat && viewModel.isPlaying ? Color.green : Color(.systemGray5))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("\(beat + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(beat == viewModel.currentBeat && viewModel.isPlaying ? .white : .primary)
                    }
                    .animation(.easeOut(duration: 0.15), value: viewModel.currentBeat)
            }
        }
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
                    .background(viewModel.isPlaying ? Color.red : Color.green, in: Circle())
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
}
