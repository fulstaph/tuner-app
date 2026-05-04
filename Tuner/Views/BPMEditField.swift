// Tuner/Views/BPMEditField.swift
import SwiftUI

struct BPMEditField: View {
    @Binding var bpm: Int
    var fontSize: CGFloat = 48
    var fieldWidth: CGFloat = 120

    @State private var isEditing = false
    @State private var bpmText = ""
    @State private var showInvalidBPM = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            if isEditing {
                editingContent
            } else {
                displayContent
            }

            Text(showInvalidBPM ? "40 – 240" : "BPM")
                .font(.caption2)
                .foregroundStyle(showInvalidBPM ? .red : .secondary)
                .textCase(.uppercase)
                .kerning(2)
                .animation(.easeOut(duration: 0.2), value: showInvalidBPM)
        }
    }

    private var editingContent: some View {
        VStack(spacing: 6) {
            TextField("BPM", text: $bpmText)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .frame(width: fieldWidth)
                .foregroundColor(bpmTextIsValid ? .primary : .red)
                .onChange(of: bpmText) { sanitizeBPMText() }

            HStack(spacing: 20) {
                Button { cancelEditing() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Button { commitBPM() } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var displayContent: some View {
        Text("\(bpm)")
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .contentTransition(.numericText())
            .onTapGesture {
                bpmText = "\(bpm)"
                showInvalidBPM = false
                isEditing = true
                isFocused = true
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
            bpm = value
            isFocused = false
            isEditing = false
            showInvalidBPM = false
        } else {
            showInvalidBPM = true
        }
    }

    private func cancelEditing() {
        isFocused = false
        isEditing = false
        showInvalidBPM = false
    }
}
