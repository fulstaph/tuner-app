import SwiftUI

struct LinearBarView: View {
    let data: TunerData

    private var tuneColor: Color {
        data.isActive && abs(data.cents) <= 5 ? .green : .orange
    }

    private var indicatorOffset: CGFloat {
        let clamped = max(-50, min(50, data.cents))
        return CGFloat(clamped / 50.0)
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            noteLabel
            barIndicator
            centsLabel
            Spacer()
        }
        .padding(.horizontal, 30)
    }

    private var noteLabel: some View {
        VStack(spacing: 4) {
            Text(data.isActive ? "\(data.note)\(data.octave)" : "--")
                .font(.system(size: 56, weight: .bold, design: .rounded))
            Text(data.isActive ? String(format: "%.1f Hz", data.frequency) : " ")
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var barIndicator: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let centerX = trackWidth / 2
            let indicatorX = centerX + indicatorOffset * centerX

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.green)
                    .frame(width: 4, height: 26)
                    .position(x: centerX, y: geo.size.height / 2)

                ForEach([-0.5, 0.5], id: \.self) { offset in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 1, height: 14)
                        .position(x: centerX + CGFloat(offset) * centerX, y: geo.size.height / 2)
                }

                if data.isActive {
                    Circle()
                        .fill(tuneColor)
                        .frame(width: 18, height: 18)
                        .position(x: indicatorX, y: geo.size.height / 2)
                        .animation(.easeOut(duration: 0.15), value: data.cents)
                }
            }
        }
        .frame(height: 30)
    }

    private var centsLabel: some View {
        Text(data.isActive ? String(format: "%+.0f ¢", data.cents) : " ")
            .font(.system(size: 20, weight: .semibold, design: .monospaced))
            .foregroundStyle(tuneColor)
    }
}
