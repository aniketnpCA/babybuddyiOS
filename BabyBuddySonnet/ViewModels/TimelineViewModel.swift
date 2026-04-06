import Foundation
import SwiftUI

@Observable
@MainActor
final class TimelineViewModel {
    var entries: [TimelineEntry] = []
    var isLoading = false
    var error: String?
    var selectedDate: Date = Date()

    func loadTimeline(childID: Int) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: dayStart)!
        let dayAfter = Calendar.current.date(byAdding: .day, value: 2, to: dayStart)!
        let minDate = DateFormatting.formatDateOnly(dayBefore)
        let maxDate = DateFormatting.formatDateOnly(dayAfter)

        do {
            async let feedingsResp: PaginatedResponse<Feeding> = APIClient.shared.get(
                path: APIEndpoints.feedings,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: minDate),
                    URLQueryItem(name: "start_max", value: maxDate),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            async let pumpingResp: PaginatedResponse<Pumping> = APIClient.shared.get(
                path: APIEndpoints.pumping,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: minDate),
                    URLQueryItem(name: "start_max", value: maxDate),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            async let sleepResp: PaginatedResponse<SleepRecord> = APIClient.shared.get(
                path: APIEndpoints.sleep,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: minDate),
                    URLQueryItem(name: "start_max", value: maxDate),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            async let diaperResp: PaginatedResponse<DiaperChange> = APIClient.shared.get(
                path: APIEndpoints.changes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: minDate),
                    URLQueryItem(name: "time_max", value: maxDate),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            async let tummyResp: PaginatedResponse<TummyTime> = APIClient.shared.get(
                path: APIEndpoints.tummyTimes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "start_min", value: minDate),
                    URLQueryItem(name: "start_max", value: maxDate),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            async let tempResp: PaginatedResponse<Temperature> = APIClient.shared.get(
                path: APIEndpoints.temperatures,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "time_min", value: minDate),
                    URLQueryItem(name: "time_max", value: maxDate),
                    URLQueryItem(name: "limit", value: "1000"),
                ]
            )
            async let noteResp: PaginatedResponse<Note> = APIClient.shared.get(
                path: APIEndpoints.notes,
                queryItems: [
                    URLQueryItem(name: "child", value: "\(childID)"),
                    URLQueryItem(name: "limit", value: "200"),
                ]
            )

            let feedings = try await feedingsResp.results
            let pumpings = try await pumpingResp.results
            let sleeps = try await sleepResp.results
            let diapers = try await diaperResp.results
            let tummyTimes = try await tummyResp.results
            let temperatures = try await tempResp.results
            let notes = try await noteResp.results

            let dateKey = DateFormatting.formatDateOnly(selectedDate)

            var all: [TimelineEntry] = []

            for f in feedings {
                guard let start = DateFormatting.parseISO(f.start),
                      DateFormatting.formatDateOnly(start) == dateKey
                else { continue }
                let end = DateFormatting.parseISO(f.end)
                let subtitle: String
                if let method = f.feedingMethod {
                    let amountStr = f.amount.map { String(format: "%.2f oz", $0) } ?? ""
                    subtitle = [method.displayName, amountStr].filter { !$0.isEmpty }.joined(separator: " \u{2022} ")
                } else {
                    subtitle = f.method
                }
                all.append(TimelineEntry(
                    id: "feeding-\(f.id)",
                    category: .feeding,
                    title: f.feedingType?.displayName ?? "Feeding",
                    subtitle: subtitle,
                    time: start,
                    endTime: end,
                    icon: f.feedingMethod?.sfSymbol ?? "drop.fill",
                    color: AppConstants.feedingMethodColors[f.feedingMethod ?? .bottle] ?? .blue
                ))
            }

            for p in pumpings {
                guard let start = DateFormatting.parseISO(p.start),
                      DateFormatting.formatDateOnly(start) == dateKey
                else { continue }
                let end = DateFormatting.parseISO(p.end)
                let amountStr = p.amount.map { String(format: "%.2f oz", $0) } ?? ""
                all.append(TimelineEntry(
                    id: "pumping-\(p.id)",
                    category: .pumping,
                    title: "Pumping",
                    subtitle: [amountStr, p.milkCategory.displayName].filter { !$0.isEmpty }.joined(separator: " \u{2022} "),
                    time: start,
                    endTime: end,
                    icon: "drop.triangle.fill",
                    color: AppConstants.milkCategoryColors[p.milkCategory] ?? .orange
                ))
            }

            for s in sleeps {
                guard let start = DateFormatting.parseISO(s.start),
                      DateFormatting.formatDateOnly(start) == dateKey
                else { continue }
                let end = DateFormatting.parseISO(s.end)
                all.append(TimelineEntry(
                    id: "sleep-\(s.id)",
                    category: .sleep,
                    title: s.nap ? "Nap" : "Night Sleep",
                    subtitle: DateFormatting.formatDuration(start: s.start, end: s.end),
                    time: start,
                    endTime: end,
                    icon: s.nap ? "sun.max.fill" : "moon.fill",
                    color: s.nap ? .orange : .purple
                ))
            }

            for d in diapers {
                guard let time = DateFormatting.parseISO(d.time),
                      DateFormatting.formatDateOnly(time) == dateKey
                else { continue }
                let desc = d.typeDescription
                var colorInfo = ""
                if d.solid, let sc = d.stoolColor { colorInfo = " \u{2022} \(sc.displayName)" }
                all.append(TimelineEntry(
                    id: "diaper-\(d.id)",
                    category: .diaper,
                    title: "Diaper Change",
                    subtitle: desc + colorInfo,
                    time: time,
                    endTime: nil,
                    icon: d.wet && d.solid ? "drop.circle.fill" : d.wet ? "drop.fill" : "circle.fill",
                    color: d.wet && d.solid ? .teal : d.wet ? .cyan : .brown
                ))
            }

            for tt in tummyTimes {
                guard let start = DateFormatting.parseISO(tt.start),
                      DateFormatting.formatDateOnly(start) == dateKey
                else { continue }
                let end = DateFormatting.parseISO(tt.end)
                let duration = DateFormatting.formatDuration(start: tt.start, end: tt.end)
                all.append(TimelineEntry(
                    id: "tummy-\(tt.id)",
                    category: .tummyTime,
                    title: "Tummy Time",
                    subtitle: tt.milestone ?? duration,
                    time: start,
                    endTime: end,
                    icon: "figure.play",
                    color: .green
                ))
            }

            for t in temperatures {
                guard let time = DateFormatting.parseISO(t.time),
                      DateFormatting.formatDateOnly(time) == dateKey
                else { continue }
                all.append(TimelineEntry(
                    id: "temp-\(t.id)",
                    category: .temperature,
                    title: "Temperature",
                    subtitle: String(format: "%.1f\u{00B0}F", t.temperature),
                    time: time,
                    endTime: nil,
                    icon: "thermometer.medium",
                    color: t.temperature >= 100.4 ? .red : t.temperature >= 99.5 ? .orange : .green
                ))
            }

            for n in notes {
                guard let time = DateFormatting.parseISO(n.time),
                      DateFormatting.formatDateOnly(time) == dateKey
                else { continue }
                all.append(TimelineEntry(
                    id: "note-\(n.id)",
                    category: .note,
                    title: "Note",
                    subtitle: n.note,
                    time: time,
                    endTime: nil,
                    icon: "note.text",
                    color: .yellow
                ))
            }

            entries = all.sorted { $0.time > $1.time }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }

    func goToToday() {
        selectedDate = Date()
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}

// MARK: - Timeline Entry Model

nonisolated enum TimelineCategory: String, Sendable {
    case feeding, pumping, sleep, diaper, tummyTime, temperature, note
}

struct TimelineEntry: Identifiable {
    let id: String
    let category: TimelineCategory
    let title: String
    let subtitle: String
    let time: Date
    let endTime: Date?
    let icon: String
    let color: Color

    var durationMinutes: Int? {
        guard let end = endTime else { return nil }
        let mins = Int(end.timeIntervalSince(time) / 60)
        return mins > 0 ? mins : nil
    }
}
