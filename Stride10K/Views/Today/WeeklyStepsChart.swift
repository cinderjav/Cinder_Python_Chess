import Charts
import SwiftUI
import TrainingKit

/// Bar chart of daily steps with a dashed goal line.
struct WeeklyStepsChart: View {
    let days: [DailySteps]
    let goal: Int

    var body: some View {
        Chart {
            ForEach(days) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Steps", day.steps)
                )
                .foregroundStyle(day.steps >= goal ? Color.green : Color.accentColor)
                .cornerRadius(4)
            }
            RuleMark(y: .value("Goal", goal))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Color.secondary)
                .annotation(position: .top, alignment: .leading) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
        }
        .frame(height: 180)
        .accessibilityLabel("Steps over the last seven days")
    }
}

#Preview {
    let today = Calendar.current.startOfDay(for: Date())
    let days = (0..<7).reversed().map { offset in
        DailySteps(
            date: Calendar.current.date(byAdding: .day, value: -offset, to: today)!,
            steps: [4_200, 11_300, 8_900, 12_400, 6_100, 10_200, 7_800][offset]
        )
    }
    return WeeklyStepsChart(days: days, goal: 10_000).padding()
}
