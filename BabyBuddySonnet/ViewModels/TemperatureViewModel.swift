import Foundation

@Observable
@MainActor
final class TemperatureViewModel {
    var todayTemperatures: [Temperature] = []
    var weekTemperatures: [Temperature] = []
    var customTemperatures: [Temperature] = []
    var isLoadingToday = false
    var isLoadingWeek = false
    var isLoadingCustom = false
    var error: String?

    func loadToday(childID: Int) async {
        isLoadingToday = true
        error = nil
        defer { isLoadingToday = false }

        let yesterday = DateFormatting.formatDateOnly(DateFormatting.yesterday())
        let tomorrow = DateFormatting.formatDateOnly(DateFormatting.tomorrow())

        do {
            let response: PaginatedResponse<Temperature> = try await APIClient.shared.get(
                path: APIEndpoints.temperatures,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: yesterday),
                    URLQueryItem(name: "time_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            todayTemperatures = response.results
                .filter { DateFormatting.isToday($0.time) }
                .sorted { $0.time > $1.time }
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
            let response: PaginatedResponse<Temperature> = try await APIClient.shared.get(
                path: APIEndpoints.temperatures,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: sevenDaysAgo),
                    URLQueryItem(name: "time_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            weekTemperatures = response.results.sorted { $0.time > $1.time }
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
            let response: PaginatedResponse<Temperature> = try await APIClient.shared.get(
                path: APIEndpoints.temperatures,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: startStr),
                    URLQueryItem(name: "time_max", value: endStr),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            customTemperatures = response.results.sorted { $0.time > $1.time }
        } catch {
            if (error as? URLError)?.code != .cancelled {
                self.error = error.localizedDescription
            }
        }
    }

    func deleteTemperature(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.temperature(id))
    }
}
