import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    var feedingProgress: Calculations.FeedingProgress?
    var dailySurplus: Double = 0
    var todaySleepMinutes: Int = 0
    var lastFeedingTime: String?
    var lastPumpingTime: String?
    var lastDiaperTime: String?
    var todayPumpedOz: Double = 0
    var todayConsumedOz: Double = 0
    var isLoading = false
    var error: String?

    // Active timers
    var activeTimers: [BabyTimer] = []

    // Raw feeding arrays for cumulative chart
    var todayFeedings: [Feeding] = []
    var weekFeedings: [Feeding] = []

    // Growth data for profile card
    var latestWeight: WeightMeasurement?
    var latestHeight: HeightMeasurement?
    var latestHeadCircumference: HeadCircumferenceMeasurement?

    // Extra widget data (loaded on demand)
    var weightMeasurements: [WeightMeasurement] = []
    var heightMeasurements: [HeightMeasurement] = []
    var headCircumferenceMeasurements: [HeadCircumferenceMeasurement] = []
    var bmiMeasurements: [BMIMeasurement] = []
    var recentFeedings: [Feeding] = []
    var recentPumping: [Pumping] = []
    var recentSleep: [SleepRecord] = []
    var recentDiaperChanges: [DiaperChange] = []
    var weekPumping: [Pumping] = []
    var recentTummyTimes: [TummyTime] = []
    var recentTemperatures: [Temperature] = []

    // MARK: - Next Expected Times

    var nextFeedingTime: Date? {
        guard settings.isIntervalEnabled(for: .feeding),
              let lastEnd = lastFeedingTime,
              let date = DateFormatting.parseISO(lastEnd)
        else { return nil }
        return date.addingTimeInterval(settings.intervalHours(for: .feeding) * 3600)
    }

    var nextPumpingTime: Date? {
        guard settings.isIntervalEnabled(for: .pumping),
              let lastEnd = lastPumpingTime,
              let date = DateFormatting.parseISO(lastEnd)
        else { return nil }
        return date.addingTimeInterval(settings.intervalHours(for: .pumping) * 3600)
    }

    var nextDiaperTime: Date? {
        guard settings.isIntervalEnabled(for: .diaper),
              let lastTime = lastDiaperTime,
              let date = DateFormatting.parseISO(lastTime)
        else { return nil }
        return date.addingTimeInterval(settings.intervalHours(for: .diaper) * 3600)
    }

    private let settings = SettingsService.shared

    // MARK: - Timer Management

    func startTimer(childID: Int, name: String?) async {
        do {
            let input = CreateTimerInput(
                child: childID,
                name: name,
                start: DateFormatting.formatForAPI(Date())
            )
            let timer: BabyTimer = try await APIClient.shared.post(
                path: APIEndpoints.timers,
                body: input
            )
            activeTimers.append(timer)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stopTimer(_ timer: BabyTimer) async -> BabyTimer? {
        do {
            let input = StopTimerInput(
                end: DateFormatting.formatForAPI(Date()),
                active: false
            )
            let stopped: BabyTimer = try await APIClient.shared.patch(
                path: APIEndpoints.timer(timer.id),
                body: input
            )
            activeTimers.removeAll { $0.id == timer.id }
            return stopped
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func deleteTimer(_ timer: BabyTimer) async {
        do {
            try await APIClient.shared.delete(path: APIEndpoints.timer(timer.id))
            activeTimers.removeAll { $0.id == timer.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Cumulative Chart Data

    var cumulativeChartData: FeedingViewModel.CumulativeChartData {
        let nowMinutes = Calculations.minutesSinceMidnight(Date())

        let todaySeries = Calculations.buildCumulativeSteps(
            feedings: todayFeedings,
            upToMinutes: nowMinutes
        )

        let expectedSeries = Calculations.buildExpectedLine(
            wakeTime: settings.feedingWakeTime,
            targetTime: settings.feedingTargetTime,
            targetAmount: settings.feedingTargetAmount
        )

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let historicalFeedings = weekFeedings.filter { f in
            guard let endDate = DateFormatting.parseISO(f.end) else { return false }
            return endDate < todayStart
        }

        let averageSeries = Calculations.buildAverageLine(
            historicalFeedings: historicalFeedings,
            days: settings.feedingAverageDays
        )

        let currentOz = todaySeries.last?.y ?? 0
        let expectedNow = interpolate(series: expectedSeries, at: nowMinutes)
        let averageNow = interpolate(series: averageSeries, at: nowMinutes)

        let progress = Calculations.calculateFeedingProgress(
            feedings: todayFeedings,
            targetAmount: settings.feedingTargetAmount,
            targetTime: settings.feedingTargetTime
        )

        return FeedingViewModel.CumulativeChartData(
            todaySeries: todaySeries,
            expectedSeries: expectedSeries,
            averageSeries: averageSeries,
            targetAmount: settings.feedingTargetAmount,
            currentOz: currentOz,
            status: progress.status,
            expectedNow: expectedNow,
            averageNow: averageNow,
            averageDays: settings.feedingAverageDays
        )
    }

    private func interpolate(series: [(x: Double, y: Double)], at x: Double) -> Double {
        var result = 0.0
        for point in series {
            if point.x <= x { result = point.y }
            else { break }
        }
        return result
    }

    // MARK: - Widget Computed Properties

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

    var dailyFeedingOz: [(date: String, oz: Double)] {
        let grouped = Calculations.groupByDate(recentFeedings) { $0.start }
        return grouped.map { dateStr, feedings in
            (date: dateStr, oz: Calculations.calculateTotalConsumed(feedings))
        }.sorted { $0.date < $1.date }
    }

    var dailyPumpingOz: [(date: String, oz: Double)] {
        let grouped = Calculations.groupByDate(recentPumping) { $0.start }
        return grouped.map { dateStr, pumpings in
            (date: dateStr, oz: Calculations.calculateTotalPumped(pumpings))
        }.sorted { $0.date < $1.date }
    }

    var dailyDiaperCounts: [(date: String, wetOnly: Int, solidOnly: Int, both: Int)] {
        let grouped = Calculations.groupByDate(recentDiaperChanges) { $0.time }
        return grouped.map { dateStr, changes in
            var wetOnly = 0, solidOnly = 0, both = 0
            for change in changes {
                if change.wet && change.solid { both += 1 }
                else if change.wet { wetOnly += 1 }
                else if change.solid { solidOnly += 1 }
            }
            return (date: dateStr, wetOnly: wetOnly, solidOnly: solidOnly, both: both)
        }.sorted { $0.date < $1.date }
    }

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

    var weeklyFeedingChartData: [FeedingViewModel.DailyFeedingData] {
        let calendar = Calendar.current
        let today = DateFormatting.startOfToday()
        var data: [FeedingViewModel.DailyFeedingData] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dateKey = DateFormatting.formatDateOnly(date)
            let dayFeedings = weekFeedings.filter { f in
                guard let d = DateFormatting.parseISO(f.start) else { return false }
                return DateFormatting.formatDateOnly(d) == dateKey
            }
            let totalOz = Calculations.calculateTotalConsumed(dayFeedings)
            data.append(FeedingViewModel.DailyFeedingData(
                id: dateKey,
                date: dateKey,
                displayDate: formatter.string(from: date),
                totalOz: totalOz
            ))
        }
        return data
    }

    var weeklyPumpingChartData: [PumpingViewModel.DailyPumpingData] {
        let calendar = Calendar.current
        let today = DateFormatting.startOfToday()
        var data: [PumpingViewModel.DailyPumpingData] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dateKey = DateFormatting.formatDateOnly(date)
            let dayPumping = weekPumping.filter { p in
                guard let d = DateFormatting.parseISO(p.start) else { return false }
                return DateFormatting.formatDateOnly(d) == dateKey
            }
            let tbc = dayPumping.filter { $0.milkCategory == .toBeConsumed }.reduce(0.0) { $0 + ($1.amount ?? 0) }
            let consumed = dayPumping.filter { $0.milkCategory == .consumed }.reduce(0.0) { $0 + ($1.amount ?? 0) }
            let frozen = dayPumping.filter { $0.milkCategory == .frozen }.reduce(0.0) { $0 + ($1.amount ?? 0) }

            data.append(PumpingViewModel.DailyPumpingData(
                id: dateKey,
                date: dateKey,
                displayDate: formatter.string(from: date),
                toBeConsumedOz: tbc,
                consumedOz: consumed,
                frozenOz: frozen
            ))
        }
        return data
    }

    // MARK: - New Analytics Widget Computed Properties

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

    var feedingScatterPoints: [(date: Date, hourOfDay: Double, type: String)] {
        recentFeedings.compactMap { f in
            guard let date = DateFormatting.parseISO(f.start) else { return nil }
            let cal = Calendar.current
            let hour = Double(cal.component(.hour, from: date)) +
                       Double(cal.component(.minute, from: date)) / 60.0
            return (date: date, hourOfDay: hour, type: f.type)
        }
    }

    var dailySleepTotals: [(date: String, hours: Double)] {
        let grouped = Calculations.groupByDate(recentSleep) { $0.start }
        return grouped.map { dateStr, sleeps in
            let minutes = Calculations.calculateTotalSleepMinutes(sleeps)
            return (date: dateStr, hours: Double(minutes) / 60.0)
        }.sorted { $0.date < $1.date }
    }

    var diaperIntervals: [(date: Date, hours: Double)] {
        let sorted = recentDiaperChanges.compactMap { DateFormatting.parseISO($0.time) }.sorted()
        var results: [(date: Date, hours: Double)] = []
        for i in 1..<sorted.count {
            let hours = sorted[i].timeIntervalSince(sorted[i - 1]) / 3600
            results.append((date: sorted[i], hours: hours))
        }
        return results
    }

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

    var temperaturePoints: [(date: Date, value: Double)] {
        recentTemperatures.compactMap { temp in
            guard let date = DateFormatting.parseISO(temp.time) else { return nil }
            return (date: date, value: temp.temperature)
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Load

    func loadDashboard(childID: Int, childName: String? = nil, birthDate: String? = nil) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let yesterday = DateFormatting.formatDateOnly(DateFormatting.yesterday())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())
        let sevenDaysAgo = DateFormatting.formatDateOnly(DateFormatting.sevenDaysAgo())

        do {
            // Fetch today feedings, week feedings, pumping, and sleep in parallel
            async let feedingsResponse: PaginatedResponse<Feeding> = APIClient.shared.get(
                path: APIEndpoints.feedings,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: yesterday),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let weekFeedingsResponse: PaginatedResponse<Feeding> = APIClient.shared.get(
                path: APIEndpoints.feedings,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: sevenDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let pumpingResponse: PaginatedResponse<Pumping> = APIClient.shared.get(
                path: APIEndpoints.pumping,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: yesterday),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            async let sleepResponse: PaginatedResponse<SleepRecord> = APIClient.shared.get(
                path: APIEndpoints.sleep,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: yesterday),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )

            // Fetch latest diaper change for next-expected timer
            async let diaperResponse: PaginatedResponse<DiaperChange> = APIClient.shared.get(
                path: APIEndpoints.changes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "ordering", value: "-time"),
                    URLQueryItem(name: "limit", value: "1"),
                ]
            )

            // Fetch active timers
            async let timersResponse: PaginatedResponse<BabyTimer> = APIClient.shared.get(
                path: APIEndpoints.timers,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "active", value: "true"),
                    URLQueryItem(name: "limit", value: "10"),
                ]
            )

            // Always fetch latest growth measurements for profile card
            async let weightResponse: PaginatedResponse<WeightMeasurement> = APIClient.shared.get(
                path: APIEndpoints.weight,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "ordering", value: "-date"),
                    URLQueryItem(name: "limit", value: "1"),
                ]
            )

            async let heightResponse: PaginatedResponse<HeightMeasurement> = APIClient.shared.get(
                path: APIEndpoints.height,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "ordering", value: "-date"),
                    URLQueryItem(name: "limit", value: "1"),
                ]
            )

            async let headResponse: PaginatedResponse<HeadCircumferenceMeasurement> = APIClient.shared.get(
                path: APIEndpoints.headCircumference,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "ordering", value: "-date"),
                    URLQueryItem(name: "limit", value: "1"),
                ]
            )

            let feedings = try await feedingsResponse.results.filter { DateFormatting.isToday($0.start) }
            let allWeekFeedings = try await weekFeedingsResponse.results
            let pumpings = try await pumpingResponse.results.filter { DateFormatting.isToday($0.start) }
            let sleeps = try await sleepResponse.results.filter { DateFormatting.isToday($0.start) }
            let latestDiaper = try await diaperResponse.results.first
            activeTimers = try await timersResponse.results

            // Growth data for profile card
            latestWeight = try await weightResponse.results.first
            latestHeight = try await heightResponse.results.first
            latestHeadCircumference = try await headResponse.results.first

            todayFeedings = feedings.sorted { $0.end > $1.end }
            weekFeedings = allWeekFeedings.sorted { $0.end > $1.end }

            feedingProgress = Calculations.calculateFeedingProgress(
                feedings: feedings,
                targetAmount: settings.feedingTargetAmount,
                targetTime: settings.feedingTargetTime
            )

            todayPumpedOz = Calculations.calculateTotalPumped(pumpings)
            todayConsumedOz = Calculations.calculateTotalConsumed(feedings)
            dailySurplus = todayPumpedOz - todayConsumedOz
            todaySleepMinutes = Calculations.calculateTotalSleepMinutes(sleeps)

            // Find most recent times for each category
            lastFeedingTime = feedings
                .sorted { $0.end > $1.end }
                .first?.end

            lastPumpingTime = pumpings
                .sorted { $0.end > $1.end }
                .first?.end

            lastDiaperTime = latestDiaper?.time

            // Update Live Activity + Shared Data for Watch
            if let name = childName {
                LiveActivityService.shared.updateFromDashboard(
                    childName: name,
                    nextFeedingTime: nextFeedingTime,
                    nextPumpingTime: nextPumpingTime,
                    nextDiaperTime: nextDiaperTime,
                    dailyConsumedOz: todayConsumedOz,
                    dailyTargetOz: settings.feedingTargetAmount
                )

                SharedDataService.update(
                    childName: name,
                    nextFeedingTime: nextFeedingTime,
                    nextPumpingTime: nextPumpingTime,
                    nextDiaperTime: nextDiaperTime,
                    dailyConsumedOz: todayConsumedOz,
                    dailyTargetOz: settings.feedingTargetAmount
                )
            }

            // Load extra widget data if any widgets are enabled
            await loadWidgetData(childID: childID, birthDate: birthDate)

        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Widget Data Loading

    private func loadWidgetData(childID: Int, birthDate: String?) async {
        let enabledWidgets = settings.dashboardWidgets
        guard !enabledWidgets.isEmpty else { return }

        let thirtyDaysAgo = DateFormatting.formatDateOnly(
            Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        )
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())
        let sevenDaysAgo = DateFormatting.formatDateOnly(DateFormatting.sevenDaysAgo())

        let needsGrowth = enabledWidgets.contains(.growthChart) || enabledWidgets.contains(.bmiChart)
        let needs30DayFeedings = enabledWidgets.contains(.dailyTrendChart) || enabledWidgets.contains(.feedingHeatmapChart) || enabledWidgets.contains(.monthlyComparison) || enabledWidgets.contains(.feedingByTypeChart) || enabledWidgets.contains(.feedingPatternChart) || enabledWidgets.contains(.feedingDurationsChart) || enabledWidgets.contains(.feedingIntervalsChart)
        let needs30DayPumping = enabledWidgets.contains(.dailyTrendChart) || enabledWidgets.contains(.monthlyComparison) || enabledWidgets.contains(.pumpingAmountsChart)
        let needsSleep = enabledWidgets.contains(.sleepPatternChart) || enabledWidgets.contains(.monthlyComparison) || enabledWidgets.contains(.sleepTotalsChart)
        let needsDiapers = enabledWidgets.contains(.diaperFrequencyChart) || enabledWidgets.contains(.monthlyComparison) || enabledWidgets.contains(.diaperIntervalsChart) || enabledWidgets.contains(.diaperLifetimesChart)
        let needsWeekPumping = enabledWidgets.contains(.pumpingWeeklyChart)
        let needsTummyTime = enabledWidgets.contains(.tummyTimeChart)
        let needsTemperature = enabledWidgets.contains(.temperatureChart)

        do {
            if needsGrowth {
                async let wResp: PaginatedResponse<WeightMeasurement> = APIClient.shared.get(
                    path: APIEndpoints.weight,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "ordering", value: "date"),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                async let hResp: PaginatedResponse<HeightMeasurement> = APIClient.shared.get(
                    path: APIEndpoints.height,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "ordering", value: "date"),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                async let hcResp: PaginatedResponse<HeadCircumferenceMeasurement> = APIClient.shared.get(
                    path: APIEndpoints.headCircumference,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "ordering", value: "date"),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                weightMeasurements = try await wResp.results.sorted { $0.date < $1.date }
                heightMeasurements = try await hResp.results.sorted { $0.date < $1.date }
                headCircumferenceMeasurements = try await hcResp.results.sorted { $0.date < $1.date }
            }

            if needs30DayFeedings {
                let resp: PaginatedResponse<Feeding> = try await APIClient.shared.get(
                    path: APIEndpoints.feedings,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "start_min", value: thirtyDaysAgo),
                        URLQueryItem(name: "start_max", value: tomorrow),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                recentFeedings = resp.results.sorted { $0.start < $1.start }
            }

            if needs30DayPumping {
                let resp: PaginatedResponse<Pumping> = try await APIClient.shared.get(
                    path: APIEndpoints.pumping,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "start_min", value: thirtyDaysAgo),
                        URLQueryItem(name: "start_max", value: tomorrow),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                recentPumping = resp.results.sorted { $0.start < $1.start }
            }

            if needsSleep {
                let resp: PaginatedResponse<SleepRecord> = try await APIClient.shared.get(
                    path: APIEndpoints.sleep,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "start_min", value: thirtyDaysAgo),
                        URLQueryItem(name: "start_max", value: tomorrow),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                recentSleep = resp.results.sorted { $0.start < $1.start }
            }

            if needsDiapers {
                let resp: PaginatedResponse<DiaperChange> = try await APIClient.shared.get(
                    path: APIEndpoints.changes,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "time_min", value: thirtyDaysAgo),
                        URLQueryItem(name: "time_max", value: tomorrow),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                recentDiaperChanges = resp.results.sorted { $0.time < $1.time }
            }

            if needsWeekPumping {
                let resp: PaginatedResponse<Pumping> = try await APIClient.shared.get(
                    path: APIEndpoints.pumping,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "start_min", value: sevenDaysAgo),
                        URLQueryItem(name: "start_max", value: tomorrow),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                weekPumping = resp.results.sorted { $0.start < $1.start }
            }

            if needsGrowth, enabledWidgets.contains(.bmiChart) {
                let resp: PaginatedResponse<BMIMeasurement> = try await APIClient.shared.get(
                    path: APIEndpoints.bmi,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "ordering", value: "date"),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                bmiMeasurements = resp.results.sorted { $0.date < $1.date }
            }

            if needsTummyTime {
                let resp: PaginatedResponse<TummyTime> = try await APIClient.shared.get(
                    path: APIEndpoints.tummyTimes,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "start_min", value: thirtyDaysAgo),
                        URLQueryItem(name: "start_max", value: tomorrow),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                recentTummyTimes = resp.results
            }

            if needsTemperature {
                let resp: PaginatedResponse<Temperature> = try await APIClient.shared.get(
                    path: APIEndpoints.temperatures,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "time_min", value: thirtyDaysAgo),
                        URLQueryItem(name: "time_max", value: tomorrow),
                        URLQueryItem(name: "limit", value: "1000"),
                    ]
                )
                recentTemperatures = resp.results
            }
        } catch {
            // Widget data is supplementary; don't fail the whole dashboard
        }
    }
}
