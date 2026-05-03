import SwiftUI

struct MinimalistView: View {
    let data: TunerData

    private var tuneColor: Color {
        data.isActive && abs(data.cents) <= 5 ? .green : .orange
    }

    private var dotIndex: Int {
        let clamped = max(-50, min(50, data.cents))
        return Int(round((clamped + 50) / 100.0 * 10))
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(data.isActive ? "\(data.note)\(data.octave)" : "--")
                .font(.system(size: 80, weight: .heavy, design: .rounded))

            Text(data.isActive ? String(format: "%.1f Hz", data.frequency) : " ")
                .font(.system(size: 18, design: .monospaced))
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text(data.isActive ? String(format: "%+.0f", data.cents) : " ")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(tuneColor)
                if data.isActive {
                    Text(data.cents >= 0 ? "sharp" : "flat")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            dotStrip
            Spacer()
        }
        .padding()
    }

    private var dotStrip: some View {
        HStack(spacing: 6) {
            ForEach(0..<11, id: \.self) { i in
                let isCenter = i == 5
                let isActive = data.isActive && i == dotIndex

                Circle()
                    .fill(dotColor(index: i, isActive: isActive, isCenter: isCenter))
                    .frame(width: isActive ? 12 : 8, height: isActive ? 12 : 8)
                    .animation(.easeOut(duration: 0.15), value: dotIndex)
            }
        }
    }

    private func dotColor(index: Int, isActive: Bool, isCenter: Bool) -> Color {
        if isActive { return tuneColor }
        if isCenter { return .green.opacity(0.5) }
        return .gray.opacity(0.3)
    }
}
