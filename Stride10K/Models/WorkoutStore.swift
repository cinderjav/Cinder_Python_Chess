import Foundation
import SwiftData
import TrainingKit

/// Saving and editing workout records.
@MainActor
enum WorkoutStore {
    /// Saves a finished session locally and, if enabled, to Apple Health.
    static func save(
        _ result: WorkoutResult,
        countsTowardPlan: Bool,
        in context: ModelContext,
        health: HealthService,
        exportToHealth: Bool
    ) async {
        let record = WorkoutRecord(
            kind: result.kind,
            planWorkoutID: result.planWorkout?.id,
            startDate: result.startDate,
            endDate: result.endDate,
            activeDuration: result.activeDuration,
            distanceMeters: result.distanceMeters,
            steps: result.steps,
            completedPlan: countsTowardPlan && result.planWorkout != nil
        )
        context.insert(record)
        try? context.save()

        // Very short sessions are usually accidental; keep them out of Health.
        guard exportToHealth, result.activeDuration >= 60 else { return }
        do {
            try await health.saveWorkout(
                kind: result.kind,
                start: result.startDate,
                end: result.endDate,
                distanceMeters: result.distanceMeters
            )
            record.savedToHealth = true
            try? context.save()
        } catch {
            health.report(error)
        }
    }

    /// Marks a plan workout as done without tracking it (e.g. it was done on a treadmill).
    static func markDone(_ workout: PlanWorkout, in context: ModelContext) {
        let now = Date()
        let duration = workout.estimatedDuration()
        context.insert(WorkoutRecord(
            kind: .plan,
            planWorkoutID: workout.id,
            startDate: now.addingTimeInterval(-duration),
            endDate: now,
            activeDuration: duration,
            completedPlan: true,
            isManual: true
        ))
        try? context.save()
    }

    /// Un-marks a plan workout. Hand-made records are deleted; tracked sessions stay in history.
    static func markNotDone(_ workoutID: String, records: [WorkoutRecord], in context: ModelContext) {
        for record in records where record.planWorkoutID == workoutID && record.completedPlan {
            if record.isManual {
                context.delete(record)
            } else {
                record.completedPlan = false
            }
        }
        try? context.save()
    }

    /// Clears all plan progress while keeping tracked sessions in history.
    static func resetPlan(records: [WorkoutRecord], in context: ModelContext) {
        for record in records where record.planWorkoutID != nil {
            if record.isManual {
                context.delete(record)
            } else {
                record.completedPlan = false
            }
        }
        try? context.save()
    }
}
