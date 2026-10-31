# Stride: steps, walks, runs, and Zero to 10K

An iOS app (SwiftUI, iOS 17+) that tracks your daily steps, walks, and runs, and coaches you through **Zero to 10K**: a 14-week run/walk plan in the spirit of beginner "couch to 5K" programs that takes you from your first minute of running to 10 km.

## Features

**Today**
- Live step count with a ring showing progress toward your daily goal (10,000 by default, adjustable)
- Walking + running distance, plus minutes spent walking vs. running (from Motion & Fitness)
- A 7-day step chart with a goal line, your daily average, and your goal streak
- "Up next" card for your next plan workout, and one-tap **Start Walk** / **Start Run**

**Zero to 10K plan**
- 14 weeks × 3 sessions, each with a 5-minute warm-up walk and a 5-minute cool-down walk
- A guided workout screen with a countdown ring, color-coded run/walk segments, what's next, overall progress, pause / skip / end
- **Voice coaching** ("Run for 1 minute 30 seconds…", "Halfway there", "Last run!") that ducks your music and works with the screen locked
- Your progress is the first workout you haven't finished, so repeating a day or week just works. Workouts can also be marked done by hand (for treadmill runs).

**Tracking**
- GPS distance and pace during workouts (falls back to pedometer distance indoors or with GPS off)
- Steps per workout, and per-km/mile split announcements on free runs and the final 10K
- Saves workouts to **Apple Health**; history tab with weekly totals
- If iOS suspends the app mid-workout (GPS off), scheduled notifications still cue each run/walk switch

## The plan

Every session is a 5-minute warm-up walk, then the main set below, then a 5-minute cool-down walk.

| Week | Phase | Day 1 | Day 2 | Day 3 |
|---|---|---|---|---|
| 1 | Foundation | 8 × (run 1 min, walk 1:30) | same | same |
| 2 | Foundation | 7 × (run 1:30, walk 1:30) | same | same |
| 3 | Foundation | 6 × (run 2 min, walk 1:30) | 6 × (run 2 min, walk 1:30) | 5 × (run 2:30, walk 1:30) |
| 4 | Foundation | 5 × (run 3 min, walk 1:30) | 4 × (run 4 min, walk 1:30) | 3 × (run 5 min, walk 2 min) |
| 5 | Build to 5K | 3 × (run 6 min, walk 2 min) | 2 × (run 8 min, walk 2 min), run 4 min | 2 × (run 10 min, walk 2 min) |
| 6 | Build to 5K | 3 × (run 7 min, walk 2 min) | 2 × (run 11 min, walk 1:30) | Run 15 min, walk 2 min, run 8 min |
| 7 | Build to 5K | 2 × (run 12 min, walk 1:30) | Run 18 min, walk 2 min, run 7 min | **Run 25 min** |
| 8 | Build to 5K | Run 20 min, walk 1:30, run 8 min | Run 28 min | **Run 30 min** (≈ 5K) |
| 9 | Endurance | Run 30 min | 2 × (run 16 min, walk 1:30) | Run 34 min |
| 10 | Endurance | Run 32 min | 3 × (run 12 min, walk 1 min) | Run 38 min |
| 11 | Endurance | Run 35 min | 2 × (run 20 min, walk 1:30) | Run 42 min |
| 12 | Endurance | Run 38 min | Run 25 min, walk 1 min, run 20 min | Run 46 min |
| 13 | Race Ready | Run 40 min | 2 × (run 25 min, walk 1:30) | Run 55 min |
| 14 | Race Ready | Run 35 min | Run 25 min | **Run 10 km** 🏁 |

Weekly running time increases every week until the week-14 taper, and the long run grows by only a few minutes a week once continuous running starts. Unit tests check both rules. The plan lives in [`ZeroTo10KPlan.swift`](TrainingKit/Sources/TrainingKit/ZeroTo10KPlan.swift) if you want to tweak it.

## Getting started

Requirements: a Mac with **Xcode 16 or later**, and an iPhone running **iOS 17 or later** (steps, motion, and GPS need a real device; the simulator runs the UI with no sensor data).

1. Open `Stride10K.xcodeproj` in Xcode.
2. Select the **Stride10K** target → **Signing & Capabilities** → pick your **Team**. If the bundle ID `com.cinderjav.Stride10K` is taken, change it to something unique.
3. Plug in your iPhone, select it as the run destination, and press **⌘R**.
4. On first launch, tap **Get Started** and allow Health, Motion & Fitness, and notifications. Location permission is requested the first time you start a workout with GPS on.

Run the unit tests with **⌘U** in Xcode, or from the command line:

```sh
cd TrainingKit && swift test
```

## Project layout

```
Stride10K.xcodeproj        Xcode project (folder-synced: new files in Stride10K/ are picked up automatically)
Stride10K/
  App/                     App entry point, settings keys and defaults
  Models/                  SwiftData WorkoutRecord + save/edit helpers
  Services/
    HealthService          HealthKit: step/distance history, saving workouts
    MotionService          CoreMotion: live steps, 7-day history, walking vs running time
    WorkoutSession         The workout engine: clock, intervals, cues, GPS + pedometer
    LocationTracker        GPS distance with accuracy and jump filtering
    VoiceCoach             Spoken cues (AVSpeechSynthesizer)
    CueNotifier            Notification fallback when the app is suspended
  Views/                   Today, Plan, Workout, History, Settings (SwiftUI)
  Assets.xcassets          App icon and accent color
Support/                   Info.plist (privacy strings, background modes) and HealthKit entitlements
TrainingKit/               Swift package with no Apple-framework dependencies: plan data, interval engine,
                           formatting, step/motion stats, and their unit tests
```

The interval engine (`TrainingKit/Sources/TrainingKit/IntervalEngine.swift`) works from total active time and distance rather than timer ticks. If iOS suspends the app, it catches up to the right segment when the app wakes, and the same logic predicts upcoming cues for background notifications.

## Notes

- **Background cues:** with GPS on, iOS keeps the app running during a workout, so voice cues play with the screen locked. With GPS off, the app may be suspended. Cues then arrive as notifications, so keep notifications enabled.
- **Step counts:** Today shows the higher of Apple Health's count (which includes Apple Watch steps) and the iPhone pedometer's live count. If Health access is denied, history comes from the pedometer's on-device 7 days.
- **Health:** this is a fitness app, not medical advice. Check with a doctor before starting a new exercise program.
