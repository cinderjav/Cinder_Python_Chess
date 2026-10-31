import XCTest
@testable import TrainingKit

final class PlanTests: XCTestCase {
    private let plan = TrainingPlan.zeroTo10K

    func testPlanHasFourteenWeeksOfThreeWorkouts() {
        XCTAssertEqual(plan.weeks.count, 14)
        XCTAssertEqual(plan.weeks.map(\.number), Array(1...14))
        for week in plan.weeks {
            XCTAssertEqual(week.workouts.count, 3, "week \(week.number)")
            XCTAssertEqual(week.workouts.map(\.day), [1, 2, 3], "week \(week.number)")
            XCTAssertTrue(week.workouts.allSatisfy { $0.week == week.number })
        }
        XCTAssertEqual(plan.workouts.count, 42)
    }

    func testWorkoutIDsAreUnique() {
        let ids = plan.workouts.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(plan.workouts.first?.id, "w1d1")
        XCTAssertEqual(plan.workouts.last?.id, "w14d3")
    }

    func testEveryWorkoutIsBookendedByWarmupAndCooldown() {
        for workout in plan.workouts {
            XCTAssertEqual(workout.segments.first, .warmup(PlanWorkout.warmupDuration), workout.id)
            XCTAssertEqual(workout.segments.last, .cooldown(PlanWorkout.cooldownDuration), workout.id)
            let middle = workout.segments.dropFirst().dropLast()
            XCTAssertTrue(middle.allSatisfy { $0.kind == .run || $0.kind == .walk }, workout.id)
            XCTAssertTrue(middle.contains { $0.kind == .run }, workout.id)
        }
    }

    func testFinalWorkoutIsATenKilometerRun() {
        let last = plan.workouts.last!
        XCTAssertEqual(last.runningDistance, 10_000)
        XCTAssertFalse(last.isTimeBased)
        XCTAssertTrue(plan.workouts.dropLast().allSatisfy(\.isTimeBased))
    }

    func testWeeklyRunningTimeNeverDropsBeforeTheTaper() {
        let buildWeeks = plan.weeks.filter { $0.number <= 13 }
        for (previous, current) in zip(buildWeeks, buildWeeks.dropFirst()) {
            XCTAssertGreaterThanOrEqual(
                current.runningTime, previous.runningTime,
                "week \(current.number) runs less than week \(previous.number)"
            )
        }
    }

    func testLongestRunNeverShrinksBeforeTheTaper() {
        let longest = plan.weeks.filter { $0.number <= 13 }.map { week in
            week.workouts.map(\.longestRun).max() ?? 0
        }
        for (previous, current) in zip(longest, longest.dropFirst()) {
            XCTAssertGreaterThanOrEqual(current, previous)
        }
        XCTAssertEqual(longest.first, 60)
        XCTAssertEqual(longest.last, 55 * 60)
    }

    func testThirtyMinuteMilestoneAtEndOfWeekEight() {
        let workout = plan.workout(withID: "w8d3")
        XCTAssertEqual(workout?.runningTime, 30 * 60)
        XCTAssertEqual(workout?.longestRun, 30 * 60)
        XCTAssertNotNil(workout?.note)
    }

    func testSummaries() {
        XCTAssertEqual(plan.workout(withID: "w1d1")?.summary, "8 × (run 1 min, walk 1:30)")
        XCTAssertEqual(plan.workout(withID: "w5d2")?.summary, "2 × (run 8 min, walk 2 min), then run 4 min")
        XCTAssertEqual(plan.workout(withID: "w8d3")?.summary, "Run 30 min")
        XCTAssertEqual(plan.workout(withID: "w14d3")?.summary, "Run 10 km")
    }

    func testDurations() throws {
        let first = try XCTUnwrap(plan.workout(withID: "w1d1"))
        // 5 min warm-up + 8 × 2.5 min + 5 min cool-down
        XCTAssertEqual(first.estimatedDuration(), 30 * 60)
        XCTAssertEqual(first.runningTime, 8 * 60)

        let last = try XCTUnwrap(plan.workout(withID: "w14d3"))
        // 10 km at the default 7:00/km, plus warm-up and cool-down
        XCTAssertEqual(last.estimatedDuration(), 70 * 60 + 10 * 60, accuracy: 0.001)
        XCTAssertEqual(last.estimatedDuration(paceSecondsPerKm: 360), 60 * 60 + 10 * 60, accuracy: 0.001)
    }

    func testNextWorkoutFollowsPlanOrder() {
        XCTAssertEqual(plan.nextWorkout(completed: [])?.id, "w1d1")
        XCTAssertEqual(plan.nextWorkout(completed: ["w1d1"])?.id, "w1d2")
        // A skipped workout comes back as the next one.
        XCTAssertEqual(plan.nextWorkout(completed: ["w1d1", "w1d3"])?.id, "w1d2")
        let all = Set(plan.workouts.map(\.id))
        XCTAssertNil(plan.nextWorkout(completed: all))
        XCTAssertTrue(plan.isFinished(completed: all))
    }

    func testProgressIgnoresUnknownIDs() {
        XCTAssertEqual(plan.progress(completed: []), 0)
        XCTAssertEqual(plan.completedCount(["w1d1", "w1d2", "bogus"]), 2)
        XCTAssertEqual(plan.progress(completed: ["w1d1", "w1d2", "w1d3"]), 3.0 / 42.0, accuracy: 1e-9)
        XCTAssertEqual(plan.progress(completed: Set(plan.workouts.map(\.id))), 1)
    }
}
