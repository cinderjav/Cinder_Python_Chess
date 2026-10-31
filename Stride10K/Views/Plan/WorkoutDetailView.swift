import SwiftData
import SwiftUI
import TrainingKit

struct WorkoutDetailView: View {
    let workout: PlanWorkout

    @Environment(WorkoutSession.self) private var session
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutRecord.startDate, order: .reverse) private var records: [WorkoutRecord]
    @AppStorage(SettingsKey.distanceUnit) private var unit: DistanceUnit = .kilometers

    private var completions: [WorkoutRecord] {
        records.filter { $0.planWorkoutID == workout.id && $0.completedPlan }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    Text(workout.summary)
                        .font(.title3.weight(.semibold))
                    SegmentTimelineView(segments: workout.segments)
                    HStack {
                        StatTile(
                            title: "Total",
                            value: "~" + Format.shortDuration(workout.estimatedDuration()),
                            systemImage: "clock"
                        )
                        if workout.isTimeBased {
                            StatTile(
                                title: "Running",
                                value: Format.shortDuration(workout.runningTime),
                                systemImage: SegmentKind.run.systemImage,
                                tint: SegmentKind.run.color
                            )
                        } else {
                            StatTile(
                                title: "Distance",
                                value: Format.planDistance(workout.runningDistance),
                                systemImage: SegmentKind.run.systemImage,
                                tint: SegmentKind.run.color
                            )
                        }
                        StatTile(
                            title: "Longest run",
                            value: Format.shortDuration(workout.longestRun),
                            systemImage: "stopwatch"
                        )
                    }
                    if let note = workout.note {
                        Label(note, systemImage: "lightbulb")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Segments") {
                ForEach(Array(workout.segments.enumerated()), id: \.offset) { index, segment in
                    HStack(spacing: 12) {
                        Image(systemName: segment.kind.systemImage)
                            .foregroundStyle(segment.kind.color)
                            .frame(width: 28)
                        Text(segment.kind.displayName)
                        Spacer()
                        Text(segment.goalText)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Segment \(index + 1): \(segment.kind.displayName), \(segment.goalText)")
                }
            }

            if !completions.isEmpty {
                Section("Completed") {
                    ForEach(completions) { record in
                        HStack {
                            Text(record.startDate, format: .dateTime.weekday().month().day())
                            Spacer()
                            if record.isManual {
                                Text("Marked done").foregroundStyle(.secondary)
                            } else {
                                Text(Format.clock(record.activeDuration))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                if record.distanceMeters > 0 {
                                    Text(Format.distance(record.distanceMeters, unit: unit))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    session.start(workout)
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if completions.isEmpty {
                    Button("Mark as Done") {
                        WorkoutStore.markDone(workout, in: context)
                    }
                    .font(.subheadline)
                } else {
                    Button("Mark as Not Done", role: .destructive) {
                        WorkoutStore.markNotDone(workout.id, records: records, in: context)
                    }
                    .font(.subheadline)
                }
            }
            .padding()
            .background(.bar)
        }
    }
}
