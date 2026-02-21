import Foundation
import UserNotifications

@Observable
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    var permissionStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let settings = SettingsService.shared

    private init() {}

    // MARK: - Permission

    func refreshPermissionStatus() async {
        let notifSettings = await center.notificationSettings()
        permissionStatus = notifSettings.authorizationStatus
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshPermissionStatus()
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Full Reschedule (fetches from API)

    func rescheduleAll(childID: Int) async {
        // Cancel all existing reminder notifications
        center.removePendingNotificationRequests(
            withIdentifiers: ReminderCategory.allCases.map { $0.notificationID }
        )

        guard permissionStatus == .authorized else { return }

        for category in ReminderCategory.allCases {
            guard settings.isReminderEnabled(for: category) else { continue }

            let threshold = settings.reminderThresholdHours(for: category)

            if let lastDate = await fetchMostRecentDate(for: category, childID: childID) {
                let deadline = lastDate.addingTimeInterval(threshold * 3600)
                let remaining = deadline.timeIntervalSinceNow

                if remaining > 0 {
                    scheduleNotification(for: category, timeInterval: remaining, thresholdHours: threshold)
                } else {
                    // Already overdue — fire immediately
                    scheduleNotification(for: category, timeInterval: 1, thresholdHours: threshold)
                }
            } else {
                // No entries found — fire immediately
                scheduleNotification(for: category, timeInterval: 1, thresholdHours: threshold)
            }
        }
    }

    // MARK: - Quick Reschedule (after logging, no API call)

    func rescheduleCategory(_ category: ReminderCategory, lastEntryDate: Date) {
        center.removePendingNotificationRequests(withIdentifiers: [category.notificationID])

        guard settings.isReminderEnabled(for: category),
              permissionStatus == .authorized
        else { return }

        let threshold = settings.reminderThresholdHours(for: category)
        let deadline = lastEntryDate.addingTimeInterval(threshold * 3600)
        let remaining = deadline.timeIntervalSinceNow

        if remaining > 0 {
            scheduleNotification(for: category, timeInterval: remaining, thresholdHours: threshold)
        }
        // If already overdue, don't spam — the full rescheduleAll on next foreground handles it
    }

    // MARK: - Cancel

    func cancelAll() {
        center.removePendingNotificationRequests(
            withIdentifiers: ReminderCategory.allCases.map { $0.notificationID }
        )
    }

    // MARK: - Private

    private func scheduleNotification(
        for category: ReminderCategory,
        timeInterval: TimeInterval,
        thresholdHours: Double
    ) {
        let content = UNMutableNotificationContent()
        content.title = category.notificationTitle
        content.body = category.notificationBody(thresholdHours: thresholdHours)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, timeInterval),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: category.notificationID,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("Failed to schedule \(category.rawValue) notification: \(error)")
            }
        }
    }

    private func fetchMostRecentDate(
        for category: ReminderCategory,
        childID: Int
    ) async -> Date? {
        do {
            switch category {
            case .feeding:
                let response: PaginatedResponse<Feeding> = try await APIClient.shared.get(
                    path: APIEndpoints.feedings,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "ordering", value: "-end"),
                        URLQueryItem(name: "limit", value: "1"),
                    ]
                )
                return response.results.first.flatMap { DateFormatting.parseISO($0.end) }

            case .diaper:
                let response: PaginatedResponse<DiaperChange> = try await APIClient.shared.get(
                    path: APIEndpoints.changes,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "ordering", value: "-time"),
                        URLQueryItem(name: "limit", value: "1"),
                    ]
                )
                return response.results.first.flatMap { DateFormatting.parseISO($0.time) }

            case .sleep:
                let response: PaginatedResponse<SleepRecord> = try await APIClient.shared.get(
                    path: APIEndpoints.sleep,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "ordering", value: "-end"),
                        URLQueryItem(name: "limit", value: "1"),
                    ]
                )
                return response.results.first.flatMap { DateFormatting.parseISO($0.end) }

            case .pumping:
                let response: PaginatedResponse<Pumping> = try await APIClient.shared.get(
                    path: APIEndpoints.pumping,
                    queryItems: [
                        URLQueryItem(name: "child", value: "\(childID)"),
                        URLQueryItem(name: "ordering", value: "-end"),
                        URLQueryItem(name: "limit", value: "1"),
                    ]
                )
                return response.results.first.flatMap { DateFormatting.parseISO($0.end) }
            }
        } catch {
            print("Failed to fetch latest \(category.rawValue): \(error)")
            return nil
        }
    }
}
