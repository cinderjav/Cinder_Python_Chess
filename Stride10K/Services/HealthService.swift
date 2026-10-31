import Foundation
import HealthKit
import Observation
import TrainingKit

/// Reads step and distance history from Apple Health and saves finished workouts to it.
@MainActor
@Observable
final class HealthService {
    enum HealthError: LocalizedError {
        case unavailable
        case notAuthorized
        case operationFailed

        var errorDescription: String? {
            switch self {
            case .unavailable: return "Health data isn't available on this device."
            case .notAuthorized: return "Stride doesn't have permission to save workouts to Health."
            case .operationFailed: return "Health couldn't complete the request."
            }
        }
    }

    private(set) var todaySteps = 0
    /// Walking + running distance today, in meters.
    private(set) var todayDistance: Double = 0
    /// One entry per day for the last 30 days, oldest first, including today.
    private(set) var dailySteps: [DailySteps] = []
    private(set) var lastError: String?

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var stepType: HKQuantityType { HKQuantityType(.stepCount) }
    private var distanceType: HKQuantityType { HKQuantityType(.distanceWalkingRunning) }

    func requestAuthorization() async {
        guard isAvailable else { return }
        let read: Set<HKObjectType> = [stepType, distanceType, HKObjectType.workoutType()]
        let share: Set<HKSampleType> = [HKObjectType.workoutType(), distanceType]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Reloads today's totals and the last 30 days of steps.
    func refresh() async {
        guard isAvailable else { return }
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -29, to: today) else { return }
        do {
            let steps = try await dailySums(of: stepType, unit: .count(), from: start, to: now)
            let distance = try await dailySums(of: distanceType, unit: .meter(), from: today, to: now)
            dailySteps = steps.map { DailySteps(date: $0.date, steps: Int($0.value.rounded())) }
            todaySteps = dailySteps.last?.steps ?? 0
            todayDistance = distance.last?.value ?? 0
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Saves a finished session as a workout in Apple Health.
    func saveWorkout(kind: WorkoutKind, start: Date, end: Date, distanceMeters: Double) async throws {
        guard isAvailable else { throw HealthError.unavailable }
        guard store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized else {
            throw HealthError.notAuthorized
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = kind == .walk ? .walking : .running
        configuration.locationType = .outdoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        try await Self.perform { builder.beginCollection(withStart: start, completion: $0) }

        if distanceMeters > 0, store.authorizationStatus(for: distanceType) == .sharingAuthorized {
            let sample = HKQuantitySample(
                type: distanceType,
                quantity: HKQuantity(unit: .meter(), doubleValue: distanceMeters),
                start: start,
                end: end
            )
            try await Self.perform { builder.add([sample], completion: $0) }
        }

        try await Self.perform { builder.endCollection(withEnd: end, completion: $0) }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.finishWorkout { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func report(_ error: Error) {
        lastError = error.localizedDescription
    }

    // MARK: - Helpers

    /// Sums a cumulative quantity per calendar day. Days without samples are reported as 0.
    private func dailySums(
        of type: HKQuantityType,
        unit: HKUnit,
        from start: Date,
        to end: Date
    ) async throws -> [(date: Date, value: Double)] {
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: start)
        let predicate = HKQuery.predicateForSamples(withStart: anchor, end: end, options: .strictStartDate)
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: predicate),
            options: .cumulativeSum,
            anchorDate: anchor,
            intervalComponents: DateComponents(day: 1)
        )
        let collection = try await descriptor.result(for: store)

        var result: [(date: Date, value: Double)] = []
        var day = anchor
        while day <= end {
            let value = collection.statistics(for: day)?.sumQuantity()?.doubleValue(for: unit) ?? 0
            result.append((date: day, value: value))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// Bridges HealthKit's `(Bool, Error?)` completion handlers to async/await.
    private static func perform(
        _ operation: (@escaping @Sendable (Bool, Error?) -> Void) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: HealthError.operationFailed)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
