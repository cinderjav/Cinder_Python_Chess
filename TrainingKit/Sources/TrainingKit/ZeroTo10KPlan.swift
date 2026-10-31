import Foundation

extension TrainingPlan {
    /// A 14-week, three-sessions-a-week run/walk plan that takes a beginner from their first minute
    /// of running to 10 km.
    ///
    /// Shape of the plan:
    /// - Weeks 1–4 (Foundation): 1–5 minute run intervals with walk breaks.
    /// - Weeks 5–8 (Build to 5K): intervals stretch until a 30-minute non-stop run.
    /// - Weeks 9–12 (Endurance): mostly continuous runs, with a long run that grows each week.
    /// - Weeks 13–14 (Race Ready): a 55-minute peak long run, a short taper, then 10 km.
    ///
    /// Weekly running time never drops before the taper, and the long run grows by at most a few
    /// minutes a week once continuous running begins.
    public static let zeroTo10K = TrainingPlan(
        name: "Zero to 10K",
        tagline: "14 weeks · 3 runs a week · from your first minute of running to 10 km",
        weeks: ZeroTo10K.weeks
    )
}

private enum ZeroTo10K {
    static func mins(_ minutes: Double) -> TimeInterval { minutes * 60 }

    static func week(
        _ number: Int,
        _ phase: PlanPhase,
        _ focus: String,
        _ days: [[Block]],
        notes: [Int: String] = [:]
    ) -> PlanWeek {
        let workouts = days.enumerated().map { index, blocks in
            PlanWorkout(week: number, day: index + 1, blocks: blocks, note: notes[index + 1])
        }
        return PlanWeek(number: number, phase: phase, focus: focus, workouts: workouts)
    }

    /// The same session on all three days.
    static func threeTimes(_ blocks: [Block]) -> [[Block]] {
        Array(repeating: blocks, count: 3)
    }

    static let weeks: [PlanWeek] = [
        // MARK: Foundation
        week(1, .foundation,
             "Short runs with plenty of walking. Keep every run easy enough to chat.",
             threeTimes([.repeats(8, run: mins(1), walk: mins(1.5))]),
             notes: [1: "Welcome! Walk briskly for the warm-up, then run slowly enough to talk in full sentences. Slow is perfect."]),
        week(2, .foundation,
             "Runs grow to 90 seconds, with equal recovery.",
             threeTimes([.repeats(7, run: mins(1.5), walk: mins(1.5))])),
        week(3, .foundation,
             "Two-minute runs, then two and a half.",
             [
                 [.repeats(6, run: mins(2), walk: mins(1.5))],
                 [.repeats(6, run: mins(2), walk: mins(1.5))],
                 [.repeats(5, run: mins(2.5), walk: mins(1.5))],
             ]),
        week(4, .foundation,
             "Up to five minutes of running at a time.",
             [
                 [.repeats(5, run: mins(3), walk: mins(1.5))],
                 [.repeats(4, run: mins(4), walk: mins(1.5))],
                 [.repeats(3, run: mins(5), walk: mins(2))],
             ]),

        // MARK: Build to 5K
        week(5, .fiveK,
             "Longer blocks, ending with two 10-minute runs.",
             [
                 [.repeats(3, run: mins(6), walk: mins(2))],
                 [.repeats(2, run: mins(8), walk: mins(2)), .run(mins(4))],
                 [.repeats(2, run: mins(10), walk: mins(2))],
             ],
             notes: [3: "Your first 10-minute runs. If you need to walk, walk. Repeating a day is part of the plan."]),
        week(6, .fiveK,
             "Fewer, longer walk breaks.",
             [
                 [.repeats(3, run: mins(7), walk: mins(2))],
                 [.repeats(2, run: mins(11), walk: mins(1.5))],
                 [.run(mins(15)), .walk(mins(2)), .run(mins(8))],
             ]),
        week(7, .fiveK,
             "Your first 25 minutes without stopping.",
             [
                 [.repeats(2, run: mins(12), walk: mins(1.5))],
                 [.run(mins(18)), .walk(mins(2)), .run(mins(7))],
                 [.run(mins(25))],
             ],
             notes: [3: "25 minutes, no walk breaks. Start slower than feels necessary."]),
        week(8, .fiveK,
             "Thirty minutes non-stop by the end of the week.",
             [
                 [.run(mins(20)), .walk(mins(1.5)), .run(mins(8))],
                 [.run(mins(28))],
                 [.run(mins(30))],
             ],
             notes: [3: "Milestone: 30 minutes non-stop. For many new runners that's about 5 km. You're halfway to 10K."]),

        // MARK: Endurance
        week(9, .endurance,
             "Run past 30 minutes. Hold a relaxed, conversational pace.",
             [
                 [.run(mins(30))],
                 [.repeats(2, run: mins(16), walk: mins(1.5))],
                 [.run(mins(34))],
             ]),
        week(10, .endurance,
             "The long run approaches 40 minutes.",
             [
                 [.run(mins(32))],
                 [.repeats(3, run: mins(12), walk: mins(1))],
                 [.run(mins(38))],
             ]),
        week(11, .endurance,
             "The long run reaches 42 minutes.",
             [
                 [.run(mins(35))],
                 [.repeats(2, run: mins(20), walk: mins(1.5))],
                 [.run(mins(42))],
             ]),
        week(12, .endurance,
             "A 45-minute session with one short break, then 46 minutes non-stop.",
             [
                 [.run(mins(38))],
                 [.run(mins(25)), .walk(mins(1)), .run(mins(20))],
                 [.run(mins(46))],
             ]),

        // MARK: Race Ready
        week(13, .raceReady,
             "Peak week: the long run hits 55 minutes.",
             [
                 [.run(mins(40))],
                 [.repeats(2, run: mins(25), walk: mins(1.5))],
                 [.run(mins(55))],
             ],
             notes: [3: "Your longest run before 10K day. Easy pace, steady breathing."]),
        week(14, .raceReady,
             "Taper with two shorter runs, then run your 10K.",
             [
                 [.run(mins(35))],
                 [.run(mins(25))],
                 [.runDistance(meters: 10_000)],
             ],
             notes: [
                 2: "Short and easy. Save your legs for 10K day.",
                 3: "10K day! Run 10 km at a relaxed pace. A short walk break is fine. Finishing is the goal.",
             ]),
    ]
}
