import SwiftUI

struct OnboardingView: View {
    @Environment(HealthService.self) private var health
    @Environment(MotionService.self) private var motion
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Welcome to Stride")
                    .font(.largeTitle.bold())
                Text("Track your steps, walks, and runs, then go from your first minute of running to a full 10K.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    systemImage: "shoeprints.fill",
                    title: "Daily steps",
                    text: "Live step count, distance, walking and running time, and a 10,000-step goal."
                )
                FeatureRow(
                    systemImage: "calendar",
                    title: "Zero to 10K",
                    text: "A 14-week run/walk plan, three sessions a week, with voice coaching."
                )
                FeatureRow(
                    systemImage: "heart.text.square",
                    title: "Apple Health",
                    text: "Reads your steps and saves your workouts."
                )
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await getStarted() }
                } label: {
                    Group {
                        if isRequesting {
                            ProgressView()
                        } else {
                            Text("Get Started")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequesting)

                Text("Stride will ask for access to Health, Motion & Fitness, and notifications. You can change these any time in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .interactiveDismissDisabled()
    }

    private func getStarted() async {
        isRequesting = true
        await health.requestAuthorization()
        await motion.requestAuthorization()
        await CueNotifier.requestAuthorization()
        motion.startLiveUpdates()
        await health.refresh()
        await motion.refresh()
        isRequesting = false
        hasOnboarded = true
    }
}

private struct FeatureRow: View {
    let systemImage: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
