import XCTest
@testable import TrainingKit

final class IntervalEngineTests: XCTestCase {
    func testAdvancesAtSegmentBoundaries() {
        var engine = IntervalEngine(segments: [.warmup(60), .run(30), .walk(30), .cooldown(60)])
        XCTAssertEqual(engine.update(elapsed: 10, distance: 0), [])
        XCTAssertEqual(engine.index, 0)
        XCTAssertEqual(engine.update(elapsed: 60, distance: 0), [.segmentStarted(index: 1)])
        XCTAssertEqual(engine.currentSegment, .run(30))
        XCTAssertEqual(engine.update(elapsed: 89, distance: 0), [])
        XCTAssertEqual(engine.update(elapsed: 180, distance: 0), [
            .segmentStarted(index: 2),
            .segmentStarted(index: 3),
            .finished,
        ])
        XCTAssertTrue(engine.isFinished)
        XCTAssertNil(engine.currentSegment)
        XCTAssertEqual(engine.update(elapsed: 500, distance: 0), [])
    }

    func testCatchingUpKeepsExactBoundaries() {
        // Simulates the app being suspended for a while, then waking up mid-segment.
        var engine = IntervalEngine(segments: [.warmup(60), .run(30), .walk(30), .cooldown(60)])
        XCTAssertEqual(engine.update(elapsed: 125, distance: 0), [
            .segmentStarted(index: 1),
            .segmentStarted(index: 2),
            .segmentStarted(index: 3),
        ])
        XCTAssertEqual(engine.segmentStartTime, 120)
        let status = engine.status(elapsed: 125, distance: 0)
        XCTAssertEqual(status.segmentElapsed, 5)
        XCTAssertEqual(status.segmentRemaining, 55)
        XCTAssertNil(status.next)
    }

    func testHalfwayCueOnlyForLongSegments() {
        var engine = IntervalEngine(segments: [.run(60), .run(300)])
        XCTAssertEqual(engine.update(elapsed: 30, distance: 0), [], "short segments get no halfway cue")
        XCTAssertEqual(engine.update(elapsed: 60, distance: 0), [.segmentStarted(index: 1)])
        XCTAssertEqual(engine.update(elapsed: 209, distance: 0), [])
        XCTAssertEqual(engine.update(elapsed: 210, distance: 0), [.halfway(index: 1)])
        XCTAssertEqual(engine.update(elapsed: 211, distance: 0), [], "halfway is announced once")
    }

    func testDistanceSegment() {
        var engine = IntervalEngine(segments: [.warmup(60), .run(meters: 1000), .cooldown(60)])
        XCTAssertEqual(engine.update(elapsed: 60, distance: 50), [.segmentStarted(index: 1)])
        XCTAssertEqual(engine.segmentStartDistance, 50)

        var status = engine.status(elapsed: 120, distance: 300)
        XCTAssertEqual(status.segmentDistanceRemaining, 750)
        XCTAssertNil(status.segmentRemaining)
        XCTAssertEqual(status.segmentProgress, 0.25, accuracy: 1e-9)

        XCTAssertEqual(engine.update(elapsed: 200, distance: 549), [])
        XCTAssertEqual(engine.update(elapsed: 201, distance: 550), [.halfway(index: 1)])
        XCTAssertEqual(engine.update(elapsed: 400, distance: 1050), [.segmentStarted(index: 2)])
        XCTAssertEqual(engine.segmentStartTime, 400)

        status = engine.status(elapsed: 430, distance: 1100)
        XCTAssertEqual(status.segmentRemaining, 30)
        XCTAssertEqual(engine.update(elapsed: 460, distance: 1100), [.finished])
    }

    func testSkipSegmentRestartsTheClockForTheNextSegment() {
        var engine = IntervalEngine(segments: [.run(100), .walk(100)])
        XCTAssertEqual(engine.update(elapsed: 10, distance: 0), [])
        XCTAssertEqual(engine.skipSegment(elapsed: 10, distance: 0), [.segmentStarted(index: 1)])
        XCTAssertEqual(engine.status(elapsed: 50, distance: 0).segmentRemaining, 60)
        XCTAssertEqual(engine.skipSegment(elapsed: 50, distance: 0), [.finished])
        XCTAssertEqual(engine.skipSegment(elapsed: 60, distance: 0), [])
    }

    func testOverallProgressIsWeightedByDuration() {
        var engine = IntervalEngine(segments: [.run(50), .walk(150)])
        _ = engine.update(elapsed: 25, distance: 0)
        XCTAssertEqual(engine.status(elapsed: 25, distance: 0).overallProgress, 0.125, accuracy: 1e-9)
        _ = engine.update(elapsed: 125, distance: 0)
        XCTAssertEqual(engine.status(elapsed: 125, distance: 0).overallProgress, 0.625, accuracy: 1e-9)
        _ = engine.update(elapsed: 200, distance: 0)
        XCTAssertEqual(engine.status(elapsed: 200, distance: 0).overallProgress, 1)
        XCTAssertTrue(engine.status(elapsed: 200, distance: 0).isFinished)
    }

    func testUpcomingCues() {
        var engine = IntervalEngine(segments: [.warmup(60), .run(30), .walk(30)])
        XCTAssertEqual(engine.upcomingCues(elapsed: 20), [
            .init(after: 40, event: .segmentStarted(index: 1)),
            .init(after: 70, event: .segmentStarted(index: 2)),
            .init(after: 100, event: .finished),
        ])
        _ = engine.update(elapsed: 70, distance: 0)
        XCTAssertEqual(engine.upcomingCues(elapsed: 70), [
            .init(after: 20, event: .segmentStarted(index: 2)),
            .init(after: 50, event: .finished),
        ])
    }

    func testUpcomingCuesStopAtDistanceSegments() {
        let engine = IntervalEngine(segments: [.run(30), .run(meters: 500), .walk(30)])
        XCTAssertEqual(engine.upcomingCues(elapsed: 10), [
            .init(after: 20, event: .segmentStarted(index: 1)),
        ])
    }

    func testEmptyWorkoutIsImmediatelyFinished() {
        var engine = IntervalEngine(segments: [])
        XCTAssertTrue(engine.isFinished)
        XCTAssertEqual(engine.update(elapsed: 10, distance: 0), [])
        XCTAssertTrue(engine.status(elapsed: 0, distance: 0).isFinished)
    }

    func testRunsAWholePlanWorkout() throws {
        let workout = try XCTUnwrap(TrainingPlan.zeroTo10K.workout(withID: "w1d1"))
        var engine = IntervalEngine(segments: workout.segments)
        var started = 0
        var finished = false
        var t: TimeInterval = 0
        while t <= workout.estimatedDuration() + 1 {
            for event in engine.update(elapsed: t, distance: 0) {
                if case .segmentStarted = event { started += 1 }
                if event == .finished { finished = true }
            }
            t += 0.5
        }
        XCTAssertEqual(started, workout.segments.count - 1)
        XCTAssertTrue(finished)
    }
}
