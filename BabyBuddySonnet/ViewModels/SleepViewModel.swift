import Foundation

@Observable
@MainActor
final class SleepViewModel {
    var todaySleep: [SleepRecord] = []
    var weekSleep: [SleepRecord] = []
    var isLoadingToday = false
    var isLoadingWeek = false
    var error: String?

    var todayTotalMinutes: Int {
        Calculations.calculateTotalSleepMinutes(todaySleep)
    }

    var todayNaps: [SleepRecord] {
        todaySleep.filter { $0.nap }
    }

    var todayNightSleep: [SleepRecord] {
        todaySleep.filter { !$0.nap }
    }

    struct SleepPeriod: Identifiable {
        let id: Int
        let startHour: Double
        let endHour: Double
        let isNap: Bool
    }

    var timelinePeriods: [SleepPeriod] {
        todaySleep.compactMap { sleep in
            guard let start = DateFormatting.parseISO(sleep.start),
                  let end = DateFormatting.parseISO(sleep.end)
            else { return nil }

            let calendar = Calendar.current
            let startHour = Double(calendar.component(.hour, from: start))
                + Double(calendar.component(.minute, from: start)) / 60.0
            let endHour = Double(calendar.component(.hour, from: end))
                + Double(calendar.component(.minute, from: end)) / 60.0

            return SleepPeriod(
                id: sleep.id,
                startHour: startHour,
                endHour: endHour > startHour ? endHour : 24.0,
                isNap: sleep.nap
            )
        }
    }

    struct DailySleepData: Identifiable {
        let id: String
        let date: String
        let displayDate: String
        let napMinutes: Int
        let nightMinutes: Int
    }

    var weeklyChartData: [DailySleepData] {
        let calendar = Calendar.current
        var data: [DailySleepData] = []
        let today = DateFormatting.startOfToday()

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dateKey = DateFormatting.formatDateOnly(date)

            let daySleeps = weekSleep.filter { s in
                guard let d = DateFormatting.parseISO(s.start) else { return false }
                return DateFormatting.formatDateOnly(d) == dateKey
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"

            data.append(DailySleepData(
                id: dateKey,
                date: dateKey,
                displayDate: formatter.string(from: date),
                napMinutes: Calculations.calculateTotalSleepMinutes(daySleeps.filter { $0.nap }),
                nightMinutes: Calculations.calculateTotalSleepMinutes(daySleeps.filter { !$0.nap })
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
            let response: PaginatedResponse<SleepRecord> = try await APIClient.shared.get(
                path: APIEndpoints.sleep,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: yesterday),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            todaySleep = response.results
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
            let response: PaginatedResponse<SleepRecord> = try await APIClient.shared.get(
                path: APIEndpoints.sleep,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: sevenDaysAgo),
                    URLQueryItem(name: "start_max", value: tomorrow),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            weekSleep = response.results.sorted { $0.end > $1.end }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createSleep(_ input: CreateSleepInput) async throws {
        let _: SleepRecord = try await APIClient.shared.post(
            path: APIEndpoints.sleep,
            body: input
        )
    }

    func deleteSleep(id: Int) async throws {
        try await APIClient.shared.delete(path: APIEndpoints.sleepSession(id))
    }
}
