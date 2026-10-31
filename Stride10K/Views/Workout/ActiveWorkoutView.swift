import SwiftUI
import TrainingKit

/// Full-screen view shown while a workout is running, then its summary.
struct ActiveWorkoutView: View {
    @Environment(WorkoutSession.self) private var session

    var body: some View {
        if let result = session.result {
            WorkoutSummaryView(result: result)
        } else {
            WorkoutInProgressView()
        }
    }
}

private struct WorkoutInProgressView: View {
    @Environment(WorkoutSession.self) private var session
    @AppStorage(SettingsKey.distanceUnit) private var unit: DistanceUnit = .kilometers
    @State private var confirmingEnd = false

    private var tint: Color {
        if let segment = session.status?.segment {
            return segment.kind.color
        }
        return session.kind.color
    }

    var body: some View {
        VStack(spacing: 20) {
            header
            Spacer(minLength: 0)
            if let status = session.status, let segment = status.segment {
                intervalDisplay(status: status, segment: segment)
            } else {
                freeDisplay
            }
            Spacer(minLength: 0)
            stats
            controls
        }
        .padding()
        .background(tint.opacity(0.12).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: session.status?.index)
        .confirmationDialog("End this workout?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) { session.end() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            if session.planWorkout != nil {
                Text("You haven't finished every segment yet. You can still save what you've done.")
            }
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 4) {
            Text(session.planWorkout?.title ?? session.kind.displayName)
                .font(.headline)
            if session.state == .paused {
                Text("Paused")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            } else if let workout = session.planWorkout {
                Text(workout.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }

    private func intervalDisplay(status: IntervalEngine.Status, segment: Segment) -> some View {
        VStack(spacing: 16) {
            Label(segment.kind.displayName.uppercased(), systemImage: segment.kind.systemImage)
                .font(.title2.weight(.heavy))
                .foregroundStyle(segment.kind.color)
                .contentTransition(.opacity)

            ZStack {
                Circle()
                    .stroke(segment.kind.color.opacity(0.2), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: status.segmentProgress)
                    .stroke(segment.kind.color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: status.segmentProgress)
                VStack(spacing: 2) {
                    if let remaining = status.segmentRemaining {
                        Text(Format.clock(remaining, roundingUp: true))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("remaining")
                            .foregroundStyle(.secondary)
                    } else if let meters = status.segmentDistanceRemaining {
                        Text(Format.distanceValue(meters, unit: unit))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("\(unit.abbreviation) to go")
                            .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(28)
            }
            .frame(width: 260, height: 260)

            Group {
                if let next = status.next {
                    Text("Next: \(next.kind.displayName) \(next.goalText)")
                } else {
                    Text("Last segment. Almost done!")
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                ProgressView(value: status.overallProgress)
                    .tint(segment.kind.color)
                Text("Segment \(status.index + 1) of \(session.segmentCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var freeDisplay: some View {
        VStack(spacing: 8) {
            Image(systemName: session.kind.systemImage)
                .font(.system(size: 48))
                .foregroundStyle(session.kind.color)
            Text(Format.clock(session.elapsed))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(Format.distance(session.distance, unit: unit))
                .font(.title.weight(.semibold))
                .monospacedDigit()
        }
    }

    private var stats: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                StatTile(title: "Time", value: Format.clock(session.elapsed), systemImage: "clock")
                StatTile(
                    title: "Distance",
                    value: Format.distance(session.distance, unit: unit),
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                )
            }
            GridRow {
                StatTile(
                    title: "Avg pace",
                    value: Format.pace(duration: session.elapsed, meters: session.distance, unit: unit),
                    systemImage: "speedometer"
                )
                StatTile(title: "Steps", value: session.steps.formatted(), systemImage: "shoeprints.fill")
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var controls: some View {
        HStack(spacing: 36) {
            ControlButton(systemImage: "stop.fill", label: "End", tint: .red, size: 64) {
                confirmingEnd = true
            }
            if session.state == .paused {
                ControlButton(systemImage: "play.fill", label: "Resume", tint: .green, size: 84) {
                    session.resume()
                }
            } else {
                ControlButton(systemImage: "pause.fill", label: "Pause", tint: tint, size: 84) {
                    session.pause()
                }
            }
            if session.planWorkout != nil {
                ControlButton(systemImage: "forward.end.fill", label: "Skip segment", tint: .gray, size: 64) {
                    session.skipSegment()
                }
            } else {
                // Keeps the pause button centered.
                Color.clear.frame(width: 64, height: 64)
            }
        }
        .padding(.bottom, 8)
    }
}

private struct ControlButton: View {
    let systemImage: String
    let label: String
    let tint: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(tint, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
