import Foundation

/// Step total for one calendar day. `date` is the start of the day.
public struct DailySteps: Identifiable, Hashable, Sendable {
    public let date: Date
    public let steps: Int

    public init(date: Date, steps: Int) {
        self.date = date
        self.steps = steps
    }

    public var id: Date { date }
}

public enum StepStats {
    /// Consecutive days that met `goal`, counting back from `today`.
    /// Today counts once the goal is met. Until then, the streak runs up to yesterday, so it isn't broken mid-day.
    public static func streak(
        _ days: [DailySteps],
        goal: Int,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard goal > 0 else { return 0 }
        var stepsByDay: [Date: Int] = [:]
        for day in days {
            stepsByDay[calendar.startOfDay(for: day.date), default: 0] += day.steps
        }
        var day = calendar.startOfDay(for: today)
        if (stepsByDay[day] ?? 0) < goal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while (stepsByDay[day] ?? 0) >= goal {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// Average daily steps, optionally leaving out today (which is usually incomplete).
    public static func average(
        _ days: [DailySteps],
        excludingToday: Bool = true,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let included = excludingToday
            ? days.filter { !calendar.isDate($0.date, inSameDayAs: today) }
            : days
        guard !included.isEmpty else { return 0 }
        return included.reduce(0) { $0 + $1.steps } / included.count
    }
}

/// A simplified motion-activity sample (mirrors what CoreMotion reports).
public struct MotionSample: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case walking
        case running
        case other
    }

    public let start: Date
    public let kind: Kind

    public init(start: Date, kind: Kind) {
        self.start = start
        self.kind = kind
    }
}

public struct MotionBreakdown: Equatable, Sendable {
    public var walking: TimeInterval
    public var running: TimeInterval

    public init(walking: TimeInterval = 0, running: TimeInterval = 0) {
        self.walking = walking
        self.running = running
    }
}

public enum MotionStats {
    /// Totals walking and running time. Each sample lasts until the next one starts, or until `end` for the last one.
    /// A single sample is capped at `maxSpan` so a stale reading can't inflate the totals.
    public static func breakdown(
        _ samples: [MotionSample],
        until end: Date,
        maxSpan: TimeInterval = 3 * 60 * 60
    ) -> MotionBreakdown {
        let sorted = samples.sorted { $0.start < $1.start }
        var result = MotionBreakdown()
        for (i, sample) in sorted.enumerated() {
            let sampleEnd = i + 1 < sorted.count ? sorted[i + 1].start : end
            let span = min(maxSpan, max(0, sampleEnd.timeIntervalSince(sample.start)))
            switch sample.kind {
            case .walking: result.walking += span
            case .running: result.running += span
            case .other: break
            }
        }
        return result
    }
}
