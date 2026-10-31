import CoreMotion
import Foundation
import Observation
import TrainingKit

/// Live step counting and walking/running breakdown from the iPhone's motion coprocessor.
/// Works even when Apple Health access is denied, and keeps 7 days of history on-device.
@MainActor
@Observable
final class MotionService {
    private(set) var todaySteps = 0
    /// Distance today in meters, as estimated by the pedometer.
    private(set) var todayDistance: Double = 0
    /// Time spent walking and running today.
    private(set) var breakdown = MotionBreakdown()
    /// The last 7 days of steps, oldest first, including today.
    private(set) var weeklySteps: [DailySteps] = []

    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    @ObservationIgnored private var liveDayStart: Date?

    var isStepCountingAvailable: Bool { CMPedometer.isStepCountingAvailable() }

    /// Asks for Motion & Fitness permission by making a tiny pedometer query.
    func requestAuthorization() async {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let now = Date()
        _ = await steps(from: now.addingTimeInterval(-60), to: now)
    }

    /// Streams today's step count. Safe to call repeatedly; restarts after midnight.
    func startLiveUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let dayStart = Calendar.current.startOfDay(for: Date())
        guard liveDayStart != dayStart else { return }
        pedometer.stopUpdates()
        liveDayStart = dayStart
        pedometer.startUpdates(from: dayStart) { @Sendable [weak self] data, _ in
            guard let data, let self else { return }
            let steps = data.numberOfSteps.intValue
            let distance = data.distance?.doubleValue ?? 0
            Task { @MainActor in
                self.todaySteps = steps
                self.todayDistance = distance
            }
        }
    }

    func stopLiveUpdates() {
        pedometer.stopUpdates()
        liveDayStart = nil
    }

    func refresh() async {
        await refreshWeeklySteps()
        await refreshBreakdown()
    }

    private func refreshWeeklySteps() async {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        var days: [DailySteps] = []
        for offset in (0..<7).reversed() {
            guard let start = calendar.date(byAdding: .day, value: -offset, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            let count = await steps(from: start, to: min(end, now))
            days.append(DailySteps(date: start, steps: count))
        }
        weeklySteps = days
    }

    private func refreshBreakdown() async {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let manager = activityManager
        let samples: [MotionSample] = await withCheckedContinuation { continuation in
            manager.queryActivityStarting(from: start, to: now, to: .main) { @Sendable activities, _ in
                let samples = (activities ?? []).map { activity -> MotionSample in
                    let kind: MotionSample.Kind
                    if activity.confidence == .low {
                        kind = .other
                    } else if activity.running {
                        kind = .running
                    } else if activity.walking {
                        kind = .walking
                    } else {
                        kind = .other
                    }
                    return MotionSample(start: activity.startDate, kind: kind)
                }
                continuation.resume(returning: samples)
            }
        }
        breakdown = MotionStats.breakdown(samples, until: now)
    }

    private func steps(from start: Date, to end: Date) async -> Int {
        let pedometer = self.pedometer
        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { @Sendable data, _ in
                continuation.resume(returning: data?.numberOfSteps.intValue ?? 0)
            }
        }
    }
}
