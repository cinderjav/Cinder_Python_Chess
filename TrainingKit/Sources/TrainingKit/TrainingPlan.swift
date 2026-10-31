import Foundation

/// A stage of the plan, used to group weeks.
public enum PlanPhase: String, CaseIterable, Hashable, Sendable {
    case foundation
    case fiveK
    case endurance
    case raceReady

    public var title: String {
        switch self {
        case .foundation: return "Foundation"
        case .fiveK: return "Build to 5K"
        case .endurance: return "Endurance"
        case .raceReady: return "Race Ready"
        }
    }

    public var blurb: String {
        switch self {
        case .foundation:
            return "Build the habit with short running intervals and generous walk breaks."
        case .fiveK:
            return "Stretch the intervals until you can run 30 minutes without stopping."
        case .endurance:
            return "Add time gradually. Most runs are continuous, with a longer run at the end of each week."
        case .raceReady:
            return "Hit your longest run, ease off for a few days, then run 10 km."
        }
    }
}

public struct PlanWeek: Identifiable, Hashable, Sendable {
    public let number: Int
    public let phase: PlanPhase
    /// One-line description of what the week is about.
    public let focus: String
    public let workouts: [PlanWorkout]

    public init(number: Int, phase: PlanPhase, focus: String, workouts: [PlanWorkout]) {
        self.number = number
        self.phase = phase
        self.focus = focus
        self.workouts = workouts
    }

    public var id: Int { number }

    /// Total time-based running across the week's workouts.
    public var runningTime: TimeInterval {
        workouts.reduce(0) { $0 + $1.runningTime }
    }
}

public struct TrainingPlan: Sendable {
    public let name: String
    public let tagline: String
    public let weeks: [PlanWeek]

    public init(name: String, tagline: String, weeks: [PlanWeek]) {
        self.name = name
        self.tagline = tagline
        self.weeks = weeks
    }

    /// Every workout in the order it should be done.
    public var workouts: [PlanWorkout] { weeks.flatMap(\.workouts) }

    public func workout(withID id: String) -> PlanWorkout? {
        workouts.first { $0.id == id }
    }

    /// The first workout, in plan order, that hasn't been completed.
    public func nextWorkout(completed: Set<String>) -> PlanWorkout? {
        workouts.first { !completed.contains($0.id) }
    }

    /// Number of this plan's workouts in `completed` (unknown IDs are ignored).
    public func completedCount(_ completed: Set<String>) -> Int {
        workouts.filter { completed.contains($0.id) }.count
    }

    /// Fraction of the plan completed, from 0 to 1.
    public func progress(completed: Set<String>) -> Double {
        let total = workouts.count
        guard total > 0 else { return 0 }
        return Double(completedCount(completed)) / Double(total)
    }

    public func isFinished(completed: Set<String>) -> Bool {
        nextWorkout(completed: completed) == nil
    }
}
