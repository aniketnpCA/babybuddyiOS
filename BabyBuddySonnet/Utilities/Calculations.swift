import Foundation

nonisolated enum Calculations {

    // MARK: - Feeding

    static func calculateTotalConsumed(_ feedings: [Feeding]) -> Double {
        feedings
            .filter { $0.method == FeedingMethod.bottle.rawValue && $0.amount != nil }
            .reduce(0) { $0 + ($1.amount ?? 0) }
    }

    static func calculateTotalPumped(_ pumpings: [Pumping]) -> Double {
        pumpings.reduce(0) { $0 + $1.amount }
    }

    static func calculateDailySurplus(pumpings: [Pumping], feedings: [Feeding]) -> Double {
        calculateTotalPumped(pumpings) - calculateTotalConsumed(feedings)
    }

    // MARK: - Sleep

    static func calculateTotalSleepMinutes(_ sleeps: [SleepRecord]) -> Int {
        sleeps.reduce(0) { total, s in
            guard let start = DateFormatting.parseISO(s.start),
                  let end = DateFormatting.parseISO(s.end)
            else { return total }
            return total + Int(end.timeIntervalSince(start) / 60)
        }
    }

    // MARK: - Feeding Progress

    struct FeedingProgress {
        let consumed: Double
        let target: Double
        let percentage: Int
        let expectedByNow: Double
        let status: FeedingStatus
    }

    enum FeedingStatus: String {
        case onTrack = "On Track"
        case behind = "Behind"
        case critical = "Critical"
        case complete = "Complete"
    }

    static func calculateFeedingProgress(
        feedings: [Feeding],
        targetAmount: Double,
        targetTime: String
    ) -> FeedingProgress {
        let consumed = calculateTotalConsumed(feedings)
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)

        let parts = targetTime.split(separator: ":").compactMap { Int($0) }
        let targetHours = parts.count > 0 ? parts[0] : 22
        let targetMinutes = parts.count > 1 ? parts[1] : 0

        var targetDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: today)
        targetDateComponents.hour = targetHours
        targetDateComponents.minute = targetMinutes
        let targetDate = Calendar.current.date(from: targetDateComponents) ?? today

        let totalMinutesToTarget = targetDate.timeIntervalSince(today) / 60
        let minutesSinceStart = now.timeIntervalSince(today) / 60

        var expectedByNow: Double = 0
        if now >= targetDate {
            expectedByNow = targetAmount
        } else if minutesSinceStart > 0 && totalMinutesToTarget > 0 {
            let progressRatio = minutesSinceStart / totalMinutesToTarget
            expectedByNow = targetAmount * progressRatio
        }

        let percentage = min(100, Int((consumed / targetAmount) * 100))

        let status: FeedingStatus
        if consumed >= targetAmount {
            status = .complete
        } else if consumed >= expectedByNow * 0.9 {
            status = .onTrack
        } else if consumed >= expectedByNow * 0.7 {
            status = .behind
        } else {
            status = .critical
        }

        return FeedingProgress(
            consumed: consumed,
            target: targetAmount,
            percentage: percentage,
            expectedByNow: (expectedByNow * 10).rounded() / 10,
            status: status
        )
    }

    // MARK: - Grouping

    static func groupByDate<T>(_ items: [T], dateExtractor: (T) -> String?) -> [(key: String, items: [T])] {
        var grouped: [String: [T]] = [:]
        for item in items {
            guard let dateString = dateExtractor(item),
                  let date = DateFormatting.parseISO(dateString)
            else { continue }
            let key = DateFormatting.formatDateOnly(date)
            grouped[key, default: []].append(item)
        }
        return grouped.sorted { $0.key > $1.key }.map { (key: $0.key, items: $0.value) }
    }
}
