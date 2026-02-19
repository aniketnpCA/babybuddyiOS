import Foundation

nonisolated enum DateFormatting {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterNoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let apiDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Parsing

    static func parseISO(_ string: String) -> Date? {
        isoFormatter.date(from: string) ?? isoFormatterNoFractional.date(from: string)
    }

    static func parseDate(_ string: String) -> Date? {
        apiDateFormatter.date(from: string)
    }

    // MARK: - Formatting for API

    static func formatForAPI(_ date: Date) -> String {
        isoFormatterNoFractional.string(from: date)
    }

    static func formatDateOnly(_ date: Date) -> String {
        apiDateFormatter.string(from: date)
    }

    // MARK: - Display Formatting

    static func formatTime(_ isoString: String) -> String {
        guard let date = parseISO(isoString) else { return "" }
        return timeFormatter.string(from: date)
    }

    static func formatTimeFromDate(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func formatDate(_ isoString: String) -> String {
        guard let date = parseISO(isoString) else { return "" }
        return dateFormatter.string(from: date)
    }

    static func formatShortDate(_ isoString: String) -> String {
        guard let date = parseISO(isoString) else { return "" }
        return shortDateFormatter.string(from: date)
    }

    static func formatDuration(start: String, end: String) -> String {
        guard let startDate = parseISO(start),
              let endDate = parseISO(end)
        else { return "" }
        return formatDurationBetween(startDate, and: endDate)
    }

    static func formatDurationBetween(_ start: Date, and end: Date) -> String {
        let minutes = Int(end.timeIntervalSince(start) / 60)
        return formatMinutesToDuration(minutes)
    }

    static func formatMinutesToDuration(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - Date Range Helpers

    static func startOfToday() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    static func yesterday() -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: startOfToday())!
    }

    static func tomorrow() -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfToday())!
    }

    static func sevenDaysAgo() -> Date {
        Calendar.current.date(byAdding: .day, value: -7, to: startOfToday())!
    }

    static func isToday(_ isoString: String) -> Bool {
        guard let date = parseISO(isoString) else { return false }
        return Calendar.current.isDateInToday(date)
    }
}
