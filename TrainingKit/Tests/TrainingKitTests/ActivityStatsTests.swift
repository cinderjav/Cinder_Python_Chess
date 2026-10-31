import XCTest
@testable import TrainingKit

final class ActivityStatsTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func day(_ dayOfMonth: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: dayOfMonth, hour: hour))!
    }

    private func days(_ steps: [Int: Int]) -> [DailySteps] {
        steps.map { DailySteps(date: day($0.key), steps: $0.value) }
    }

    func testStreakDoesNotBreakBeforeTodaysGoalIsMet() {
        let history = days([27: 12_000, 28: 11_000, 29: 10_500, 30: 10_000, 31: 3_000])
        XCTAssertEqual(StepStats.streak(history, goal: 10_000, today: day(31, hour: 9), calendar: calendar), 4)
    }

    func testStreakIncludesTodayOnceGoalIsMet() {
        let history = days([27: 12_000, 28: 11_000, 29: 10_500, 30: 10_000, 31: 10_200])
        XCTAssertEqual(StepStats.streak(history, goal: 10_000, today: day(31, hour: 20), calendar: calendar), 5)
    }

    func testStreakStopsAtAMissedDay() {
        let history = days([27: 12_000, 28: 4_000, 29: 10_500, 30: 10_000, 31: 0])
        XCTAssertEqual(StepStats.streak(history, goal: 10_000, today: day(31), calendar: calendar), 2)
    }

    func testStreakTreatsMissingDaysAsMissed() {
        let history = days([27: 12_000, 30: 10_000])
        XCTAssertEqual(StepStats.streak(history, goal: 10_000, today: day(31), calendar: calendar), 1)
        XCTAssertEqual(StepStats.streak([], goal: 10_000, today: day(31), calendar: calendar), 0)
        XCTAssertEqual(StepStats.streak(history, goal: 0, today: day(31), calendar: calendar), 0)
    }

    func testAverageExcludesToday() {
        let history = days([29: 8_000, 30: 10_000, 31: 1_000])
        XCTAssertEqual(StepStats.average(history, today: day(31), calendar: calendar), 9_000)
        XCTAssertEqual(StepStats.average(history, excludingToday: false, today: day(31), calendar: calendar), 6_333)
        XCTAssertEqual(StepStats.average([], today: day(31), calendar: calendar), 0)
    }

    func testMotionBreakdown() {
        let start = day(31, hour: 8)
        let samples = [
            MotionSample(start: start.addingTimeInterval(600), kind: .running),
            MotionSample(start: start, kind: .walking),
            MotionSample(start: start.addingTimeInterval(900), kind: .other),
        ]
        let result = MotionStats.breakdown(samples, until: start.addingTimeInterval(1200))
        XCTAssertEqual(result, MotionBreakdown(walking: 600, running: 300))
    }

    func testMotionBreakdownCapsStaleSamples() {
        let start = day(31, hour: 8)
        let result = MotionStats.breakdown(
            [MotionSample(start: start, kind: .walking)],
            until: start.addingTimeInterval(5 * 3600),
            maxSpan: 3 * 3600
        )
        XCTAssertEqual(result.walking, 3 * 3600)
        XCTAssertEqual(result.running, 0)
    }
}
