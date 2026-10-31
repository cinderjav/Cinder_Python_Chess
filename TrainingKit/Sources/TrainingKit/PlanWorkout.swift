import Foundation

/// A building block for the main set of a plan workout.
public enum Block: Hashable, Sendable {
    /// `count` repetitions of running for `run` seconds and then walking for `walk` seconds.
    case repeats(Int, run: TimeInterval, walk: TimeInterval)
    /// Run continuously for the given number of seconds.
    case run(TimeInterval)
    /// Walk for the given number of seconds.
    case walk(TimeInterval)
    /// Run until the given distance is covered.
    case runDistance(meters: Double)

    var segments: [Segment] {
        switch self {
        case let .repeats(count, run, walk):
            return (0..<max(0, count)).flatMap { _ in [Segment.run(run), Segment.walk(walk)] }
        case .run(let seconds):
            return [.run(seconds)]
        case .walk(let seconds):
            return [.walk(seconds)]
        case .runDistance(let meters):
            return [.run(meters: meters)]
        }
    }

    var summary: String {
        switch self {
        case let .repeats(count, run, walk):
            return "\(count) × (run \(Format.shortDuration(run)), walk \(Format.shortDuration(walk)))"
        case .run(let seconds):
            return "run \(Format.shortDuration(seconds))"
        case .walk(let seconds):
            return "walk \(Format.shortDuration(seconds))"
        case .runDistance(let meters):
            return "run \(Format.planDistance(meters))"
        }
    }
}

/// One session of a training plan. Every session starts with a brisk warm-up walk and ends with a cool-down walk.
public struct PlanWorkout: Identifiable, Hashable, Sendable {
    public static let warmupDuration: TimeInterval = 5 * 60
    public static let cooldownDuration: TimeInterval = 5 * 60

    /// 1-based week number.
    public let week: Int
    /// 1-based day within the week.
    public let day: Int
    /// The main set, between the warm-up and the cool-down.
    public let blocks: [Block]
    /// Optional coaching tip for this session.
    public let note: String?

    public init(week: Int, day: Int, blocks: [Block], note: String? = nil) {
        self.week = week
        self.day = day
        self.blocks = blocks
        self.note = note
    }

    /// Stable identifier used to store progress, e.g. "w3d2".
    public var id: String { "w\(week)d\(day)" }

    public var title: String { "Week \(week) · Day \(day)" }

    /// Human-readable description of the main set, e.g. "8 × (run 1 min, walk 1:30)".
    public var summary: String {
        let text = blocks.map(\.summary).joined(separator: ", then ")
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    /// All segments in order, including the warm-up and cool-down.
    public var segments: [Segment] {
        [.warmup(Self.warmupDuration)] + blocks.flatMap(\.segments) + [.cooldown(Self.cooldownDuration)]
    }

    /// Total time spent in time-based run segments.
    public var runningTime: TimeInterval {
        segments.filter { $0.kind == .run }.compactMap(\.duration).reduce(0, +)
    }

    /// Total distance of distance-based run segments, in meters.
    public var runningDistance: Double {
        segments.compactMap(\.distance).reduce(0, +)
    }

    /// The longest single run segment (distance segments are estimated at the default pace).
    public var longestRun: TimeInterval {
        segments.filter { $0.kind == .run }.map { $0.estimatedDuration() }.max() ?? 0
    }

    /// True when every segment is time-based, so the workout's length is known exactly.
    public var isTimeBased: Bool { runningDistance == 0 }

    /// Estimated total length, including warm-up and cool-down.
    public func estimatedDuration(paceSecondsPerKm: Double = Segment.defaultPaceSecondsPerKm) -> TimeInterval {
        segments.reduce(0) { $0 + $1.estimatedDuration(paceSecondsPerKm: paceSecondsPerKm) }
    }
}
