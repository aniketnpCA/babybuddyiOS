import Foundation

@Observable
@MainActor
final class AnalyticsViewModel {
    // Growth data
    var weightMeasurements: [WeightMeasurement] = []
    var heightMeasurements: [HeightMeasurement] = []
    var headCircumferenceMeasurements: [HeadCircumferenceMeasurement] = []
    var bmiMeasurements: [BMIMeasurement] = []

    // Activity data (30 days for trends)
    var recentFeedings: [Feeding] = []
    var recentSleep: [SleepRecord] = []
    var recentDiaperChanges: [DiaperChange] = []
    var recentPumping: [Pumping] = []
    var recentTummyTimes: [TummyTime] = []
    var recentTemperatures: [Temperature] = []

    // State
    var isLoading = false
    var error: String?

    private let settings = SettingsService.shared

    // MARK: - Load All Data

    func loadAll(childID: Int, birthDate: String?) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let thirtyDaysAgo = DateFormatting.formatDateOnly(
            Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        )
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            // Fetch all data in parallel
            async let weightResponse: PaginatedResponse<WeightMeasurement> = APIClient.shared.get(
                path: APIEndpoints.weight,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "ordering", value: "date"),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let heightResponse: PaginatedResponse<HeightMeasurement> = APIClient.shared.get(
                path: APIEndpoints.height,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "ordering", value: "date"),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let headResponse: PaginatedResponse<HeadCircumferenceMeasurement> = APIClient.shared.get(
                path: APIEndpoints.headCircumference,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "ordering", value: "date"),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let feedingsResponse: PaginatedResponse<Feeding> = APIClient.shared.get(
                path: APIEndpoints.feedings,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: thirtyDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let sleepResponse: PaginatedResponse<SleepRecord> = APIClient.shared.get(
                path: APIEndpoints.sleep,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: thirtyDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let diaperResponse: PaginatedResponse<DiaperChange> = APIClient.shared.get(
                path: APIEndpoints.changes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: thirtyDaysAgo),
                    URLQueryItem(name: "time_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let pumpingResponse: PaginatedResponse<Pumping> = APIClient.shared.get(
                path: APIEndpoints.pumping,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: thirtyDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let bmiResponse: PaginatedResponse<BMIMeasurement> = APIClient.shared.get(
                path: APIEndpoints.bmi,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "ordering", value: "date"),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let tummyTimeResponse: PaginatedResponse<TummyTime> = APIClient.shared.get(
                path: APIEndpoints.tummyTimes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: thirtyDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let temperatureResponse: PaginatedResponse<Temperature> = APIClient.shared.get(
                path: APIEndpoints.temperatures,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: thirtyDaysAgo),
                    URLQueryItem(name: "time_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            weightMeasurements = try await weightResponse.results.sorted { $0.date < $1.date }
            heightMeasurements = try await heightResponse.results.sorted { $0.date < $1.date }
            headCircumferenceMeasurements = try await headResponse.results.sorted { $0.date < $1.date }
            recentFeedings = try await feedingsResponse.results.sorted { $0.start < $1.start }
            recentSleep = try await sleepResponse.results.sorted { $0.start < $1.start }
            recentDiaperChanges = try await diaperResponse.results.sorted { $0.time < $1.time }
            recentPumping = try await pumpingResponse.results.sorted { $0.start < $1.start }

            // These endpoints may not exist on older server versions
            do {
                bmiMeasurements = try await bmiResponse.results.sorted { $0.date < $1.date }
            } catch {
                bmiMeasurements = []
            }
            do {
                recentTummyTimes = try await tummyTimeResponse.results.sorted { $0.start < $1.start }
            } catch {
                recentTummyTimes = []
            }
            do {
                recentTemperatures = try await temperatureResponse.results.sorted { $0.time < $1.time }
            } catch {
                recentTemperatures = []
            }

        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Growth Measurement CRUD

    func createWeight(childID: Int, weightGrams: Double, date: Date, notes: String?) async throws {
        let input = CreateWeightInput(
            child: childID,
            weight: weightGrams,
            date: DateFormatting.formatDateOnly(date),
            notes: notes
        )
        let _: WeightMeasurement = try await APIClient.shared.post(
            path: APIEndpoints.weight, body: input
        )
    }

    func createHeight(childID: Int, heightCm: Double, date: Date, notes: String?) async throws {
        let input = CreateHeightInput(
            child: childID,
            height: heightCm,
            date: DateFormatting.formatDateOnly(date),
            notes: notes
        )
        let _: HeightMeasurement = try await APIClient.shared.post(
            path: APIEndpoints.height, body: input
        )
    }

    func createHeadCircumference(childID: Int, headCircumferenceCm: Double, date: Date, notes: String?) async throws {
        let input = CreateHeadCircumferenceInput(
            child: childID,
            headCircumference: headCircumferenceCm,
            date: DateFormatting.formatDateOnly(date),
            notes: notes
        )
        let _: HeadCircumferenceMeasurement = try await APIClient.shared.post(
            path: APIEndpoints.headCircumference, body: input
        )
    }

    // MARK: - Update Growth Measurements

    func updateWeight(id: Int, weightGrams: Double, date: Date, notes: String?) async throws {
        let input = UpdateWeightInput(
            weight: weightGrams,
            date: DateFormatting.formatDateOnly(date),
            notes: notes
        )
        let _: WeightMeasurement = try await APIClient.shared.patch(
            path: APIEndpoints.weight(id), body: input
        )
    }

    func updateHeight(id: Int, heightCm: Double, date: Date, notes: String?) async throws {
        let input = UpdateHeightInput(
            height: heightCm,
            date: DateFormatting.formatDateOnly(date),
            notes: notes
        )
        let _: HeightMeasurement = try await APIClient.shared.patch(
            path: APIEndpoints.height(id), body: input
        )
    }

    func updateHeadCircumference(id: Int, headCircumferenceCm: Double, date: Date, notes: String?) async throws {
        let input = UpdateHeadCircumferenceInput(
            headCircumference: headCircumferenceCm,
            date: DateFormatting.formatDateOnly(date),
            notes: notes
        )
        let _: HeadCircumferenceMeasurement = try await APIClient.shared.patch(
            path: APIEndpoints.headCircumference(id), body: input
        )
    }

    // MARK: - Delete Growth Measurements

    func deleteWeight(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.weight(id))
    }

    func deleteHeight(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.height(id))
    }

    func deleteHeadCircumference(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.headCircumference(id))
    }

    // MARK: - Computed Chart Data

    /// Feeding count by hour of day (0–23) for time-of-day heatmap
    var feedingByHour: [Int: Int] {
        var counts = [Int: Int]()
        for feeding in recentFeedings {
            if let date = DateFormatting.parseISO(feeding.start) {
                let hour = Calendar.current.component(.hour, from: date)
                counts[hour, default: 0] += 1
            }
        }
        return counts
    }

    /// Daily feeding totals (bottle oz) for the past 30 days
    var dailyFeedingOz: [(date: String, oz: Double)] {
        let grouped = Calculations.groupByDate(recentFeedings) { $0.start }
        return grouped.map { dateStr, feedings in
            let oz = Calculations.calculateTotalConsumed(feedings)
            return (date: dateStr, oz: oz)
        }.sorted { $0.date < $1.date }
    }

    /// Daily pumping totals for the past 30 days
    var dailyPumpingOz: [(date: String, oz: Double)] {
        let grouped = Calculations.groupByDate(recentPumping) { $0.start }
        return grouped.map { dateStr, pumpings in
            let oz = Calculations.calculateTotalPumped(pumpings)
            return (date: dateStr, oz: oz)
        }.sorted { $0.date < $1.date }
    }

    /// Daily diaper counts for frequency chart
    var dailyDiaperCounts: [(date: String, wetOnly: Int, solidOnly: Int, both: Int)] {
        let grouped = Calculations.groupByDate(recentDiaperChanges) { $0.time }
        return grouped.map { dateStr, changes in
            var wetOnly = 0, solidOnly = 0, both = 0
            for change in changes {
                if change.wet && change.solid {
                    both += 1
                } else if change.wet {
                    wetOnly += 1
                } else if change.solid {
                    solidOnly += 1
                }
            }
            return (date: dateStr, wetOnly: wetOnly, solidOnly: solidOnly, both: both)
        }.sorted { $0.date < $1.date }
    }

    /// Sleep blocks for pattern chart (last 7 days)
    var sleepBlocks: [(date: String, startHour: Double, endHour: Double, isNap: Bool)] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        var blocks: [(date: String, startHour: Double, endHour: Double, isNap: Bool)] = []

        for sleep in recentSleep {
            guard let startDate = DateFormatting.parseISO(sleep.start),
                  let endDate = DateFormatting.parseISO(sleep.end),
                  startDate >= sevenDaysAgo
            else { continue }

            let cal = Calendar.current
            let startHour = Double(cal.component(.hour, from: startDate)) +
                           Double(cal.component(.minute, from: startDate)) / 60.0
            let endHour = Double(cal.component(.hour, from: endDate)) +
                         Double(cal.component(.minute, from: endDate)) / 60.0
            let dateStr = DateFormatting.formatDateOnly(startDate)

            blocks.append((date: dateStr, startHour: startHour, endHour: endHour, isNap: sleep.nap))
        }

        return blocks
    }

    // MARK: - New Chart Data

    /// Time between consecutive diaper changes (hours)
    var diaperIntervals: [(date: Date, hours: Double)] {
        let sorted = recentDiaperChanges.sorted { $0.time < $1.time }
        var results: [(date: Date, hours: Double)] = []
        for i in 1..<sorted.count {
            guard let prev = DateFormatting.parseISO(sorted[i - 1].time),
                  let curr = DateFormatting.parseISO(sorted[i].time) else { continue }
            let hours = curr.timeIntervalSince(prev) / 3600
            if hours < 24 { results.append((date: curr, hours: hours)) }
        }
        return results
    }

    /// Daily feeding oz split by type (bottle-method only)
    var dailyFeedingByType: [(date: String, breastMilk: Double, formula: Double, fortified: Double)] {
        let grouped = Calculations.groupByDate(recentFeedings) { $0.start }
        return grouped.map { dateStr, feedings in
            let bottleFeedings = feedings.filter { $0.method == FeedingMethod.bottle.rawValue }
            let bm = bottleFeedings.filter { $0.type == FeedingType.breastMilk.rawValue }
                .reduce(0.0) { $0 + ($1.amount ?? 0) }
            let fm = bottleFeedings.filter { $0.type == FeedingType.formula.rawValue }
                .reduce(0.0) { $0 + ($1.amount ?? 0) }
            let ft = bottleFeedings.filter { $0.type == FeedingType.fortifiedBreastMilk.rawValue }
                .reduce(0.0) { $0 + ($1.amount ?? 0) }
            return (date: dateStr, breastMilk: bm, formula: fm, fortified: ft)
        }.sorted { $0.date < $1.date }
    }

    /// Average feeding duration (minutes) and count per day
    var dailyFeedingDurations: [(date: String, avgMinutes: Double, count: Int)] {
        let grouped = Calculations.groupByDate(recentFeedings) { $0.start }
        return grouped.compactMap { dateStr, feedings in
            let durations: [Double] = feedings.compactMap { f in
                guard let s = DateFormatting.parseISO(f.start),
                      let e = DateFormatting.parseISO(f.end) else { return nil }
                return e.timeIntervalSince(s) / 60
            }
            guard !durations.isEmpty else { return nil }
            let avg = durations.reduce(0, +) / Double(durations.count)
            return (date: dateStr, avgMinutes: avg, count: feedings.count)
        }.sorted { $0.date < $1.date }
    }

    /// Average hours between feedings per day
    var dailyFeedingIntervals: [(date: String, avgHours: Double)] {
        let grouped = Calculations.groupByDate(recentFeedings) { $0.start }
        return grouped.compactMap { dateStr, feedings in
            let times = feedings.compactMap { DateFormatting.parseISO($0.start) }.sorted()
            guard times.count > 1 else { return nil }
            var totalHours = 0.0
            for i in 1..<times.count {
                totalHours += times[i].timeIntervalSince(times[i - 1]) / 3600
            }
            return (date: dateStr, avgHours: totalHours / Double(times.count - 1))
        }.sorted { $0.date < $1.date }
    }

    /// Each feeding as a scatter point (date, time of day, type)
    var feedingScatterPoints: [(date: Date, hourOfDay: Double, type: String)] {
        recentFeedings.compactMap { f in
            guard let date = DateFormatting.parseISO(f.start) else { return nil }
            let cal = Calendar.current
            let hour = Double(cal.component(.hour, from: date)) +
                       Double(cal.component(.minute, from: date)) / 60.0
            return (date: date, hourOfDay: hour, type: f.type)
        }
    }

    /// Total sleep hours per day
    var dailySleepTotals: [(date: String, hours: Double)] {
        let grouped = Calculations.groupByDate(recentSleep) { $0.start }
        return grouped.map { dateStr, sleeps in
            let minutes = Calculations.calculateTotalSleepMinutes(sleeps)
            return (date: dateStr, hours: Double(minutes) / 60.0)
        }.sorted { $0.date < $1.date }
    }

    /// Monthly comparison data
    var monthlyComparison: MonthlyComparison? {
        let cal = Calendar.current
        let now = Date()
        guard let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)),
              let lastMonthStart = cal.date(byAdding: .month, value: -1, to: thisMonthStart)
        else { return nil }

        let thisMonthFeedings = recentFeedings.filter {
            guard let d = DateFormatting.parseISO($0.start) else { return false }
            return d >= thisMonthStart
        }
        let lastMonthFeedings = recentFeedings.filter {
            guard let d = DateFormatting.parseISO($0.start) else { return false }
            return d >= lastMonthStart && d < thisMonthStart
        }

        let thisMonthSleep = recentSleep.filter {
            guard let d = DateFormatting.parseISO($0.start) else { return false }
            return d >= thisMonthStart
        }
        let lastMonthSleep = recentSleep.filter {
            guard let d = DateFormatting.parseISO($0.start) else { return false }
            return d >= lastMonthStart && d < thisMonthStart
        }

        let thisMonthDiapers = recentDiaperChanges.filter {
            guard let d = DateFormatting.parseISO($0.time) else { return false }
            return d >= thisMonthStart
        }
        let lastMonthDiapers = recentDiaperChanges.filter {
            guard let d = DateFormatting.parseISO($0.time) else { return false }
            return d >= lastMonthStart && d < thisMonthStart
        }

        let thisMonthPumping = recentPumping.filter {
            guard let d = DateFormatting.parseISO($0.start) else { return false }
            return d >= thisMonthStart
        }
        let lastMonthPumping = recentPumping.filter {
            guard let d = DateFormatting.parseISO($0.start) else { return false }
            return d >= lastMonthStart && d < thisMonthStart
        }

        let daysThisMonth = max(1, cal.component(.day, from: now))
        let daysLastMonth = max(1, cal.range(of: .day, in: .month, for: lastMonthStart)?.count ?? 30)

        return MonthlyComparison(
            avgDailyFeedingOzThisMonth: Calculations.calculateTotalConsumed(thisMonthFeedings) / Double(daysThisMonth),
            avgDailyFeedingOzLastMonth: Calculations.calculateTotalConsumed(lastMonthFeedings) / Double(daysLastMonth),
            avgDailySleepHoursThisMonth: Double(Calculations.calculateTotalSleepMinutes(thisMonthSleep)) / 60.0 / Double(daysThisMonth),
            avgDailySleepHoursLastMonth: Double(Calculations.calculateTotalSleepMinutes(lastMonthSleep)) / 60.0 / Double(daysLastMonth),
            avgDailyDiapersThisMonth: Double(thisMonthDiapers.count) / Double(daysThisMonth),
            avgDailyDiapersLastMonth: Double(lastMonthDiapers.count) / Double(daysLastMonth),
            totalPumpedThisMonth: Calculations.calculateTotalPumped(thisMonthPumping),
            totalPumpedLastMonth: Calculations.calculateTotalPumped(lastMonthPumping)
        )
    }

    /// Daily tummy time minutes for chart
    var dailyTummyTimeMinutes: [(date: String, minutes: Double)] {
        let grouped = Calculations.groupByDate(recentTummyTimes) { $0.start }
        return grouped.map { dateStr, tummyTimes in
            let minutes = tummyTimes.compactMap { tt -> Double? in
                guard let start = DateFormatting.parseISO(tt.start),
                      let end = DateFormatting.parseISO(tt.end)
                else { return nil }
                return end.timeIntervalSince(start) / 60
            }.reduce(0, +)
            return (date: dateStr, minutes: minutes)
        }.sorted { $0.date < $1.date }
    }

    /// Temperature readings as chart-ready (date, value) tuples
    var temperaturePoints: [(date: Date, value: Double)] {
        recentTemperatures.compactMap { temp in
            guard let date = DateFormatting.parseISO(temp.time) else { return nil }
            return (date: date, value: temp.temperature)
        }.sorted { $0.date < $1.date }
    }

    /// Build data context string for AI queries
    func buildAIContext(childAge: String?) -> String {
        var parts: [String] = []

        if let age = childAge {
            parts.append("Baby's age: \(age)")
        }

        // Last 7 days of feeding data
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let weekFeedings = recentFeedings.filter {
            guard let d = DateFormatting.parseISO($0.start) else { return false }
            return d >= sevenDaysAgo
        }
        if !weekFeedings.isEmpty {
            let feedingLines = weekFeedings.prefix(50).map { f in
                let amount = f.amount.map { "\($0)oz" } ?? "n/a"
                return "  \(DateFormatting.formatTime(f.start)) - method:\(f.method), type:\(f.type), amount:\(amount)"
            }
            parts.append("Recent feedings (last 7 days):\n\(feedingLines.joined(separator: "\n"))")
        }

        // Last 7 days sleep
        let weekSleep = recentSleep.filter {
            guard let d = DateFormatting.parseISO($0.start) else { return false }
            return d >= sevenDaysAgo
        }
        if !weekSleep.isEmpty {
            let sleepLines = weekSleep.prefix(30).map { s in
                let duration = DateFormatting.formatDuration(start: s.start, end: s.end)
                return "  \(DateFormatting.formatTime(s.start))-\(DateFormatting.formatTime(s.end)) (\(duration), nap:\(s.nap))"
            }
            parts.append("Recent sleep (last 7 days):\n\(sleepLines.joined(separator: "\n"))")
        }

        // Last 7 days diapers
        let weekDiapers = recentDiaperChanges.filter {
            guard let d = DateFormatting.parseISO($0.time) else { return false }
            return d >= sevenDaysAgo
        }
        if !weekDiapers.isEmpty {
            parts.append("Diaper changes (last 7 days): \(weekDiapers.count) total, \(weekDiapers.filter { $0.wet }.count) wet, \(weekDiapers.filter { $0.solid }.count) solid")
        }

        // Growth summary
        if let latestWeight = weightMeasurements.last {
            parts.append("Latest weight: \(String(format: "%.1f", latestWeight.weightInLbs)) lbs (\(latestWeight.date))")
        }
        if let latestHeight = heightMeasurements.last {
            parts.append("Latest height: \(String(format: "%.1f", latestHeight.heightInInches)) inches (\(latestHeight.date))")
        }

        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Supporting Types

struct MonthlyComparison {
    let avgDailyFeedingOzThisMonth: Double
    let avgDailyFeedingOzLastMonth: Double
    let avgDailySleepHoursThisMonth: Double
    let avgDailySleepHoursLastMonth: Double
    let avgDailyDiapersThisMonth: Double
    let avgDailyDiapersLastMonth: Double
    let totalPumpedThisMonth: Double
    let totalPumpedLastMonth: Double
}
