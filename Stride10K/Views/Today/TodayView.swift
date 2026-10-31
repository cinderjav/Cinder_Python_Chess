import SwiftData
import SwiftUI
import TrainingKit
import UIKit

struct TodayView: View {
    @Environment(HealthService.self) private var health
    @Environment(MotionService.self) private var motion
    @Environment(WorkoutSession.self) private var session
    @AppStorage(SettingsKey.dailyStepGoal) private var goal = AppSettings.defaultStepGoal
    @AppStorage(SettingsKey.distanceUnit) private var unit: DistanceUnit = .kilometers
    @Query private var records: [WorkoutRecord]

    private let plan = TrainingPlan.zeroTo10K

    // Health includes steps from an Apple Watch; the pedometer updates live. Show whichever is further along.
    private var steps: Int { max(health.todaySteps, motion.todaySteps) }
    private var distance: Double { max(health.todayDistance, motion.todayDistance) }

    /// The last 7 days, with today's bar using the live count. Falls back to on-device pedometer history
    /// if Health has no data (e.g. access was denied).
    private var week: [DailySteps] {
        let healthWeek = Array(health.dailySteps.suffix(7))
        let source = healthWeek.contains(where: { $0.steps > 0 }) ? healthWeek : motion.weeklySteps
        return source.map { day in
            Calendar.current.isDateInToday(day.date) ? DailySteps(date: day.date, steps: max(day.steps, steps)) : day
        }
    }

    private var streak: Int {
        let history = health.dailySteps.contains(where: { $0.steps > 0 }) ? health.dailySteps : motion.weeklySteps
        var days = history.filter { !Calendar.current.isDateInToday($0.date) }
        days.append(DailySteps(date: Calendar.current.startOfDay(for: Date()), steps: steps))
        return StepStats.streak(days, goal: goal)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StepRingView(steps: steps, goal: goal)
                        .frame(width: 230, height: 230)
                        .padding(.top, 8)

                    if streak > 0 {
                        Label("\(streak)-day goal streak", systemImage: "flame.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    Card {
                        HStack {
                            StatTile(
                                title: "Distance",
                                value: Format.distance(distance, unit: unit),
                                systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                                tint: .blue
                            )
                            StatTile(
                                title: "Walking",
                                value: Format.shortDuration(motion.breakdown.walking.roundedToMinute),
                                systemImage: SegmentKind.walk.systemImage,
                                tint: SegmentKind.walk.color
                            )
                            StatTile(
                                title: "Running",
                                value: Format.shortDuration(motion.breakdown.running.roundedToMinute),
                                systemImage: SegmentKind.run.systemImage,
                                tint: SegmentKind.run.color
                            )
                        }
                    }

                    if let next = plan.nextWorkout(completed: records.completedPlanIDs) {
                        NextWorkoutCard(workout: next) { session.start(next) }
                    }

                    HStack(spacing: 12) {
                        quickStartButton(.walk)
                        quickStartButton(.run)
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("This Week").font(.headline)
                                Spacer()
                                Text("Avg \(StepStats.average(week).formatted()) / day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if week.isEmpty {
                                Text("Step history will appear here once Stride can read Health or Motion data.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                WeeklyStepsChart(days: week, goal: goal)
                            }
                        }
                    }

                    if let error = health.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Today")
            .refreshable {
                await health.refresh()
                await motion.refresh()
            }
        }
    }

    private func quickStartButton(_ kind: WorkoutKind) -> some View {
        Button {
            session.startFree(kind)
        } label: {
            Label("Start \(kind.displayName)", systemImage: kind.systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(kind.color)
        .controlSize(.large)
    }
}

private extension TimeInterval {
    /// Whole minutes, so short durations read as "12 min" rather than "12:07".
    var roundedToMinute: TimeInterval { (self / 60).rounded(.down) * 60 }
}
