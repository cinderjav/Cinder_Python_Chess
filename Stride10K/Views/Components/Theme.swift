import SwiftUI
import TrainingKit
import UIKit

extension SegmentKind {
    var color: Color {
        switch self {
        case .warmup: return .orange
        case .run: return Color(red: 0.98, green: 0.27, blue: 0.36)
        case .walk: return .teal
        case .cooldown: return .indigo
        }
    }

    var systemImage: String {
        switch self {
        case .warmup: return "flame.fill"
        case .run: return "figure.run"
        case .walk: return "figure.walk"
        case .cooldown: return "figure.cooldown"
        }
    }
}

extension WorkoutKind {
    var color: Color {
        switch self {
        case .plan: return .accentColor
        case .run: return SegmentKind.run.color
        case .walk: return SegmentKind.walk.color
        }
    }
}

extension Segment {
    /// "1:30" for timed segments, "10 km" for distance segments.
    var goalText: String {
        switch goal {
        case .duration(let seconds): return Format.shortDuration(seconds)
        case .distance(let meters): return Format.planDistance(meters)
        }
    }
}

/// A rounded card background used throughout the app.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// A small labeled metric, e.g. "Distance 3.2 km".
struct StatTile: View {
    let title: String
    let value: String
    var systemImage: String?
    var tint: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                }
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// A proportional, color-coded bar showing a workout's segments.
struct SegmentTimelineView: View {
    let segments: [Segment]

    var body: some View {
        GeometryReader { geometry in
            let total = segments.reduce(0) { $0 + $1.estimatedDuration() }
            let spacing: CGFloat = 2
            let available = max(0, geometry.size.width - spacing * CGFloat(max(0, segments.count - 1)))
            HStack(spacing: spacing) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(segment.kind.color)
                        .frame(width: total > 0 ? available * CGFloat(segment.estimatedDuration() / total) : 0)
                }
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}

/// Summary card for the next plan workout, with a start button.
struct NextWorkoutCard: View {
    let workout: PlanWorkout
    let onStart: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Up next", systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("~\(Format.shortDuration(workout.estimatedDuration()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(workout.title)
                    .font(.headline)
                Text(workout.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                SegmentTimelineView(segments: workout.segments)
                Button(action: onStart) {
                    Label("Start Workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}
