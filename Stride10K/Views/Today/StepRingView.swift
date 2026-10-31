import SwiftUI

/// Circular progress toward the daily step goal.
struct StepRingView: View {
    let steps: Int
    let goal: Int

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return Double(steps) / Double(goal)
    }

    private let lineWidth: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    AngularGradient(
                        colors: [Color.accentColor.opacity(0.7), Color.accentColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * max(min(progress, 1), 0.01))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)

            VStack(spacing: 4) {
                Image(systemName: progress >= 1 ? "checkmark.circle.fill" : "shoeprints.fill")
                    .font(.title3)
                    .foregroundStyle(progress >= 1 ? Color.green : Color.accentColor)
                Text(steps.formatted())
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("of \(goal.formatted()) steps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(lineWidth * 1.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(steps) of \(goal) steps")
        .accessibilityValue("\(Int(min(progress, 1) * 100)) percent of goal")
    }
}

#Preview {
    StepRingView(steps: 6_420, goal: 10_000)
        .frame(width: 230, height: 230)
}
