import SwiftData
import SwiftUI

@main
struct Stride10KApp: App {
    @State private var health = HealthService()
    @State private var motion = MotionService()
    @State private var session = WorkoutSession()

    init() {
        AppSettings.registerDefaults()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(health)
                .environment(motion)
                .environment(session)
        }
        .modelContainer(for: WorkoutRecord.self)
    }
}
