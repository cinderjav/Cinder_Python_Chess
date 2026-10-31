import SwiftData
import SwiftUI
import TrainingKit
import UIKit

/// Shown when a workout ends. Nothing is stored until the user taps Save.
struct WorkoutSummaryView: View {
    let result: WorkoutResult

    @Environment(WorkoutSession.self) private var session
    @Environment(HealthService.self) private var health
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.distanceUnit) private var unit: DistanceUnit = .kilometers
    @AppStorage(SettingsKey.saveToHealth) private var saveToHealth = true
    @State private var countsTowardPlan: Bool
    @State private var isSaving = false
    @State private var confirmingDiscard = false

    init(result: WorkoutResult) {
        self.result = result
        _countsTowardPlan = State(initialValue: result.completedAllSegments)
    }

    private var isPlanFinale: Bool {
        result.planWorkout?.id == TrainingPlan.zeroTo10K.workouts.last?.id && result.completedAllSegments
    }

    private var headline: String {
        if isPlanFinale { return "You ran 10K!" }
        if let workout = result.planWorkout {
            return result.completedAllSegments ? "\(workout.title) complete!" : "Workout ended early"
        }
        return result.kind == .walk ? "Walk complete" : "Run complete"
    }

    private var symbol: String {
        if isPlanFinale { return "trophy.fill" }
        if result.planWorkout != nil && !result.completedAllSegments { return "flag.fill" }
        return "checkmark.seal.fill"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: symbol)
                            .font(.system(size: 64))
                            .foregroundStyle(isPlanFinale ? Color.orange : result.kind.color)
                            .symbolEffect(.bounce, value: result.id)
                        Text(headline)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text(result.startDate, format: .dateTime.weekday(.wide).hour().minute())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                        GridRow {
                            StatTile(title: "Time", value: Format.clock(result.activeDuration), systemImage: "clock")
                            StatTile(
                                title: "Distance",
                                value: Format.distance(result.distanceMeters, unit: unit),
                                systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                            )
                        }
                        GridRow {
                            StatTile(
                                title: "Avg pace",
                                value: Format.pace(duration: result.activeDuration, meters: result.distanceMeters, unit: unit),
                                systemImage: "speedometer"
                            )
                            StatTile(title: "Steps", value: result.steps.formatted(), systemImage: "shoeprints.fill")
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if result.planWorkout != nil && !result.completedAllSegments {
                        Toggle(isOn: $countsTowardPlan) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Count toward my plan")
                                Text("Turn on if you finished the workout another way.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    if saveToHealth && health.isAvailable && result.activeDuration >= 60 {
                        Label("Will be saved to Apple Health", systemImage: "heart.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Group {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSaving)
                .padding()
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) { confirmingDiscard = true }
                        .disabled(isSaving)
                }
            }
            .confirmationDialog("Discard this workout?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { session.reset() }
                Button("Keep", role: .cancel) {}
            }
        }
    }

    private func save() {
        isSaving = true
        Task { @MainActor in
            await WorkoutStore.save(
                result,
                countsTowardPlan: countsTowardPlan,
                in: context,
                health: health,
                exportToHealth: saveToHealth
            )
            session.reset()
        }
    }
}
