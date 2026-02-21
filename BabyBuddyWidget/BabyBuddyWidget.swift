import WidgetKit
import SwiftUI

// MARK: - Entry

struct BabyBuddyEntry: TimelineEntry {
    let date: Date
    let childName: String
    let nextFeedingTime: Date?
    let nextPumpingTime: Date?
    let nextDiaperTime: Date?
    let dailyConsumedOz: Double
    let dailyTargetOz: Double

    static var placeholder: BabyBuddyEntry {
        BabyBuddyEntry(
            date: Date(),
            childName: "Baby",
            nextFeedingTime: Date().addingTimeInterval(2 * 3600),
            nextPumpingTime: Date().addingTimeInterval(3.5 * 3600),
            nextDiaperTime: Date().addingTimeInterval(1 * 3600),
            dailyConsumedOz: 12,
            dailyTargetOz: 24
        )
    }
}

// MARK: - Provider

struct BabyBuddyProvider: TimelineProvider {
    private static let suiteName = "group.com.BabyBuddySonnet.shared"

    func placeholder(in context: Context) -> BabyBuddyEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BabyBuddyEntry) -> Void) {
        completion(context.isPreview ? .placeholder : makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BabyBuddyEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh at the soonest upcoming expected time so the "overdue" state shows promptly.
        // Fall back to 15 minutes if no intervals are configured.
        let refreshDate = soonestTime(entry: entry) ?? Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func makeEntry() -> BabyBuddyEntry {
        let defaults = UserDefaults(suiteName: BabyBuddyProvider.suiteName)
        return BabyBuddyEntry(
            date: Date(),
            childName: defaults?.string(forKey: "childName") ?? "Baby",
            nextFeedingTime: defaults?.object(forKey: "nextFeedingTime") as? Date,
            nextPumpingTime: defaults?.object(forKey: "nextPumpingTime") as? Date,
            nextDiaperTime: defaults?.object(forKey: "nextDiaperTime") as? Date,
            dailyConsumedOz: defaults?.double(forKey: "dailyConsumedOz") ?? 0,
            dailyTargetOz: defaults?.double(forKey: "dailyTargetOz") ?? 24
        )
    }

    private func soonestTime(entry: BabyBuddyEntry) -> Date? {
        [entry.nextFeedingTime, entry.nextPumpingTime, entry.nextDiaperTime]
            .compactMap { $0 }
            .min()
    }
}

// MARK: - Entry View

struct BabyBuddyWidgetEntryView: View {
    let entry: BabyBuddyEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if widgetFamily == .systemSmall {
            smallView
        } else {
            mediumView
        }
    }

    // MARK: Small

    @ViewBuilder
    private var smallView: some View {
        if let item = allItems.first {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.childName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundStyle(item.color)

                Text(item.label)
                    .font(.caption.weight(.medium))

                Text(item.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        } else {
            noDataView
        }
    }

    // MARK: Medium

    @ViewBuilder
    private var mediumView: some View {
        let items = allItems
        if items.isEmpty {
            noDataView
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.childName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(items, id: \.label) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .font(.body)
                            .foregroundStyle(item.color)
                            .frame(width: 22)

                        Text(item.label)
                            .font(.subheadline)

                        Spacer()

                        Text(item.date, style: .relative)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    // MARK: No Data

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open app to\nset up intervals")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Helpers

    private struct WidgetItem {
        let label: String
        let icon: String
        let color: Color
        let date: Date
    }

    private var allItems: [WidgetItem] {
        var items: [WidgetItem] = []
        if let t = entry.nextFeedingTime {
            items.append(WidgetItem(label: "Feeding", icon: "drop.fill", color: .blue, date: t))
        }
        if let t = entry.nextPumpingTime {
            items.append(WidgetItem(label: "Pumping", icon: "drop.triangle.fill", color: .orange, date: t))
        }
        if let t = entry.nextDiaperTime {
            items.append(WidgetItem(label: "Diaper", icon: "circle.dotted", color: .green, date: t))
        }
        return items.sorted { $0.date < $1.date }
    }
}

// MARK: - Widget

struct BabyBuddyWidget: Widget {
    let kind: String = "BabyBuddyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BabyBuddyProvider()) { entry in
            BabyBuddyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Baby Buddy")
        .description("Next expected feeding, pumping, and diaper.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    BabyBuddyWidget()
} timeline: {
    BabyBuddyEntry.placeholder
}

#Preview(as: .systemMedium) {
    BabyBuddyWidget()
} timeline: {
    BabyBuddyEntry.placeholder
}
