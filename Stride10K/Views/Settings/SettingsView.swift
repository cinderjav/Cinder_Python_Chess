import SwiftData
import SwiftUI
import TrainingKit
import UIKit

struct SettingsView: View {
    @Environment(HealthService.self) private var health
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Query private var records: [WorkoutRecord]

    @AppStorage(SettingsKey.dailyStepGoal) private var goal = AppSettings.defaultStepGoal
    @AppStorage(SettingsKey.distanceUnit) private var unit: DistanceUnit = .kilometers
    @AppStorage(SettingsKey.voiceCues) private var voiceCues = true
    @AppStorage(SettingsKey.useGPS) private var useGPS = true
    @AppStorage(SettingsKey.saveToHealth) private var saveToHealth = true
    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $goal, in: 1_000...50_000, step: 500) {
                        HStack {
                            Text("Daily step goal")
                            Spacer()
                            Text(goal.formatted())
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    Picker("Units", selection: $unit) {
                        ForEach(DistanceUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                } header: {
                    Text("Goals")
                }

                Section {
                    Toggle("Voice coaching", isOn: $voiceCues)
                    Toggle("Use GPS for distance", isOn: $useGPS)
                } header: {
                    Text("Workouts")
                } footer: {
                    Text("Voice cues tell you when to run and walk, even with the screen locked. GPS gives accurate outdoor distance and keeps cues working in the background. Without it, Stride estimates distance from your steps.")
                }

                Section {
                    Toggle("Save workouts to Health", isOn: $saveToHealth)
                    Button("Review Health Access") {
                        Task { await health.requestAuthorization() }
                    }
                    Button("Open iPhone Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                } header: {
                    Text("Apple Health & Permissions")
                } footer: {
                    Text("To change Health permissions later, open the Health app → your profile → Apps → Stride.")
                }

                Section {
                    Button("Reset Plan Progress", role: .destructive) {
                        confirmingReset = true
                    }
                } header: {
                    Text("Plan")
                } footer: {
                    Text("Starts Zero to 10K over from Week 1. Your workout history is kept.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                } footer: {
                    Text("Check with a doctor before starting a new exercise program.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset plan progress?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset Progress", role: .destructive) {
                    WorkoutStore.resetPlan(records: records, in: context)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
