import Foundation

@Observable
@MainActor
final class PumpingViewModel {
    var todayPumping: [Pumping] = []
    var weekPumping: [Pumping] = []
    var isLoadingToday = false
    var isLoadingWeek = false
    var error: String?

    var todayTotalOz: Double {
        Calculations.calculateTotalPumped(todayPumping)
    }

    struct DailyPumpingData: Identifiable {
        let id: String
        let date: String
        let displayDate: String
        let toBeConsumedOz: Double
        let consumedOz: Double
        let frozenOz: Double
    }

    var weeklyChartData: [DailyPumpingData] {
        let calendar = Calendar.current
        var data: [DailyPumpingData] = []
        let today = DateFormatting.startOfToday()

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dateKey = DateFormatting.formatDateOnly(date)

            let dayPumping = weekPumping.filter { p in
                guard let d = DateFormatting.parseISO(p.start) else { return false }
                return DateFormatting.formatDateOnly(d) == dateKey
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"

            let tbc = dayPumping.filter { $0.milkCategory == .toBeConsumed }.reduce(0.0) { $0 + $1.amount }
            let consumed = dayPumping.filter { $0.milkCategory == .consumed }.reduce(0.0) { $0 + $1.amount }
            let frozen = dayPumping.filter { $0.milkCategory == .frozen }.reduce(0.0) { $0 + $1.amount }

            data.append(DailyPumpingData(
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

    func loadToday(childID: Int) async {
        isLoadingToday = true
        error = nil
        defer { isLoadingToday = false }

        let yesterday = DateFormatting.formatDateOnly(DateFormatting.yesterday())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            let response: PaginatedResponse<Pumping> = try await APIClient.shared.get(
                path: APIEndpoints.pumping,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: yesterday),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            todayPumping = response.results
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
            let response: PaginatedResponse<Pumping> = try await APIClient.shared.get(
                path: APIEndpoints.pumping,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: sevenDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            weekPumping = response.results.sorted { $0.end > $1.end }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createPumping(_ input: CreatePumpingInput) async throws {
        let _: Pumping = try await APIClient.shared.post(
            path: APIEndpoints.pumping,
            body: input
        )
    }

    func deletePumping(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.pumpingSession(id))
    }
}
