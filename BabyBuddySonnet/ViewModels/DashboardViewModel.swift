import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    var feedingProgress: Calculations.FeedingProgress?
    var dailySurplus: Double = 0
    var todaySleepMinutes: Int = 0
    var lastFeedingTime: String?
    var todayPumpedOz: Double = 0
    var todayConsumedOz: Double = 0
    var isLoading = false
    var error: String?

    // Raw feeding arrays for cumulative chart
    var todayFeedings: [Feeding] = []
    var weekFeedings: [Feeding] = []

    private let settings = SettingsService.shared

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

    // MARK: - Load

    func loadDashboard(childID: Int) async {
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

            let feedings = try await feedingsResponse.results.filter { DateFormatting.isToday($0.start) }
            let allWeekFeedings = try await weekFeedingsResponse.results
            let pumpings = try await pumpingResponse.results.filter { DateFormatting.isToday($0.start) }
            let sleeps = try await sleepResponse.results.filter { DateFormatting.isToday($0.start) }

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

            // Find most recent feeding
            lastFeedingTime = feedings
                .sorted { $0.end > $1.end }
                .first?.end

        } catch {
            self.error = error.localizedDescription
        }
    }
}
