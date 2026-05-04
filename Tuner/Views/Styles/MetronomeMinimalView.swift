// Tuner/Views/Styles/MetronomeMinimalView.swift
import SwiftUI

struct MetronomeMinimalView: View {
    @Bindable var viewModel: MetronomeViewModel
    @State private var isEditingBPM = false
    @State private var bpmText = ""
    @State private var showInvalidBPM = false
    @FocusState private var isBPMFieldFocused: Bool

    var body: some View {
        VStack(spacing: 40) {
            beatIndicators

            VStack(spacing: 4) {
                bpmDisplay
                Text(showInvalidBPM ? "40 – 240" : "BPM")
                    .font(.caption)
                    .foregroundStyle(showInvalidBPM ? .red : .secondary)
                    .textCase(.uppercase)
                    .kerning(2)
                    .animation(.easeOut(duration: 0.2), value: showInvalidBPM)
            }

            VStack(spacing: 20) {
                Slider(value: bpmBinding, in: 40...240, step: 1)
                    .tint(viewModel.isPlaying ? .green : .accentColor)

                controlRow
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var bpmDisplay: some View {
        if isEditingBPM {
            HStack(spacing: 12) {
                Button { cancelBPM() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                TextField("BPM", text: $bpmText)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isBPMFieldFocused)
                    .foregroundColor(bpmTextIsValid ? .primary : .red)
                    .frame(width: 140)
                    .onChange(of: bpmText) { sanitizeBPMText() }

                Button { commitBPM() } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
        } else {
            Text("\(viewModel.bpm)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .onTapGesture {
                    bpmText = "\(viewModel.bpm)"
                    showInvalidBPM = false
                    isEditingBPM = true
                    isBPMFieldFocused = true
                }
        }
    }

    private var bpmTextIsValid: Bool {
        guard let value = Int(bpmText) else { return bpmText.isEmpty }
        return (40...240).contains(value)
    }

    private func sanitizeBPMText() {
        let stripped = String(bpmText.drop(while: { $0 == "0" }))
        if stripped != bpmText {
            bpmText = stripped.isEmpty && !bpmText.isEmpty ? "" : stripped
        }
        if bpmText.count > 3 {
            bpmText = String(bpmText.prefix(3))
        }
        showInvalidBPM = false
    }

    private func commitBPM() {
        if let value = Int(bpmText), (40...240).contains(value) {
            viewModel.setBPM(value)
            isBPMFieldFocused = false
            isEditingBPM = false
            showInvalidBPM = false
        } else {
            showInvalidBPM = true
        }
    }

    private func cancelBPM() {
        isBPMFieldFocused = false
        isEditingBPM = false
        showInvalidBPM = false
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
                    .foregroundStyle(.white)
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
