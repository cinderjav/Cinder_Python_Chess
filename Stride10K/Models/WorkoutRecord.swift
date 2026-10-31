import Foundation
import SwiftData
import TrainingKit

enum WorkoutKind: String, Codable, CaseIterable {
    /// A guided session from the 10K plan.
    case plan
    /// A free run.
    case run
    /// A free walk.
    case walk

    var displayName: String {
        switch self {
        case .plan: return "Plan Workout"
        case .run: return "Run"
        case .walk: return "Walk"
        }
    }

    var systemImage: String {
        switch self {
        case .plan: return "list.bullet.clipboard"
        case .run: return "figure.run"
        case .walk: return "figure.walk"
        }
    }
}

/// A saved walk, run, or plan session.
@Model
final class WorkoutRecord {
    var id: UUID = UUID()
    var kindRaw: String = WorkoutKind.run.rawValue
    /// `PlanWorkout.id` (e.g. "w3d2") for plan sessions.
    var planWorkoutID: String?
    var startDate: Date = Date()
    var endDate: Date = Date()
    /// Time spent moving, excluding pauses.
    var activeDuration: TimeInterval = 0
    var distanceMeters: Double = 0
    var steps: Int = 0
    /// Whether this session counts toward plan progress.
    var completedPlan: Bool = false
    /// Marked done by hand rather than tracked.
    var isManual: Bool = false
    var savedToHealth: Bool = false

    init(
        kind: WorkoutKind,
        planWorkoutID: String? = nil,
        startDate: Date,
        endDate: Date,
        activeDuration: TimeInterval,
        distanceMeters: Double = 0,
        steps: Int = 0,
        completedPlan: Bool = false,
        isManual: Bool = false
    ) {
        self.kindRaw = kind.rawValue
        self.planWorkoutID = planWorkoutID
        self.startDate = startDate
        self.endDate = endDate
        self.activeDuration = activeDuration
        self.distanceMeters = distanceMeters
        self.steps = steps
        self.completedPlan = completedPlan
        self.isManual = isManual
    }

    var kind: WorkoutKind { WorkoutKind(rawValue: kindRaw) ?? .run }

    var planWorkout: PlanWorkout? {
        planWorkoutID.flatMap { TrainingPlan.zeroTo10K.workout(withID: $0) }
    }

    var title: String { planWorkout?.title ?? kind.displayName }
}

extension Array where Element == WorkoutRecord {
    /// IDs of plan workouts that count as done.
    var completedPlanIDs: Set<String> {
        Set(filter(\.completedPlan).compactMap(\.planWorkoutID))
    }
}
