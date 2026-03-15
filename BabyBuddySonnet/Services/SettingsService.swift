import Foundation

@Observable
final class SettingsService {
    static let shared = SettingsService()

    private let store = NSUbiquitousKeyValueStore.default

    // Stored properties tracked by @Observable — required so SwiftUI can observe
    // per-category changes. The methods below read/write these caches AND the
    // iCloud store. Without these, SwiftUI never re-renders when a method writes
    // to NSUbiquitousKeyValueStore because methods bypass @Observable tracking.
    private var reminderEnabledCache: [String: Bool] = [:]
    private var reminderThresholdCache: [String: Double] = [:]
    private var intervalEnabledCache: [String: Bool] = [:]
    private var intervalHoursCache: [String: Double] = [:]

    // AI settings caches — required so @Observable can track changes
    private var _aiApiKey: String = ""
    private var _aiBaseURL: String = ""
    private var _aiModel: String = ""

    // Tab order cache
    private var _tabOrder: [String] = []

    // Dashboard widgets cache
    private var _dashboardWidgets: [String] = []

    // Dog Mode cache — required so @Observable can track changes
    private var _isDogMode: Bool = false

    // Child sex cache — for WHO growth chart percentile selection
    private var _childSex: String = ""

    // MARK: - Feeding Settings

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

    var feedingWakeTime: String {
        get { store.string(forKey: Keys.feedingWakeTime) ?? AppConstants.defaultFeedingWakeTime }
        set { store.set(newValue, forKey: Keys.feedingWakeTime); store.synchronize() }
    }

    var feedingAverageDays: Int {
        get {
            let val = Int(store.longLong(forKey: Keys.feedingAverageDays))
            return val > 0 ? val : AppConstants.defaultFeedingAverageDays
        }
        set { store.set(Int64(newValue), forKey: Keys.feedingAverageDays); store.synchronize() }
    }

    // MARK: - Sleep Settings

    var sleepTargetHours: Double {
        get {
            let val = store.double(forKey: Keys.sleepTargetHours)
            return val > 0 ? val : AppConstants.defaultSleepTargetHours
        }
        set { store.set(newValue, forKey: Keys.sleepTargetHours); store.synchronize() }
    }

    // MARK: - General Settings

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
        get {
            if let url = store.string(forKey: Keys.serverURL), !url.isEmpty {
                return url
            }
            return UserDefaults.standard.string(forKey: Keys.serverURL) ?? ""
        }
        set {
            store.set(newValue, forKey: Keys.serverURL)
            store.synchronize()
            UserDefaults.standard.set(newValue, forKey: Keys.serverURL)
        }
    }

    // MARK: - Reminder Settings (per-category)

    func isReminderEnabled(for category: ReminderCategory) -> Bool {
        reminderEnabledCache[category.rawValue] ?? false
    }

    func setReminderEnabled(_ enabled: Bool, for category: ReminderCategory) {
        reminderEnabledCache[category.rawValue] = enabled
        store.set(enabled, forKey: reminderEnabledKey(for: category))
        store.synchronize()
    }

    func reminderThresholdHours(for category: ReminderCategory) -> Double {
        let val = reminderThresholdCache[category.rawValue] ?? 0
        return val > 0 ? val : category.defaultThresholdHours
    }

    func setReminderThresholdHours(_ hours: Double, for category: ReminderCategory) {
        reminderThresholdCache[category.rawValue] = hours
        store.set(hours, forKey: reminderThresholdKey(for: category))
        store.synchronize()
    }

    // MARK: - Expected Interval Settings (per-category)

    func isIntervalEnabled(for category: ReminderCategory) -> Bool {
        // Sleep doesn't use intervals
        guard category != .sleep else { return false }
        return intervalEnabledCache[category.rawValue] ?? false
    }

    func setIntervalEnabled(_ enabled: Bool, for category: ReminderCategory) {
        intervalEnabledCache[category.rawValue] = enabled
        store.set(enabled, forKey: intervalEnabledKey(for: category))
        store.synchronize()
    }

    func intervalHours(for category: ReminderCategory) -> Double {
        let val = intervalHoursCache[category.rawValue] ?? 0
        return val > 0 ? val : category.defaultIntervalHours
    }

    func setIntervalHours(_ hours: Double, for category: ReminderCategory) {
        intervalHoursCache[category.rawValue] = hours
        store.set(hours, forKey: intervalHoursKey(for: category))
        store.synchronize()
    }

    // MARK: - AI Settings

    var aiApiKey: String {
        get { _aiApiKey }
        set { _aiApiKey = newValue; store.set(newValue, forKey: Keys.aiApiKey); store.synchronize() }
    }

    var aiBaseURL: String {
        get { _aiBaseURL }
        set { _aiBaseURL = newValue; store.set(newValue, forKey: Keys.aiBaseURL); store.synchronize() }
    }

    var aiModel: String {
        get { _aiModel }
        set { _aiModel = newValue; store.set(newValue, forKey: Keys.aiModel); store.synchronize() }
    }

    // MARK: - Tab Order

    var tabOrder: [String] {
        get { _tabOrder }
        set {
            _tabOrder = newValue
            store.set(newValue, forKey: Keys.tabOrder)
            store.synchronize()
            UserDefaults.standard.set(newValue, forKey: Keys.tabOrder)
        }
    }

    // MARK: - Dashboard Widgets

    var dashboardWidgets: [DashboardWidget] {
        get { _dashboardWidgets.compactMap { DashboardWidget(rawValue: $0) } }
        set {
            _dashboardWidgets = newValue.map(\.rawValue)
            store.set(_dashboardWidgets, forKey: Keys.dashboardWidgets)
            store.synchronize()
            UserDefaults.standard.set(_dashboardWidgets, forKey: Keys.dashboardWidgets)
        }
    }

    func isDashboardWidgetEnabled(_ widget: DashboardWidget) -> Bool {
        _dashboardWidgets.contains(widget.rawValue)
    }

    func toggleDashboardWidget(_ widget: DashboardWidget) {
        if let index = _dashboardWidgets.firstIndex(of: widget.rawValue) {
            _dashboardWidgets.remove(at: index)
        } else {
            _dashboardWidgets.append(widget.rawValue)
        }
        store.set(_dashboardWidgets, forKey: Keys.dashboardWidgets)
        store.synchronize()
        UserDefaults.standard.set(_dashboardWidgets, forKey: Keys.dashboardWidgets)
    }

    // MARK: - Appearance

    var isDogMode: Bool {
        get { _isDogMode }
        set { _isDogMode = newValue; store.set(newValue, forKey: Keys.isDogMode); store.synchronize() }
    }

    var theme: PetModeTheme { isDogMode ? .dog : .baby }

    // MARK: - Child Profile

    /// Child's sex for WHO growth chart percentile selection ("M", "F", or "" for unset)
    var childSex: String {
        get { _childSex }
        set { _childSex = newValue; store.set(newValue, forKey: Keys.childSex); store.synchronize() }
    }

    // MARK: - Init

    private init() {
        store.synchronize()
        for category in ReminderCategory.allCases {
            reminderEnabledCache[category.rawValue] = store.bool(forKey: reminderEnabledKey(for: category))
            reminderThresholdCache[category.rawValue] = store.double(forKey: reminderThresholdKey(for: category))
            intervalEnabledCache[category.rawValue] = store.bool(forKey: intervalEnabledKey(for: category))
            intervalHoursCache[category.rawValue] = store.double(forKey: intervalHoursKey(for: category))
        }
        _aiApiKey = store.string(forKey: Keys.aiApiKey) ?? ""
        _aiBaseURL = store.string(forKey: Keys.aiBaseURL) ?? AppConstants.defaultAIBaseURL
        _aiModel = store.string(forKey: Keys.aiModel) ?? AppConstants.defaultAIModel
        if let order = store.array(forKey: Keys.tabOrder) as? [String] {
            _tabOrder = order
        } else if let order = UserDefaults.standard.array(forKey: Keys.tabOrder) as? [String] {
            _tabOrder = order
        } else {
            _tabOrder = AppTab.defaultOrder.map(\.rawValue)
        }
        if let widgets = store.array(forKey: Keys.dashboardWidgets) as? [String] {
            _dashboardWidgets = widgets
        } else if let widgets = UserDefaults.standard.array(forKey: Keys.dashboardWidgets) as? [String] {
            _dashboardWidgets = widgets
        } else {
            _dashboardWidgets = []
        }
        _isDogMode = store.bool(forKey: Keys.isDogMode)
        _childSex = store.string(forKey: Keys.childSex) ?? ""
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.store.synchronize()
            for category in ReminderCategory.allCases {
                self.reminderEnabledCache[category.rawValue] = self.store.bool(forKey: self.reminderEnabledKey(for: category))
                self.reminderThresholdCache[category.rawValue] = self.store.double(forKey: self.reminderThresholdKey(for: category))
                self.intervalEnabledCache[category.rawValue] = self.store.bool(forKey: self.intervalEnabledKey(for: category))
                self.intervalHoursCache[category.rawValue] = self.store.double(forKey: self.intervalHoursKey(for: category))
            }
            self._aiApiKey = self.store.string(forKey: Keys.aiApiKey) ?? ""
            self._aiBaseURL = self.store.string(forKey: Keys.aiBaseURL) ?? AppConstants.defaultAIBaseURL
            self._aiModel = self.store.string(forKey: Keys.aiModel) ?? AppConstants.defaultAIModel
            self._tabOrder = (self.store.array(forKey: Keys.tabOrder) as? [String]) ?? AppTab.defaultOrder.map(\.rawValue)
            UserDefaults.standard.set(self._tabOrder, forKey: Keys.tabOrder)
            self._dashboardWidgets = (self.store.array(forKey: Keys.dashboardWidgets) as? [String]) ?? []
            UserDefaults.standard.set(self._dashboardWidgets, forKey: Keys.dashboardWidgets)
            self._isDogMode = self.store.bool(forKey: Keys.isDogMode)
            self._childSex = self.store.string(forKey: Keys.childSex) ?? ""
        }
    }

    // MARK: - Actions

    func resetToDefaults() {
        feedingTargetAmount = AppConstants.defaultFeedingTarget
        feedingTargetTime = AppConstants.defaultFeedingTargetTime
        feedingWakeTime = AppConstants.defaultFeedingWakeTime
        feedingAverageDays = AppConstants.defaultFeedingAverageDays
        sleepTargetHours = AppConstants.defaultSleepTargetHours
        frozenExpirationDays = AppConstants.defaultFrozenExpirationDays
        timezone = AppConstants.defaultTimezone

        // Reset reminder settings
        for category in ReminderCategory.allCases {
            setReminderEnabled(false, for: category)
            setReminderThresholdHours(category.defaultThresholdHours, for: category)
            setIntervalEnabled(false, for: category)
            setIntervalHours(category.defaultIntervalHours, for: category)
        }

        // Reset AI settings
        aiApiKey = ""
        aiBaseURL = AppConstants.defaultAIBaseURL
        aiModel = AppConstants.defaultAIModel

        // Reset tab order
        tabOrder = AppTab.defaultOrder.map(\.rawValue)

        // Reset dashboard widgets
        dashboardWidgets = []

        // Reset appearance
        isDogMode = false

        // Reset child profile
        childSex = ""
    }

    // MARK: - Private Key Helpers

    private func reminderEnabledKey(for category: ReminderCategory) -> String {
        "\(category.rawValue)ReminderEnabled"
    }

    private func reminderThresholdKey(for category: ReminderCategory) -> String {
        "\(category.rawValue)ReminderThreshold"
    }

    private func intervalEnabledKey(for category: ReminderCategory) -> String {
        "\(category.rawValue)IntervalEnabled"
    }

    private func intervalHoursKey(for category: ReminderCategory) -> String {
        "\(category.rawValue)IntervalHours"
    }

    // MARK: - Keys

    private enum Keys {
        static let feedingTargetAmount = "feedingTargetAmount"
        static let feedingTargetTime = "feedingTargetTime"
        static let feedingWakeTime = "feedingWakeTime"
        static let feedingAverageDays = "feedingAverageDays"
        static let sleepTargetHours = "sleepTargetHours"
        static let frozenExpirationDays = "frozenExpirationDays"
        static let timezone = "timezone"
        static let serverURL = "serverURL"
        static let aiApiKey = "aiApiKey"
        static let aiBaseURL = "aiBaseURL"
        static let aiModel = "aiModel"
        static let tabOrder = "tabOrder"
        static let isDogMode = "isDogMode"
        static let dashboardWidgets = "dashboardWidgets"
        static let childSex = "childSex"
    }
}
