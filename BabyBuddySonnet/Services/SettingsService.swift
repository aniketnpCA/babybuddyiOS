import Foundation

@Observable
final class SettingsService {
    static let shared = SettingsService()

    private let store = NSUbiquitousKeyValueStore.default

    // MARK: - Settings Properties

    var feedingTargetAmount: Double {
        get {
            let val = store.double(forKey: Keys.feedingTargetAmount)
            return val > 0 ? val : AppConstants.defaultFeedingTarget
        }
        set { store.set(newValue, forKey: Keys.feedingTargetAmount); store.synchronize() }
    }

    var feedingTargetTime: String {
        get { store.string(forKey: Keys.feedingTargetTime) ?? AppConstants.defaultFeedingTargetTime }
        set { store.set(newValue, forKey: Keys.feedingTargetTime); store.synchronize() }
    }

    var sleepTargetHours: Double {
        get {
            let val = store.double(forKey: Keys.sleepTargetHours)
            return val > 0 ? val : AppConstants.defaultSleepTargetHours
        }
        set { store.set(newValue, forKey: Keys.sleepTargetHours); store.synchronize() }
    }

    var frozenExpirationDays: Int {
        get {
            let val = Int(store.longLong(forKey: Keys.frozenExpirationDays))
            return val > 0 ? val : AppConstants.defaultFrozenExpirationDays
        }
        set { store.set(Int64(newValue), forKey: Keys.frozenExpirationDays); store.synchronize() }
    }

    var timezone: String {
        get { store.string(forKey: Keys.timezone) ?? AppConstants.defaultTimezone }
        set { store.set(newValue, forKey: Keys.timezone); store.synchronize() }
    }

    var serverURL: String {
        get { store.string(forKey: Keys.serverURL) ?? "" }
        set { store.set(newValue, forKey: Keys.serverURL); store.synchronize() }
    }

    // MARK: - Init

    private init() {
        store.synchronize()
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            // Force SwiftUI views to re-read values
            self?.store.synchronize()
        }
    }

    // MARK: - Actions

    func resetToDefaults() {
        feedingTargetAmount = AppConstants.defaultFeedingTarget
        feedingTargetTime = AppConstants.defaultFeedingTargetTime
        sleepTargetHours = AppConstants.defaultSleepTargetHours
        frozenExpirationDays = AppConstants.defaultFrozenExpirationDays
        timezone = AppConstants.defaultTimezone
    }

    // MARK: - Keys

    private enum Keys {
        static let feedingTargetAmount = "feedingTargetAmount"
        static let feedingTargetTime = "feedingTargetTime"
        static let sleepTargetHours = "sleepTargetHours"
        static let frozenExpirationDays = "frozenExpirationDays"
        static let timezone = "timezone"
        static let serverURL = "serverURL"
    }
}
