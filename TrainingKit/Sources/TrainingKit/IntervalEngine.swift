import Foundation

/// A deterministic state machine that walks through a workout's segments.
///
/// The engine doesn't own a clock. Feed it the workout's active elapsed time (excluding pauses) and the
/// distance covered so far, and it reports which segment you're in. Because it works from totals rather
/// than ticks, it catches up correctly after the app has been suspended for a while.
public struct IntervalEngine: Sendable {
    public enum Event: Equatable, Sendable {
        /// The segment at `index` has just begun.
        case segmentStarted(index: Int)
        /// The segment at `index` is half done (only for long segments).
        case halfway(index: Int)
        /// The last segment has ended.
        case finished
    }

    /// A predicted future event, for scheduling notifications while the app is in the background.
    public struct ScheduledCue: Equatable, Sendable {
        /// Seconds from now until the event happens.
        public let after: TimeInterval
        public let event: Event
    }

    public struct Status: Equatable, Sendable {
        /// Index of the current segment, or `segments.count` when finished.
        public let index: Int
        /// The current segment, or nil when finished.
        public let segment: Segment?
        public let isFinished: Bool
        /// Seconds spent in the current segment.
        public let segmentElapsed: TimeInterval
        /// Seconds left in a time-based segment.
        public let segmentRemaining: TimeInterval?
        /// Meters left in a distance-based segment.
        public let segmentDistanceRemaining: Double?
        /// Progress through the current segment, 0...1.
        public let segmentProgress: Double
        /// Progress through the whole workout, 0...1, weighted by each segment's estimated duration.
        public let overallProgress: Double
        /// The segment after the current one, if any.
        public let next: Segment?
    }

    public let segments: [Segment]
    /// Halfway cues are only given for segments at least this long.
    public var halfwayThreshold: TimeInterval = 4 * 60

    public private(set) var index = 0
    public private(set) var segmentStartTime: TimeInterval = 0
    public private(set) var segmentStartDistance: Double = 0
    public private(set) var isFinished: Bool
    private var halfwayAnnounced = false

    public init(segments: [Segment]) {
        self.segments = segments
        self.isFinished = segments.isEmpty
    }

    public var currentSegment: Segment? {
        isFinished ? nil : segments[index]
    }

    /// Advances through every segment that has ended by `elapsed` / `distance` and returns what happened, in order.
    public mutating func update(elapsed: TimeInterval, distance: Double) -> [Event] {
        var events: [Event] = []
        while !isFinished {
            let segment = segments[index]
            switch segment.goal {
            case .duration(let length):
                let inSegment = elapsed - segmentStartTime
                if inSegment >= length {
                    // Start the next segment at the exact boundary so timing doesn't drift.
                    advance(startTime: segmentStartTime + length, startDistance: distance, events: &events)
                    continue
                }
                if !halfwayAnnounced, length >= halfwayThreshold, inSegment >= length / 2 {
                    halfwayAnnounced = true
                    events.append(.halfway(index: index))
                }
            case .distance(let meters):
                let covered = distance - segmentStartDistance
                if covered >= meters {
                    advance(startTime: elapsed, startDistance: segmentStartDistance + meters, events: &events)
                    continue
                }
                if !halfwayAnnounced, covered >= meters / 2 {
                    halfwayAnnounced = true
                    events.append(.halfway(index: index))
                }
            }
            break
        }
        return events
    }

    /// Ends the current segment now and starts the next one.
    public mutating func skipSegment(elapsed: TimeInterval, distance: Double) -> [Event] {
        guard !isFinished else { return [] }
        var events: [Event] = []
        advance(startTime: elapsed, startDistance: distance, events: &events)
        return events
    }

    public func status(elapsed: TimeInterval, distance: Double) -> Status {
        guard !isFinished else {
            return Status(
                index: segments.count, segment: nil, isFinished: true,
                segmentElapsed: 0, segmentRemaining: nil, segmentDistanceRemaining: nil,
                segmentProgress: 1, overallProgress: 1, next: nil
            )
        }
        let segment = segments[index]
        let inSegment = max(0, elapsed - segmentStartTime)
        var remaining: TimeInterval?
        var distanceRemaining: Double?
        let progress: Double
        switch segment.goal {
        case .duration(let length):
            remaining = max(0, length - inSegment)
            progress = length > 0 ? min(1, inSegment / length) : 1
        case .distance(let meters):
            let covered = max(0, distance - segmentStartDistance)
            distanceRemaining = max(0, meters - covered)
            progress = meters > 0 ? min(1, covered / meters) : 1
        }
        return Status(
            index: index,
            segment: segment,
            isFinished: false,
            segmentElapsed: inSegment,
            segmentRemaining: remaining,
            segmentDistanceRemaining: distanceRemaining,
            segmentProgress: progress,
            overallProgress: overallProgress(currentSegmentProgress: progress),
            next: index + 1 < segments.count ? segments[index + 1] : nil
        )
    }

    /// Predicts upcoming segment changes, assuming the clock keeps running from `elapsed`.
    /// Stops at the first distance-based segment, because when it ends can't be known in advance.
    public func upcomingCues(elapsed: TimeInterval) -> [ScheduledCue] {
        guard !isFinished else { return [] }
        var cues: [ScheduledCue] = []
        var boundary = segmentStartTime
        for i in index..<segments.count {
            guard let length = segments[i].duration else { break }
            boundary += length
            let event: Event = i + 1 < segments.count ? .segmentStarted(index: i + 1) : .finished
            let after = boundary - elapsed
            if after > 0 {
                cues.append(ScheduledCue(after: after, event: event))
            }
        }
        return cues
    }

    private mutating func advance(startTime: TimeInterval, startDistance: Double, events: inout [Event]) {
        index += 1
        segmentStartTime = startTime
        segmentStartDistance = startDistance
        halfwayAnnounced = false
        if index >= segments.count {
            index = segments.count
            isFinished = true
            events.append(.finished)
        } else {
            events.append(.segmentStarted(index: index))
        }
    }

    private func overallProgress(currentSegmentProgress: Double) -> Double {
        let weights = segments.map { $0.estimatedDuration() }
        let total = weights.reduce(0, +)
        guard total > 0 else { return 0 }
        let done = weights.prefix(index).reduce(0, +) + weights[index] * currentSegmentProgress
        return min(1, done / total)
    }
}
