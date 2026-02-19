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
