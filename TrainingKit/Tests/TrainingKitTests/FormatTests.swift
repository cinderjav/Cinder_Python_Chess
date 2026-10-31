import XCTest
@testable import TrainingKit

final class FormatTests: XCTestCase {
    func testClock() {
        XCTAssertEqual(Format.clock(0), "0:00")
        XCTAssertEqual(Format.clock(65), "1:05")
        XCTAssertEqual(Format.clock(89.9), "1:29")
        XCTAssertEqual(Format.clock(89.2, roundingUp: true), "1:30")
        XCTAssertEqual(Format.clock(3723), "1:02:03")
        XCTAssertEqual(Format.clock(-5), "0:00")
        XCTAssertEqual(Format.clock(.infinity), "0:00")
    }

    func testShortDuration() {
        XCTAssertEqual(Format.shortDuration(45), "45 sec")
        XCTAssertEqual(Format.shortDuration(60), "1 min")
        XCTAssertEqual(Format.shortDuration(90), "1:30")
        XCTAssertEqual(Format.shortDuration(55 * 60), "55 min")
    }

    func testSpokenDuration() {
        XCTAssertEqual(Format.spokenDuration(0), "0 seconds")
        XCTAssertEqual(Format.spokenDuration(1), "1 second")
        XCTAssertEqual(Format.spokenDuration(60), "1 minute")
        XCTAssertEqual(Format.spokenDuration(90), "1 minute 30 seconds")
        XCTAssertEqual(Format.spokenDuration(125), "2 minutes 5 seconds")
    }

    func testDistance() {
        XCTAssertEqual(Format.distance(2450, unit: .kilometers), "2.45 km")
        XCTAssertEqual(Format.distance(1609.344, unit: .miles), "1.00 mi")
        XCTAssertEqual(Format.distanceValue(10_000, unit: .kilometers, fractionDigits: 1), "10.0")
        XCTAssertEqual(Format.distance(-3, unit: .kilometers), "0.00 km")
    }

    func testPace() {
        XCTAssertEqual(Format.pace(duration: 1350, meters: 5000, unit: .kilometers), "4:30 /km")
        XCTAssertEqual(Format.pace(duration: 600, meters: 1609.344, unit: .miles), "10:00 /mi")
        XCTAssertEqual(Format.pace(duration: 10, meters: 5, unit: .kilometers), "--:-- /km")
        XCTAssertNil(Format.paceSeconds(duration: 0, meters: 1000, unit: .kilometers))
        XCTAssertNil(Format.paceSeconds(duration: 7200, meters: 100, unit: .kilometers), "slower than 1 h/km is noise")
    }

    func testPlanDistance() {
        XCTAssertEqual(Format.planDistance(10_000), "10 km")
        XCTAssertEqual(Format.planDistance(7_500), "7.5 km")
        XCTAssertEqual(Format.spokenPlanDistance(10_000), "10 kilometers")
        XCTAssertEqual(Format.spokenPlanDistance(1_000), "1 kilometer")
    }

    func testSpokenUnitNames() {
        XCTAssertEqual(DistanceUnit.kilometers.spokenName(count: 1), "kilometer")
        XCTAssertEqual(DistanceUnit.miles.spokenName(count: 3), "miles")
    }
}
