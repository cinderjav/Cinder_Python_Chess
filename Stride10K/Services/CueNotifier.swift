import Foundation
import UserNotifications

/// Backup for voice cues: if iOS suspends the app mid-workout (e.g. GPS is off), scheduled
/// notifications still tell the runner when to switch between running and walking.
enum CueNotifier {
    struct Cue {
        let after: TimeInterval
        let title: String
        let body: String
    }

    private static let identifierPrefix = "stride10k.cue."
    /// iOS keeps at most 64 pending notifications per app.
    private static let maxCues = 60

    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    static func schedule(_ cues: [Cue]) {
        let center = UNUserNotificationCenter.current()
        cancelAll()
        for (index, cue) in cues.prefix(maxCues).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = cue.title
            content.body = cue.body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, cue.after), repeats: false)
            let request = UNNotificationRequest(
                identifier: identifierPrefix + String(index),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    static func cancelAll() {
        let identifiers = (0..<maxCues).map { identifierPrefix + String($0) }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
