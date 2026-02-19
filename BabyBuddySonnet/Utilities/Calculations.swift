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

    // MARK: - Cumulative Chart

    /// Convert a Date to minutes since midnight (0–1440).
    static func minutesSinceMidnight(_ date: Date, calendar: Calendar = .current) -> Double {
        let comps = calendar.dateComponents([.hour, .minute, .second], from: date)
        return Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0)) + Double(comps.second ?? 0) / 60.0
    }

    /// Parse an "HH:MM" string into minutes since midnight.
    static func parseTimeToMinutes(_ timeString: String) -> Double {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return 0 }
        return Double(parts[0] * 60 + parts[1])
    }

    /// Build a cumulative step series for a single day's bottle feedings.
    /// - Parameters:
    ///   - feedings: All feedings for that day (will be filtered to bottle only).
    ///   - upToMinutes: If non-nil, clamp the last point to this X value (e.g., current time).
    ///   - referenceDate: The calendar day to compute minutes-since-midnight against.
    /// - Returns: Array of (x: minutes since midnight, y: cumulative oz).
    static func buildCumulativeSteps(
        feedings: [Feeding],
        upToMinutes: Double?,
        referenceDate: Date = Date()
    ) -> [(x: Double, y: Double)] {
        let calendar = Calendar.current

        let bottleFeedings = feedings
            .filter { $0.method == FeedingMethod.bottle.rawValue && ($0.amount ?? 0) > 0 }
            .compactMap { f -> (minutes: Double, amount: Double)? in
                guard let endDate = DateFormatting.parseISO(f.end) else { return nil }
                let mins = minutesSinceMidnight(endDate, calendar: calendar)
                return (mins, f.amount ?? 0)
            }
            .filter { upToMinutes == nil || $0.minutes <= upToMinutes! }
            .sorted { $0.minutes < $1.minutes }

        var points: [(x: Double, y: Double)] = [(x: 0, y: 0)]
        var cumulative = 0.0
        for (mins, amount) in bottleFeedings {
            points.append((x: mins, y: cumulative))   // step: hold previous value until feeding completes
            cumulative += amount
            points.append((x: mins, y: cumulative))   // step: jump up
        }

        // Extend the last point to current time (or upToMinutes) so the line doesn't stop early
        let endX = upToMinutes ?? minutesSinceMidnight(Date(), calendar: calendar)
        if let lastX = points.last?.x, lastX < endX {
            points.append((x: endX, y: cumulative))
        }

        return points
    }

    /// Build the expected straight-line series: flat at 0 before wake, linear rise to target, flat after.
    static func buildExpectedLine(
        wakeTime: String,
        targetTime: String,
        targetAmount: Double
    ) -> [(x: Double, y: Double)] {
        let wakeMinutes = parseTimeToMinutes(wakeTime)
        let targetMinutes = parseTimeToMinutes(targetTime)

        return [
            (x: 0,              y: 0),
            (x: wakeMinutes,    y: 0),
            (x: targetMinutes,  y: targetAmount),
            (x: 1440,           y: targetAmount),
        ]
    }

    /// Build an N-day average cumulative series from historical feedings.
    /// Samples at 15-minute intervals (97 points: 0, 15, 30, ..., 1440).
    /// - Parameters:
    ///   - historicalFeedings: Feedings from prior days (excludes today).
    ///   - days: Number of prior days to average.
    ///   - referenceDate: "Today" — days are prior to this date.
    static func buildAverageLine(
        historicalFeedings: [Feeding],
        days: Int,
        referenceDate: Date = Date()
    ) -> [(x: Double, y: Double)] {
        guard days > 0 else { return [] }
        let calendar = Calendar.current

        // Build per-day cumulative series for the N prior days
        var daySeries: [[(x: Double, y: Double)]] = []
        for dayOffset in 1...days {
            guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: referenceDate) else { continue }
            let dayStart = calendar.startOfDay(for: dayDate)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            let dayFeedings = historicalFeedings.filter { f in
                guard let endDate = DateFormatting.parseISO(f.end) else { return false }
                return endDate >= dayStart && endDate < dayEnd
            }

            let series = buildCumulativeSteps(feedings: dayFeedings, upToMinutes: nil, referenceDate: dayDate)
            daySeries.append(series)
        }

        guard !daySeries.isEmpty else { return [] }

        // For each series, build a helper to get cumulative oz at any given minute
        func ozAt(minutes: Double, in series: [(x: Double, y: Double)]) -> Double {
            var result = 0.0
            for point in series {
                if point.x <= minutes { result = point.y }
                else { break }
            }
            return result
        }

        // Sample at 15-minute intervals
        let samplePoints = stride(from: 0.0, through: 1440.0, by: 15.0)
        return samplePoints.map { minute in
            let avg = daySeries.map { ozAt(minutes: minute, in: $0) }.reduce(0, +) / Double(daySeries.count)
            return (x: minute, y: avg)
        }
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
