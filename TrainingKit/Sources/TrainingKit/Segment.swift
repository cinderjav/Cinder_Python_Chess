import Foundation

/// What the runner should be doing during a segment.
public enum SegmentKind: String, CaseIterable, Hashable, Sendable {
    case warmup
    case run
    case walk
    case cooldown

    public var displayName: String {
        switch self {
        case .warmup: return "Warm-up"
        case .run: return "Run"
        case .walk: return "Walk"
        case .cooldown: return "Cool-down"
        }
    }
}

/// When a segment ends: after a fixed amount of time, or after covering a distance.
public enum SegmentGoal: Hashable, Sendable {
    case duration(TimeInterval)
    case distance(meters: Double)
}

/// One step of a workout, e.g. "run for 90 seconds".
public struct Segment: Hashable, Sendable {
    /// Pace used to estimate how long distance-based segments take (7:00 per km).
    public static let defaultPaceSecondsPerKm: Double = 420

    public var kind: SegmentKind
    public var goal: SegmentGoal

    public init(kind: SegmentKind, goal: SegmentGoal) {
        self.kind = kind
        self.goal = goal
    }

    public static func warmup(_ seconds: TimeInterval) -> Segment {
        Segment(kind: .warmup, goal: .duration(seconds))
    }

    public static func run(_ seconds: TimeInterval) -> Segment {
        Segment(kind: .run, goal: .duration(seconds))
    }

    public static func run(meters: Double) -> Segment {
        Segment(kind: .run, goal: .distance(meters: meters))
    }

    public static func walk(_ seconds: TimeInterval) -> Segment {
        Segment(kind: .walk, goal: .duration(seconds))
    }

    public static func cooldown(_ seconds: TimeInterval) -> Segment {
        Segment(kind: .cooldown, goal: .duration(seconds))
    }

    /// The segment's length in seconds, if it is time-based.
    public var duration: TimeInterval? {
        switch goal {
        case .duration(let seconds): return seconds
        case .distance: return nil
        }
    }

    /// The segment's length in meters, if it is distance-based.
    public var distance: Double? {
        switch goal {
        case .duration: return nil
        case .distance(let meters): return meters
        }
    }

    /// How long the segment should take. Distance-based segments are estimated from `paceSecondsPerKm`.
    public func estimatedDuration(paceSecondsPerKm: Double = Segment.defaultPaceSecondsPerKm) -> TimeInterval {
        switch goal {
        case .duration(let seconds): return seconds
        case .distance(let meters): return meters / 1000 * paceSecondsPerKm
        }
    }
}
