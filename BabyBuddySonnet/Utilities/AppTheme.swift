import Foundation

// MARK: - PetModeTheme

/// Centralised string bundle for all user-facing text.
/// Swap between .baby and .dog by reading SettingsService.shared.theme.
/// All properties are immutable stored values so this struct is fully
/// nonisolated and Sendable — safe to use from any actor context under
/// Swift 6 / Xcode 26 default-MainActor isolation.
nonisolated struct PetModeTheme: Sendable {

    // MARK: - App Branding
    let appName: String
    let setupTagline: String
    let setupHint: String

    // MARK: - Tab Labels & Icons
    let feedingTabName: String
    let feedingTabIcon: String
    let sleepTabName: String
    let sleepTabIcon: String
    let diaperTabName: String
    let diaperTabIcon: String
    let pumpingTabName: String
    let pumpingTabIcon: String

    // MARK: - Diaper / Potty
    let diaperNavigationTitle: String
    let logDiaperTitle: String
    let editDiaperTitle: String
    let diaperWetLabel: String
    let diaperSolidLabel: String
    let diaperColorSectionTitle: String
    let diaperEmptyTitle: String
    let diaperEmptySubtitle: String
    let diaperWetDesc: String
    let diaperSolidDesc: String
    let diaperBothDesc: String
    let diaperWetStat: String
    let diaperSolidStat: String

    // MARK: - Feeding / Meals
    let feedingNavigationTitle: String
    let logFeedingTitle: String
    let editFeedingTitle: String
    let feedingEmptyTitle: String
    let feedingEmptySubtitle: String
    /// Keyed by FeedingType.rawValue (lowercase, e.g. "breast milk")
    let feedingTypeNames: [String: String]
    /// Keyed by FeedingMethod.rawValue (lowercase, e.g. "bottle")
    let feedingMethodNames: [String: String]

    // MARK: - Sleep / Rest
    let sleepNavigationTitle: String
    let logSleepTitle: String
    let editSleepTitle: String
    let sleepNightLabel: String
    let sleepTodayLabel: String
    let sleepTimelineTitle: String
    let sleepNightStat: String
    let sleepEmptyTitle: String
    let sleepEmptySubtitle: String

    // MARK: - Pumping / Food Supply
    let pumpingNavigationTitle: String
    let logPumpingTitle: String
    let editPumpingTitle: String
    let pumpingSessionsStat: String
    let pumpingOzStat: String
    let pumpingEmptyTitle: String
    let pumpingEmptySubtitle: String
    /// Keyed by MilkCategory.rawValue (e.g. "to-be-consumed")
    let milkCategoryNames: [String: String]
    let surplusCardTitle: String
    let surplusCardPumped: String
    let surplusCardConsumed: String
    let surplusCardSurplus: String

    // MARK: - Dashboard
    let dashboardLastFeedingLabel: String
    let dashboardSleepTodayLabel: String
    let quickActionFeedingLabel: String
    let quickActionPumpingLabel: String
    let quickActionSleepLabel: String
    let quickActionDiaperLabel: String
    let nextFeedingCategory: String
    let nextPumpingCategory: String
    let nextDiaperCategory: String

    // MARK: - About
    let aboutAppName: String
    let aboutAppIcon: String
    let aboutIconColor: String  // "pink" or "brown"

    // MARK: - Tab Helpers

    nonisolated func tabDisplayName(for tab: AppTab) -> String {
        switch tab {
        case .dashboard: return "Dashboard"
        case .feeding:   return feedingTabName
        case .sleep:     return sleepTabName
        case .diaper:    return diaperTabName
        case .pumping:   return pumpingTabName
        case .analytics: return "Analytics"
        }
    }

    nonisolated func tabIcon(for tab: AppTab) -> String {
        switch tab {
        case .dashboard: return "house.fill"
        case .feeding:   return feedingTabIcon
        case .sleep:     return sleepTabIcon
        case .diaper:    return diaperTabIcon
        case .pumping:   return pumpingTabIcon
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }

    // MARK: - Static Instances

    static let baby = PetModeTheme(
        appName: "Baby Buddy",
        setupTagline: "Connect to your Baby Buddy server",
        setupHint: "Find this in Baby Buddy under User Settings",
        feedingTabName: "Feeding",
        feedingTabIcon: "drop.fill",
        sleepTabName: "Sleep",
        sleepTabIcon: "moon.fill",
        diaperTabName: "Diaper",
        diaperTabIcon: "circle.dotted",
        pumpingTabName: "Pumping",
        pumpingTabIcon: "drop.triangle.fill",
        diaperNavigationTitle: "Diaper",
        logDiaperTitle: "Log Diaper",
        editDiaperTitle: "Edit Diaper",
        diaperWetLabel: "Wet",
        diaperSolidLabel: "Solid",
        diaperColorSectionTitle: "Stool Color",
        diaperEmptyTitle: "No changes today",
        diaperEmptySubtitle: "Tap + to log a diaper change",
        diaperWetDesc: "Wet",
        diaperSolidDesc: "Solid",
        diaperBothDesc: "Wet + Solid",
        diaperWetStat: "wet",
        diaperSolidStat: "solid",
        feedingNavigationTitle: "Feeding",
        logFeedingTitle: "Log Feeding",
        editFeedingTitle: "Edit Feeding",
        feedingEmptyTitle: "No feedings today",
        feedingEmptySubtitle: "Tap + to log a feeding",
        feedingTypeNames: [
            "breast milk": "Breast Milk",
            "formula": "Formula",
            "fortified breast milk": "Fortified",
            "solid food": "Solid Food"
        ],
        feedingMethodNames: [
            "bottle": "Bottle",
            "left breast": "Left Breast",
            "right breast": "Right Breast",
            "both breasts": "Both Breasts",
            "parent fed": "Parent Fed",
            "self fed": "Self Fed"
        ],
        sleepNavigationTitle: "Sleep",
        logSleepTitle: "Log Sleep",
        editSleepTitle: "Edit Sleep",
        sleepNightLabel: "Night Sleep",
        sleepTodayLabel: "Sleep today:",
        sleepTimelineTitle: "Sleep Timeline",
        sleepNightStat: "night",
        sleepEmptyTitle: "No sleep recorded today",
        sleepEmptySubtitle: "Tap + to log sleep",
        pumpingNavigationTitle: "Pumping",
        logPumpingTitle: "Log Pumping",
        editPumpingTitle: "Edit Pumping",
        pumpingSessionsStat: "sessions",
        pumpingOzStat: "oz today",
        pumpingEmptyTitle: "No pumping today",
        pumpingEmptySubtitle: "Tap + to log a pumping session",
        milkCategoryNames: [
            "to-be-consumed": "To Be Consumed",
            "consumed": "Consumed",
            "frozen": "Frozen"
        ],
        surplusCardTitle: "Daily Surplus",
        surplusCardPumped: "Pumped",
        surplusCardConsumed: "Consumed",
        surplusCardSurplus: "Surplus",
        dashboardLastFeedingLabel: "Last feeding:",
        dashboardSleepTodayLabel: "Sleep today:",
        quickActionFeedingLabel: "Feeding",
        quickActionPumpingLabel: "Pumping",
        quickActionSleepLabel: "Sleep",
        quickActionDiaperLabel: "Diaper",
        nextFeedingCategory: "Feeding",
        nextPumpingCategory: "Pumping",
        nextDiaperCategory: "Diaper",
        aboutAppName: "Baby Buddy",
        aboutAppIcon: "heart.fill",
        aboutIconColor: "pink"
    )

    static let dog = PetModeTheme(
        appName: "Fur Baby Buddy",
        setupTagline: "Connect to your Fur Baby Buddy server",
        setupHint: "Find this in Fur Baby Buddy under User Settings",
        feedingTabName: "Meals",
        feedingTabIcon: "fork.knife",
        sleepTabName: "Rest",
        sleepTabIcon: "moon.zzz.fill",
        diaperTabName: "Potty",
        diaperTabIcon: "pawprint.fill",
        pumpingTabName: "Food Supply",
        pumpingTabIcon: "bag.fill",
        diaperNavigationTitle: "Potty",
        logDiaperTitle: "Log Potty",
        editDiaperTitle: "Edit Potty",
        diaperWetLabel: "Pee",
        diaperSolidLabel: "Poop",
        diaperColorSectionTitle: "Color",
        diaperEmptyTitle: "No accidents today",
        diaperEmptySubtitle: "Tap + to log a potty break",
        diaperWetDesc: "Pee",
        diaperSolidDesc: "Poop",
        diaperBothDesc: "Pee & Poop",
        diaperWetStat: "pee",
        diaperSolidStat: "poop",
        feedingNavigationTitle: "Meals",
        logFeedingTitle: "Log Meal",
        editFeedingTitle: "Edit Meal",
        feedingEmptyTitle: "No meals today",
        feedingEmptySubtitle: "Tap + to log a meal",
        feedingTypeNames: [
            "breast milk": "Wet Food",
            "formula": "Kibble",
            "fortified breast milk": "Supplement Mix",
            "solid food": "Treats"
        ],
        feedingMethodNames: [
            "bottle": "Bowl",
            "left breast": "Left Side",
            "right breast": "Right Side",
            "both breasts": "Both Sides",
            "parent fed": "Hand Fed",
            "self fed": "Free Fed"
        ],
        sleepNavigationTitle: "Rest",
        logSleepTitle: "Log Rest",
        editSleepTitle: "Edit Rest",
        sleepNightLabel: "Overnight",
        sleepTodayLabel: "Rest today:",
        sleepTimelineTitle: "Rest Timeline",
        sleepNightStat: "overnight",
        sleepEmptyTitle: "No rest recorded today",
        sleepEmptySubtitle: "Tap + to log rest",
        pumpingNavigationTitle: "Food Supply",
        logPumpingTitle: "Log Food Stock",
        editPumpingTitle: "Edit Food Stock",
        pumpingSessionsStat: "restocks",
        pumpingOzStat: "oz added",
        pumpingEmptyTitle: "No restocks today",
        pumpingEmptySubtitle: "Tap + to log food stock",
        milkCategoryNames: [
            "to-be-consumed": "For Bowl",
            "consumed": "Used Up",
            "frozen": "In Pantry"
        ],
        surplusCardTitle: "Food Reserve",
        surplusCardPumped: "Stocked",
        surplusCardConsumed: "Fed",
        surplusCardSurplus: "Reserve",
        dashboardLastFeedingLabel: "Last meal:",
        dashboardSleepTodayLabel: "Rest today:",
        quickActionFeedingLabel: "Meals",
        quickActionPumpingLabel: "Food Supply",
        quickActionSleepLabel: "Rest",
        quickActionDiaperLabel: "Potty",
        nextFeedingCategory: "Meal",
        nextPumpingCategory: "Food Stock",
        nextDiaperCategory: "Potty",
        aboutAppName: "Fur Baby Buddy",
        aboutAppIcon: "pawprint.fill",
        aboutIconColor: "brown"
    )
}
