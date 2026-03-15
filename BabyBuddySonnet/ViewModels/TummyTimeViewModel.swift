import Foundation

@Observable
@MainActor
final class TummyTimeViewModel {
    var todayTummyTimes: [TummyTime] = []
    var weekTummyTimes: [TummyTime] = []
    var customTummyTimes: [TummyTime] = []
    var isLoadingToday = false
    var isLoadingWeek = false
    var isLoadingCustom = false
    var error: String?

    var todayTotalMinutes: Int {
        todayTummyTimes.compactMap { tt -> Int? in
            guard let start = DateFormatting.parseISO(tt.start),
                  let end = DateFormatting.parseISO(tt.end)
            else { return nil }
            return Int(end.timeIntervalSince(start) / 60)
        }.reduce(0, +)
    }

    func loadToday(childID: Int) async {
        isLoadingToday = true
        error = nil
        defer { isLoadingToday = false }

        let yesterday = DateFormatting.formatDateOnly(DateFormatting.yesterday())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            let response: PaginatedResponse<TummyTime> = try await APIClient.shared.get(
                path: APIEndpoints.tummyTimes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: yesterday),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            todayTummyTimes = response.results
                .filter { DateFormatting.isToday($0.start) }
                .sorted { $0.end > $1.end }
        } catch {
            if (error as? URLError)?.code != .cancelled {
                self.error = error.localizedDescription
            }
        }
    }

    func loadWeek(childID: Int) async {
        isLoadingWeek = true
        defer { isLoadingWeek = false }

        let sevenDaysAgo = DateFormatting.formatDateOnly(DateFormatting.sevenDaysAgo())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            let response: PaginatedResponse<TummyTime> = try await APIClient.shared.get(
                path: APIEndpoints.tummyTimes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: sevenDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            weekTummyTimes = response.results.sorted { $0.end > $1.end }
        } catch {
            if (error as? URLError)?.code != .cancelled {
                self.error = error.localizedDescription
            }
        }
    }

    func loadCustomRange(childID: Int, start: Date, end: Date) async {
        isLoadingCustom = true
        error = nil
        defer { isLoadingCustom = false }

        let startStr = DateFormatting.formatDateOnly(start)
        let endStr = DateFormatting.formatDateOnly(Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end)

        do {
            let response: PaginatedResponse<TummyTime> = try await APIClient.shared.get(
                path: APIEndpoints.tummyTimes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: startStr),
                    URLQueryItem(name: "start_max", value: endStr),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            customTummyTimes = response.results.sorted { $0.end > $1.end }
        } catch {
            if (error as? URLError)?.code != .cancelled {
                self.error = error.localizedDescription
            }
        }
    }

    func deleteTummyTime(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.tummyTime(id))
    }
}
