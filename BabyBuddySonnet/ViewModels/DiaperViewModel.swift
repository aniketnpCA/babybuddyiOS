import Foundation

@Observable
@MainActor
final class DiaperViewModel {
    var todayChanges: [DiaperChange] = []
    var weekChanges: [DiaperChange] = []
    var customChanges: [DiaperChange] = []
    var isLoadingToday = false
    var isLoadingWeek = false
    var isLoadingCustom = false
    var error: String?

    var todayWetCount: Int {
        todayChanges.filter { $0.wet && !$0.solid }.count
    }

    var todaySolidCount: Int {
        todayChanges.filter { $0.solid && !$0.wet }.count
    }

    var todayBothCount: Int {
        todayChanges.filter { $0.wet && $0.solid }.count
    }

    var todayTotalCount: Int {
        todayChanges.count
    }

    func loadToday(childID: Int) async {
        isLoadingToday = true
        error = nil
        defer { isLoadingToday = false }

        let yesterday = DateFormatting.formatDateOnly(DateFormatting.yesterday())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            let response: PaginatedResponse<DiaperChange> = try await APIClient.shared.get(
                path: APIEndpoints.changes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: yesterday),
                    URLQueryItem(name: "time_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            todayChanges = response.results
                .filter { DateFormatting.isToday($0.time) }
                .sorted { $0.time > $1.time }
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
            let response: PaginatedResponse<DiaperChange> = try await APIClient.shared.get(
                path: APIEndpoints.changes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: sevenDaysAgo),
                    URLQueryItem(name: "time_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            weekChanges = response.results.sorted { $0.time > $1.time }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createChange(_ input: CreateDiaperChangeInput) async throws {
        let _: DiaperChange = try await APIClient.shared.post(
            path: APIEndpoints.changes,
            body: input
        )
    }

    func deleteChange(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.change(id))
    }

    func updateChange(id: Int, _ input: UpdateDiaperChangeInput) async throws {
        let _: DiaperChange = try await APIClient.shared.patch(
            path: APIEndpoints.change(id),
            body: input
        )
    }

    func loadCustomRange(childID: Int, start: Date, end: Date) async {
        isLoadingCustom = true
        error = nil
        defer { isLoadingCustom = false }

        let startStr = DateFormatting.formatDateOnly(start)
        let endStr = DateFormatting.formatDateOnly(Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end)

        do {
            let response: PaginatedResponse<DiaperChange> = try await APIClient.shared.get(
                path: APIEndpoints.changes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: startStr),
                    URLQueryItem(name: "time_max", value: endStr),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            customChanges = response.results.sorted { $0.time > $1.time }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
