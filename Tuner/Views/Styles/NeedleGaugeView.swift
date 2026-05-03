import SwiftUI

struct NeedleGaugeView: View {
    let data: TunerData

    private var needleAngle: Double {
        let clamped = max(-50, min(50, data.cents))
        return clamped / 50.0 * 70.0
    }

    private var tuneColor: Color {
        data.isActive && abs(data.cents) <= 5 ? .green : .orange
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let centerX = width / 2
            let gaugeRadius = width * 0.38
            let centerY = geo.size.height * 0.4

            ZStack {
                arc(center: CGPoint(x: centerX, y: centerY), radius: gaugeRadius)
                tickMarks(center: CGPoint(x: centerX, y: centerY), radius: gaugeRadius)
                needle(center: CGPoint(x: centerX, y: centerY), length: gaugeRadius * 0.85)
                centerDot(at: CGPoint(x: centerX, y: centerY))
                noteDisplay(at: CGPoint(x: centerX, y: centerY + gaugeRadius * 0.55))
            }
        }
        .padding()
    }

    private func arc(center: CGPoint, radius: CGFloat) -> some View {
        Path { path in
            path.addArc(center: center, radius: radius,
                       startAngle: .degrees(180 + 20), endAngle: .degrees(360 - 20),
                       clockwise: false)
        }
        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
    }

    private func tickMarks(center: CGPoint, radius: CGFloat) -> some View {
        ForEach(-5..<6, id: \.self) { tick in
            let angle = Angle.degrees(270 + Double(tick) * 14)
            let isCenter = tick == 0
            let outerPoint = pointOnCircle(center: center, radius: radius, angle: angle)
            let innerPoint = pointOnCircle(center: center, radius: radius - (isCenter ? 18 : 10), angle: angle)

            Path { path in
                path.move(to: outerPoint)
                path.addLine(to: innerPoint)
            }
            .stroke(isCenter ? Color.green : Color.gray.opacity(0.5),
                   lineWidth: isCenter ? 3 : 1.5)
        }
    }

    private func needle(center: CGPoint, length: CGFloat) -> some View {
        let angle = Angle.degrees(270 + needleAngle)
        let tip = pointOnCircle(center: center, radius: length, angle: angle)

        return Path { path in
            path.move(to: center)
            path.addLine(to: tip)
        }
        .stroke(tuneColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .animation(.easeOut(duration: 0.15), value: data.cents)
    }

    private func centerDot(at point: CGPoint) -> some View {
        Circle()
            .fill(tuneColor)
            .frame(width: 12, height: 12)
            .position(point)
    }

    private func noteDisplay(at point: CGPoint) -> some View {
        VStack(spacing: 4) {
            Text(data.isActive ? "\(data.note)\(data.octave)" : "--")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text(data.isActive ? String(format: "%.1f Hz", data.frequency) : " ")
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(data.isActive ? String(format: "%+.0f ¢", data.cents) : " ")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(tuneColor)
        }
        .position(point)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(CGFloat(angle.radians)),
            y: center.y + radius * sin(CGFloat(angle.radians))
        )
    }
}
