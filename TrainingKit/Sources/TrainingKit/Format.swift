import Foundation

public enum DistanceUnit: String, CaseIterable, Identifiable, Sendable {
    case kilometers
    case miles

    public var id: String { rawValue }

    public var metersPerUnit: Double {
        switch self {
        case .kilometers: return 1000
        case .miles: return 1609.344
        }
    }

    public var abbreviation: String {
        switch self {
        case .kilometers: return "km"
        case .miles: return "mi"
        }
    }

    public var displayName: String {
        switch self {
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }

    /// "kilometer" / "kilometers", for voice cues.
    public func spokenName(count: Int) -> String {
        let singular = self == .kilometers ? "kilometer" : "mile"
        return count == 1 ? singular : singular + "s"
    }
}

/// Text formatting shared by the app's views and voice cues.
public enum Format {
    /// "4:05" or "1:02:03". Countdowns should round up so a 90-second segment starts at "1:30".
    public static func clock(_ seconds: TimeInterval, roundingUp: Bool = false) -> String {
        guard seconds.isFinite else { return "0:00" }
        let value = max(0, seconds)
        let total = Int(roundingUp ? value.rounded(.up) : value.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%ld:%02ld:%02ld", hours, minutes, secs)
        }
        return String(format: "%ld:%02ld", minutes, secs)
    }

    /// Compact duration for plan descriptions: "45 sec", "5 min", "1:30".
    public static func shortDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds).rounded())
        if total < 60 { return "\(total) sec" }
        if total % 60 == 0 { return "\(total / 60) min" }
        return String(format: "%ld:%02ld", total / 60, total % 60)
    }

    /// Duration as spoken words: "1 minute 30 seconds".
    public static func spokenDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds).rounded())
        let minutes = total / 60
        let secs = total % 60
        var parts: [String] = []
        if minutes > 0 {
            parts.append("\(minutes) minute" + (minutes == 1 ? "" : "s"))
        }
        if secs > 0 || minutes == 0 {
            parts.append("\(secs) second" + (secs == 1 ? "" : "s"))
        }
        return parts.joined(separator: " ")
    }

    /// Distance number without a unit: "2.45".
    public static func distanceValue(_ meters: Double, unit: DistanceUnit, fractionDigits: Int = 2) -> String {
        let value = max(0, meters) / unit.metersPerUnit
        return String(format: "%.\(max(0, fractionDigits))f", value)
    }

    /// Distance with a unit: "2.45 km".
    public static func distance(_ meters: Double, unit: DistanceUnit, fractionDigits: Int = 2) -> String {
        distanceValue(meters, unit: unit, fractionDigits: fractionDigits) + " " + unit.abbreviation
    }

    /// Seconds per km or mile, or nil when there isn't enough data for a meaningful pace.
    public static func paceSeconds(duration: TimeInterval, meters: Double, unit: DistanceUnit) -> TimeInterval? {
        guard meters >= 20, duration > 0 else { return nil }
        let pace = duration / (meters / unit.metersPerUnit)
        guard pace.isFinite, pace < 60 * 60 else { return nil }
        return pace
    }

    /// Pace as "6:45 /km", or "--:--" when unknown.
    public static func pace(duration: TimeInterval, meters: Double, unit: DistanceUnit) -> String {
        guard let pace = paceSeconds(duration: duration, meters: meters, unit: unit) else {
            return "--:-- /" + unit.abbreviation
        }
        return clock(pace) + " /" + unit.abbreviation
    }

    /// Plan distances, which are always metric: "10 km", "7.5 km".
    public static func planDistance(_ meters: Double) -> String {
        if meters.truncatingRemainder(dividingBy: 1000) == 0 {
            return "\(Int(meters / 1000)) km"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    /// Plan distances as spoken words: "10 kilometers".
    public static func spokenPlanDistance(_ meters: Double) -> String {
        if meters.truncatingRemainder(dividingBy: 1000) == 0 {
            let km = Int(meters / 1000)
            return "\(km) " + DistanceUnit.kilometers.spokenName(count: km)
        }
        return String(format: "%.1f kilometers", meters / 1000)
    }
}
