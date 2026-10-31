import SwiftData
import SwiftUI
import TrainingKit

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutRecord.startDate, order: .reverse) private var records: [WorkoutRecord]
    @AppStorage(SettingsKey.distanceUnit) private var unit: DistanceUnit = .kilometers

    private var thisWeek: [WorkoutRecord] {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return records.filter { week.contains($0.startDate) && !$0.isManual }
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "figure.run",
                        description: Text("Walks, runs, and plan workouts you save will show up here.")
                    )
                } else {
                    List {
                        Section("This Week") {
                            HStack {
                                StatTile(title: "Workouts", value: "\(thisWeek.count)", systemImage: "number")
                                StatTile(
                                    title: "Distance",
                                    value: Format.distance(thisWeek.reduce(0) { $0 + $1.distanceMeters }, unit: unit, fractionDigits: 1),
                                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                                )
                                StatTile(
                                    title: "Time",
                                    value: Format.clock(thisWeek.reduce(0) { $0 + $1.activeDuration }),
                                    systemImage: "clock"
                                )
                            }
                            .padding(.vertical, 4)
                        }

                        Section("All Workouts") {
                            ForEach(records) { record in
                                HistoryRow(record: record, unit: unit)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(records[index])
        }
        try? context.save()
    }
}

private struct HistoryRow: View {
    let record: WorkoutRecord
    let unit: DistanceUnit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.kind.systemImage)
                .font(.title3)
                .foregroundStyle(record.kind.color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(record.title).font(.headline)
                    if record.completedPlan {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .accessibilityLabel("Counts toward plan")
                    }
                }
                Text(record.startDate, format: .dateTime.weekday().month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if record.isManual {
                    Text("Marked done")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(Format.clock(record.activeDuration))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                    if record.distanceMeters > 0 {
                        Text(Format.distance(record.distanceMeters, unit: unit))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
