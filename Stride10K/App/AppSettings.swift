import Foundation
import TrainingKit

/// UserDefaults keys. Views read these with `@AppStorage`; services read them through `AppSettings`.
enum SettingsKey {
    static let dailyStepGoal = "dailyStepGoal"
    static let distanceUnit = "distanceUnit"
    static let voiceCues = "voiceCues"
    static let useGPS = "useGPS"
    static let saveToHealth = "saveToHealth"
    static let hasOnboarded = "hasOnboarded"
}

enum AppSettings {
    static let defaultStepGoal = 10_000

    /// Registers defaults so `@AppStorage` and `UserDefaults` agree before the user changes anything.
    static func registerDefaults() {
        let unit: DistanceUnit = Locale.current.measurementSystem == .metric ? .kilometers : .miles
        UserDefaults.standard.register(defaults: [
            SettingsKey.dailyStepGoal: defaultStepGoal,
            SettingsKey.distanceUnit: unit.rawValue,
            SettingsKey.voiceCues: true,
            SettingsKey.useGPS: true,
            SettingsKey.saveToHealth: true,
            SettingsKey.hasOnboarded: false,
        ])
    }

    static var distanceUnit: DistanceUnit {
        DistanceUnit(rawValue: UserDefaults.standard.string(forKey: SettingsKey.distanceUnit) ?? "") ?? .kilometers
    }

    static var voiceCues: Bool { UserDefaults.standard.bool(forKey: SettingsKey.voiceCues) }
    static var useGPS: Bool { UserDefaults.standard.bool(forKey: SettingsKey.useGPS) }
}
