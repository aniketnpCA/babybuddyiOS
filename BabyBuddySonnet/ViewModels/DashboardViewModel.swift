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

    private let settings = SettingsService.shared

    func loadDashboard(childID: Int) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let yesterday = DateFormatting.formatDateOnly(DateFormatting.yesterday())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            // Fetch feedings, pumping, and sleep in parallel
            async let feedingsResponse: PaginatedResponse<Feeding> = APIClient.shared.get(
                path: APIEndpoints.feedings,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: yesterday),
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
            let pumpings = try await pumpingResponse.results.filter { DateFormatting.isToday($0.start) }
            let sleeps = try await sleepResponse.results.filter { DateFormatting.isToday($0.start) }

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
                .sorted { ($0.end) > ($1.end) }
                .first?.end

        } catch {
            self.error = error.localizedDescription
        }
    }
}
