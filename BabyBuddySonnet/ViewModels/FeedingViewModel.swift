import Foundation

@Observable
@MainActor
final class FeedingViewModel {
    var todayFeedings: [Feeding] = []
    var weekFeedings: [Feeding] = []
    var isLoadingToday = false
    var isLoadingWeek = false
    var error: String?

    var todayTotalOz: Double {
        Calculations.calculateTotalConsumed(todayFeedings)
    }

    var todayBottleCount: Int {
        todayFeedings.filter { $0.method == FeedingMethod.bottle.rawValue }.count
    }

    var todayBreastCount: Int {
        todayFeedings.filter {
            $0.method == FeedingMethod.leftBreast.rawValue
                || $0.method == FeedingMethod.rightBreast.rawValue
                || $0.method == FeedingMethod.bothBreasts.rawValue
        }.count
    }

    struct DailyFeedingData: Identifiable {
        let id: String
        let date: String
        let displayDate: String
        let totalOz: Double
    }

    // MARK: - Cumulative Chart Data

    struct CumulativeChartData {
        let todaySeries: [(x: Double, y: Double)]
        let expectedSeries: [(x: Double, y: Double)]
        let averageSeries: [(x: Double, y: Double)]
        let targetAmount: Double
        let currentOz: Double
        let status: Calculations.FeedingStatus
        let expectedNow: Double
        let averageNow: Double
        let averageDays: Int
    }

    var cumulativeChartData: CumulativeChartData {
        let settings = SettingsService.shared
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

        // Historical feedings = weekFeedings excluding today
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

        // Expected oz at current time (interpolate expected line)
        let expectedNow = interpolate(series: expectedSeries, at: nowMinutes)
        let averageNow = interpolate(series: averageSeries, at: nowMinutes)

        let progress = Calculations.calculateFeedingProgress(
            feedings: todayFeedings,
            targetAmount: settings.feedingTargetAmount,
            targetTime: settings.feedingTargetTime
        )

        return CumulativeChartData(
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

    // MARK: - Weekly Bar Chart Data

    var weeklyChartData: [DailyFeedingData] {
        let calendar = Calendar.current
        var data: [DailyFeedingData] = []
        let today = DateFormatting.startOfToday()

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dateKey = DateFormatting.formatDateOnly(date)

            let dayFeedings = weekFeedings.filter { feeding in
                guard let feedDate = DateFormatting.parseISO(feeding.start) else { return false }
                return DateFormatting.formatDateOnly(feedDate) == dateKey
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"

            data.append(DailyFeedingData(
                id: dateKey,
                date: dateKey,
                displayDate: formatter.string(from: date),
                totalOz: Calculations.calculateTotalConsumed(dayFeedings)
            ))
        }
        return data
    }

    func loadToday(childID: Int) async {
        isLoadingToday = true
        error = nil
        defer { isLoadingToday = false }

        let yesterday = DateFormatting.formatDateOnly(DateFormatting.yesterday())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            let response: PaginatedResponse<Feeding> = try await APIClient.shared.get(
                path: APIEndpoints.feedings,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: yesterday),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            todayFeedings = response.results
                .filter { DateFormatting.isToday($0.start) }
                .sorted { $0.end > $1.end }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadWeek(childID: Int) async {
        isLoadingWeek = true
        defer { isLoadingWeek = false }

        let sevenDaysAgo = DateFormatting.formatDateOnly(DateFormatting.sevenDaysAgo())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            let response: PaginatedResponse<Feeding> = try await APIClient.shared.get(
                path: APIEndpoints.feedings,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: sevenDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            weekFeedings = response.results.sorted { $0.end > $1.end }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createFeeding(_ input: CreateFeedingInput) async throws {
        let _: Feeding = try await APIClient.shared.post(
            path: APIEndpoints.feedings,
            body: input
        )
    }

    func deleteFeeding(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.feeding(id))
    }
}
