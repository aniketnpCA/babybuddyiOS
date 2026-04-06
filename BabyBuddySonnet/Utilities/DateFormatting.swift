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

    // Fallback for microsecond precision (6 decimal places) that ISO8601DateFormatter can't handle
    private static let microsecondsFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let apiDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Display Timezone

    /// Returns the timezone to use for display formatting.
    /// When "Use Local Timezone" is enabled, returns the device's current timezone.
    /// Otherwise, returns the configured home (server) timezone.
    @MainActor
    static var displayTimeZone: TimeZone {
        let settings = SettingsService.shared
        if settings.useLocalTimezone {
            return TimeZone.current
        }
        return TimeZone(identifier: settings.timezone) ?? TimeZone.current
    }

    /// Returns the configured home (server) timezone, for reference display.
    @MainActor
    static var homeTimeZone: TimeZone {
        let settings = SettingsService.shared
        return TimeZone(identifier: settings.timezone) ?? TimeZone.current
    }

    // MARK: - Display Formatters (timezone-aware, created on-demand)

    @MainActor
    private static func makeTimeFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = displayTimeZone
        return f
    }

    @MainActor
    private static func makeDateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        f.timeZone = displayTimeZone
        return f
    }

    @MainActor
    private static func makeShortDateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.timeZone = displayTimeZone
        return f
    }

    // MARK: - Parsing

    static func parseISO(_ string: String) -> Date? {
        isoFormatter.date(from: string)
            ?? isoFormatterNoFractional.date(from: string)
            ?? microsecondsFormatter.date(from: string)
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

    @MainActor
    static func formatTime(_ isoString: String) -> String {
        guard let date = parseISO(isoString) else { return "" }
        return makeTimeFormatter().string(from: date)
    }

    @MainActor
    static func formatTimeFromDate(_ date: Date) -> String {
        makeTimeFormatter().string(from: date)
    }

    @MainActor
    static func formatDate(_ isoString: String) -> String {
        guard let date = parseISO(isoString) else { return "" }
        return makeDateFormatter().string(from: date)
    }

    @MainActor
    static func formatShortDate(_ isoString: String) -> String {
        guard let date = parseISO(isoString) else { return "" }
        return makeShortDateFormatter().string(from: date)
    }

    /// Format time in the home timezone for reference (e.g. "3:00 PM PT")
    @MainActor
    static func formatTimeInHomeTimezone(_ isoString: String) -> String {
        guard let date = parseISO(isoString) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a zzz"
        f.timeZone = homeTimeZone
        return f.string(from: date)
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
    // These use device-local calendar for day grouping (per user request)

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
