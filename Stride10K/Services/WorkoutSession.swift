import CoreMotion
import Foundation
import Observation
import TrainingKit
import UIKit

/// A finished session, shown on the summary screen before the user saves or discards it.
struct WorkoutResult: Identifiable {
    let id = UUID()
    let kind: WorkoutKind
    let planWorkout: PlanWorkout?
    let startDate: Date
    let endDate: Date
    let activeDuration: TimeInterval
    let distanceMeters: Double
    let steps: Int
    /// True if every segment of a plan workout was completed. Always true for free walks and runs.
    let completedAllSegments: Bool
}

/// Runs one workout at a time: the clock, interval transitions, voice cues, GPS and pedometer tracking.
@MainActor
@Observable
final class WorkoutSession {
    enum State {
        case idle
        case running
        case paused
        case finished
    }

    private(set) var state: State = .idle
    private(set) var kind: WorkoutKind = .run
    private(set) var planWorkout: PlanWorkout?
    /// Interval status for plan workouts; nil for free walks and runs.
    private(set) var status: IntervalEngine.Status?
    /// Active time, excluding pauses.
    private(set) var elapsed: TimeInterval = 0
    /// Meters covered (GPS when available, otherwise pedometer).
    private(set) var distance: Double = 0
    private(set) var steps = 0
    private(set) var result: WorkoutResult?

    var isActive: Bool { state == .running || state == .paused }
    var segmentCount: Int { engine?.segments.count ?? 0 }

    @ObservationIgnored private var engine: IntervalEngine?
    @ObservationIgnored private var startDate: Date?
    @ObservationIgnored private var accumulated: TimeInterval = 0
    @ObservationIgnored private var resumedAt: Date?
    @ObservationIgnored private var tickTask: Task<Void, Never>?

    // Pedometer totals since the session started, and the part of them that happened while paused.
    @ObservationIgnored private var pedometerSteps = 0
    @ObservationIgnored private var pedometerDistance: Double = 0
    @ObservationIgnored private var stepsAtPause = 0
    @ObservationIgnored private var distanceAtPause: Double = 0
    @ObservationIgnored private var pausedSteps = 0
    @ObservationIgnored private var pausedDistance: Double = 0

    @ObservationIgnored private var useGPS = false
    /// Pedometer distance covered before the first GPS fix, so switching sources doesn't lose it.
    @ObservationIgnored private var distanceBeforeFix: Double?

    @ObservationIgnored private var unit: DistanceUnit = .kilometers
    /// Whole km/mi already announced in the current free session or distance segment.
    @ObservationIgnored private var announcedUnits = 0

    private let pedometer: CMPedometer
    private let location: LocationTracker
    private let coach: VoiceCoach
    private let haptics: UINotificationFeedbackGenerator

    init() {
        pedometer = CMPedometer()
        location = LocationTracker()
        coach = VoiceCoach()
        haptics = UINotificationFeedbackGenerator()
    }

    // MARK: - Controls

    func start(_ workout: PlanWorkout) {
        begin(kind: .plan, workout: workout)
    }

    func startFree(_ kind: WorkoutKind) {
        begin(kind: kind == .walk ? .walk : .run, workout: nil)
    }

    func pause() {
        guard state == .running else { return }
        tick()
        guard state == .running else { return }
        accumulated = elapsed
        resumedAt = nil
        stepsAtPause = pedometerSteps
        distanceAtPause = pedometerDistance
        location.pause()
        state = .paused
        CueNotifier.cancelAll()
        coach.say("Paused.")
    }

    func resume() {
        guard state == .paused else { return }
        pausedSteps += max(0, pedometerSteps - stepsAtPause)
        pausedDistance += max(0, pedometerDistance - distanceAtPause)
        resumedAt = Date()
        location.resume()
        state = .running
        coach.say("Resuming.")
    }

    /// Jumps to the next segment of a plan workout.
    func skipSegment() {
        guard isActive, var engine else { return }
        updateMetrics()
        let events = engine.skipSegment(elapsed: elapsed, distance: distance)
        self.engine = engine
        status = engine.status(elapsed: elapsed, distance: distance)
        handle(events)
    }

    /// Ends the session now. Plan workouts ended early are marked as not completed.
    func end() {
        guard isActive else { return }
        finish(completedAllSegments: engine?.isFinished ?? true)
    }

    /// Clears a finished session once it has been saved or discarded.
    func reset() {
        guard !isActive else { return }
        coach.stop()
        state = .idle
        result = nil
        planWorkout = nil
        engine = nil
        status = nil
        elapsed = 0
        distance = 0
        steps = 0
    }

    // MARK: - App lifecycle

    /// If iOS might suspend the app (no GPS keeping it alive), schedule notifications for upcoming cues.
    func appDidEnterBackground() {
        guard state == .running else { return }
        tick()
        guard state == .running, !location.isTracking, let engine else { return }
        let cues = engine.upcomingCues(elapsed: elapsed).compactMap { cue -> CueNotifier.Cue? in
            guard let body = cueText(for: cue.event) else { return nil }
            return CueNotifier.Cue(after: cue.after, title: cueTitle(for: cue.event), body: body)
        }
        CueNotifier.schedule(cues)
    }

    func appWillEnterForeground() {
        CueNotifier.cancelAll()
        tick()
    }

    // MARK: - Session lifecycle

    private func begin(kind: WorkoutKind, workout: PlanWorkout?) {
        guard !isActive else { return }
        let now = Date()
        self.kind = kind
        planWorkout = workout
        engine = workout.map { IntervalEngine(segments: $0.segments) }
        result = nil
        startDate = now
        accumulated = 0
        resumedAt = now
        elapsed = 0
        distance = 0
        steps = 0
        pedometerSteps = 0
        pedometerDistance = 0
        stepsAtPause = 0
        distanceAtPause = 0
        pausedSteps = 0
        pausedDistance = 0
        distanceBeforeFix = nil
        unit = AppSettings.distanceUnit
        announcedUnits = 0
        state = .running

        coach.isEnabled = AppSettings.voiceCues
        coach.prepare()
        haptics.prepare()

        useGPS = AppSettings.useGPS
        if useGPS {
            location.start()
        }
        startPedometer(from: now)

        status = engine?.status(elapsed: 0, distance: 0)
        if engine != nil {
            announce(.segmentStarted(index: 0))
        } else {
            coach.say(kind == .walk ? "Walk started." : "Run started.")
        }
        startTicking()
    }

    private func finish(completedAllSegments: Bool) {
        guard isActive, let startDate else { return }
        updateMetrics()
        tickTask?.cancel()
        tickTask = nil
        pedometer.stopUpdates()
        location.stop()
        CueNotifier.cancelAll()

        if engine == nil {
            coach.say("Done. \(Format.distance(distance, unit: unit)) in \(Format.spokenDuration(elapsed)).")
        }
        result = WorkoutResult(
            kind: kind,
            planWorkout: planWorkout,
            startDate: startDate,
            endDate: Date(),
            activeDuration: elapsed,
            distanceMeters: distance,
            steps: steps,
            completedAllSegments: completedAllSegments
        )
        state = .finished
        haptics.notificationOccurred(.success)
    }

    // MARK: - Ticking

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.tick()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func tick() {
        guard state == .running else { return }
        updateMetrics()
        if var engine {
            let events = engine.update(elapsed: elapsed, distance: distance)
            self.engine = engine
            status = engine.status(elapsed: elapsed, distance: distance)
            handle(events)
        }
        announceSplits()
    }

    private func updateMetrics() {
        let now = Date()
        elapsed = accumulated + (resumedAt.map { now.timeIntervalSince($0) } ?? 0)
        let rawSteps = state == .paused ? stepsAtPause : pedometerSteps
        let rawDistance = state == .paused ? distanceAtPause : pedometerDistance
        steps = max(0, rawSteps - pausedSteps)
        let pedometerMoved = max(0, rawDistance - pausedDistance)
        if useGPS, location.hasFix {
            if distanceBeforeFix == nil {
                distanceBeforeFix = pedometerMoved
            }
            distance = (distanceBeforeFix ?? 0) + location.distance
        } else {
            distance = pedometerMoved
        }
    }

    private func startPedometer(from start: Date) {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: start) { [weak self] data, _ in
            guard let data, let self else { return }
            let steps = data.numberOfSteps.intValue
            let distance = data.distance?.doubleValue ?? 0
            Task { @MainActor in
                self.pedometerSteps = steps
                self.pedometerDistance = distance
            }
        }
    }

    // MARK: - Cues

    private func handle(_ events: [IntervalEngine.Event]) {
        guard !events.isEmpty else { return }
        if events.contains(.finished) {
            announce(.finished)
            finish(completedAllSegments: true)
            return
        }
        // After the app was suspended several segments may have passed at once; only announce the latest.
        if let latest = events.last(where: \.isSegmentStart) {
            announcedUnits = 0
            announce(latest)
            haptics.notificationOccurred(.success)
        } else if let other = events.last {
            announce(other)
        }
    }

    private func announce(_ event: IntervalEngine.Event) {
        guard let text = cueText(for: event) else { return }
        coach.say(text)
    }

    /// Calls out each km/mi on free sessions and distance segments (interval workouts have enough cues already).
    private func announceSplits() {
        guard state == .running else { return }
        let covered: Double
        let time: TimeInterval
        if let engine {
            guard let segment = engine.currentSegment, segment.distance != nil else { return }
            covered = distance - engine.segmentStartDistance
            time = elapsed - engine.segmentStartTime
        } else {
            covered = distance
            time = elapsed
        }
        let units = Int(max(0, covered) / unit.metersPerUnit)
        guard units > announcedUnits else { return }
        announcedUnits = units
        var text = "\(units) \(unit.spokenName(count: units)). Time, \(Format.spokenDuration(time))."
        if let pace = Format.paceSeconds(duration: time, meters: covered, unit: unit) {
            text += " Average pace, \(Format.spokenDuration(pace)) per \(unit.spokenName(count: 1))."
        }
        coach.say(text)
    }

    private func cueText(for event: IntervalEngine.Event) -> String? {
        switch event {
        case .segmentStarted(let index):
            guard let segments = engine?.segments, segments.indices.contains(index) else { return nil }
            let segment = segments[index]
            let isLastOfSeveralRuns = segment.kind == .run
                && segments[..<index].contains { $0.kind == .run }
                && !segments[(index + 1)...].contains { $0.kind == .run }
            switch (segment.kind, segment.goal) {
            case (.warmup, .duration(let seconds)):
                return "Let's go. Warm up with a brisk walk for \(Format.spokenDuration(seconds))."
            case (.run, .duration(let seconds)):
                return (isLastOfSeveralRuns ? "Last run! " : "") + "Run for \(Format.spokenDuration(seconds))."
            case (.run, .distance(let meters)):
                return "Run \(Format.spokenPlanDistance(meters)). Settle into an easy pace."
            case (.walk, .duration(let seconds)):
                return "Walk for \(Format.spokenDuration(seconds))."
            case (.cooldown, .duration(let seconds)):
                return "Nice work. Cool down with an easy walk for \(Format.spokenDuration(seconds))."
            case (_, .duration(let seconds)):
                return "\(segment.kind.displayName) for \(Format.spokenDuration(seconds))."
            case (_, .distance(let meters)):
                return "\(segment.kind.displayName) for \(Format.spokenPlanDistance(meters))."
            }
        case .halfway:
            return "Halfway there."
        case .finished:
            return "Workout complete. Great job!"
        }
    }

    private func cueTitle(for event: IntervalEngine.Event) -> String {
        switch event {
        case .segmentStarted(let index):
            guard let segments = engine?.segments, segments.indices.contains(index) else { return "Next" }
            return segments[index].kind.displayName
        case .halfway:
            return "Halfway"
        case .finished:
            return "Workout complete"
        }
    }
}

private extension IntervalEngine.Event {
    var isSegmentStart: Bool {
        if case .segmentStarted = self { return true }
        return false
    }
}
