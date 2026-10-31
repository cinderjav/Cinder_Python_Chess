import SwiftData
import SwiftUI
import TrainingKit

struct PlanView: View {
    @Environment(WorkoutSession.self) private var session
    @Query private var records: [WorkoutRecord]
    @State private var showingGuide = false

    private let plan = TrainingPlan.zeroTo10K

    var body: some View {
        let completed = records.completedPlanIDs
        let next = plan.nextWorkout(completed: completed)

        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Section {
                        PlanHeader(plan: plan, completed: completed)
                        if let next {
                            Button {
                                session.start(next)
                            } label: {
                                Label("Start \(next.title)", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .listRowSeparator(.hidden)
                        }
                    }

                    ForEach(plan.weeks) { week in
                        Section {
                            ForEach(week.workouts) { workout in
                                NavigationLink(value: workout) {
                                    WorkoutRow(
                                        workout: workout,
                                        isDone: completed.contains(workout.id),
                                        isNext: workout.id == next?.id
                                    )
                                }
                                .id(workout.id)
                            }
                        } header: {
                            Text("Week \(week.number) · \(week.phase.title)")
                        } footer: {
                            Text(week.focus)
                        }
                    }
                }
                .navigationTitle(plan.name)
                .navigationDestination(for: PlanWorkout.self) { workout in
                    WorkoutDetailView(workout: workout)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingGuide = true
                        } label: {
                            Label("About the plan", systemImage: "info.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingGuide) {
                    PlanGuideView(plan: plan)
                }
                .onAppear {
                    if let next, next.id != plan.workouts.first?.id {
                        proxy.scrollTo(next.id, anchor: .center)
                    }
                }
            }
        }
    }
}

private struct PlanHeader: View {
    let plan: TrainingPlan
    let completed: Set<String>

    var body: some View {
        let done = plan.completedCount(completed)
        let total = plan.workouts.count
        VStack(alignment: .leading, spacing: 10) {
            Text(plan.tagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: plan.progress(completed: completed))
                .tint(.accentColor)
            HStack {
                Text("\(done) of \(total) workouts")
                Spacer()
                if plan.isFinished(completed: completed) {
                    Label("Plan complete!", systemImage: "trophy.fill")
                        .foregroundStyle(.orange)
                } else if let next = plan.nextWorkout(completed: completed) {
                    Text("Week \(next.week) of \(plan.weeks.count)")
                }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct WorkoutRow: View {
    let workout: PlanWorkout
    let isDone: Bool
    let isNext: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isDone ? "checkmark.circle.fill" : (isNext ? "play.circle.fill" : "circle"))
                .font(.title2)
                .foregroundStyle(isDone ? Color.green : (isNext ? Color.accentColor : Color.secondary))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Day \(workout.day)")
                        .font(.headline)
                    Spacer()
                    Text("~\(Format.shortDuration(workout.estimatedDuration()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(workout.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                SegmentTimelineView(segments: workout.segments)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isDone ? "Completed" : (isNext ? "Up next" : ""))
    }
}
