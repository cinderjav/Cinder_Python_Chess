import SwiftUI

struct RootView: View {
    @Environment(HealthService.self) private var health
    @Environment(MotionService.self) private var motion
    @Environment(WorkoutSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "figure.walk") }
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .fullScreenCover(isPresented: workoutPresented) {
            ActiveWorkoutView()
        }
        .sheet(isPresented: onboardingPresented) {
            OnboardingView()
        }
        .task {
            await refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                session.appWillEnterForeground()
                Task { await refresh() }
            case .background:
                session.appDidEnterBackground()
            default:
                break
            }
        }
    }

    private var workoutPresented: Binding<Bool> {
        Binding(
            get: { session.state != .idle },
            set: { isPresented in
                if !isPresented { session.reset() }
            }
        )
    }

    private var onboardingPresented: Binding<Bool> {
        Binding(get: { !hasOnboarded }, set: { _ in })
    }

    private func refresh() async {
        guard hasOnboarded else { return }
        motion.startLiveUpdates()
        await health.refresh()
        await motion.refresh()
    }
}
