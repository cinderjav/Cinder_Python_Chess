import SwiftUI
import TrainingKit

/// Explains how the plan works and how to follow it safely.
struct PlanGuideView: View {
    let plan: TrainingPlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(plan.tagline)
                        .font(.headline)
                    Text("Every session starts with a 5-minute brisk walk and ends with a 5-minute easy walk. In between, you alternate running and walking. Runs get longer and walks get shorter until you can run for an hour, then you run 10 km.")
                }

                Section("Phases") {
                    ForEach(PlanPhase.allCases, id: \.self) { phase in
                        let weeks = plan.weeks.filter { $0.phase == phase }.map(\.number)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(phase.title).font(.headline)
                                Spacer()
                                if let first = weeks.first, let last = weeks.last {
                                    Text(first == last ? "Week \(first)" : "Weeks \(first)–\(last)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(phase.blurb)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("How to follow it") {
                    GuideTip(systemImage: "tortoise.fill", text: "Run slowly. You should be able to talk in full sentences. Pace comes later.")
                    GuideTip(systemImage: "calendar.badge.clock", text: "Take a rest day (or an easy walk) between sessions. Three sessions a week is the goal.")
                    GuideTip(systemImage: "arrow.counterclockwise", text: "Repeat a day or a week whenever you need to. The next workout is always the first one you haven't finished.")
                    GuideTip(systemImage: "speaker.wave.2.fill", text: "Put your phone away. Voice cues tell you when to run and walk, even with the screen locked.")
                    GuideTip(systemImage: "location.fill", text: "Turn on GPS in Settings for accurate distance outdoors. On a treadmill, turn it off or use “Mark as Done”.")
                }

                Section {
                    Text("Check with a doctor before starting a new exercise program, especially if you have a health condition. Stop if you feel pain, dizziness, or shortness of breath.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About the Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct GuideTip: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(.tint)
        }
    }
}
