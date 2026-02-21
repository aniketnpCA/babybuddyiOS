import Foundation
import WidgetKit

/// Writes shared data to App Groups UserDefaults for Live Activities and Apple Watch.
/// Requires App Groups entitlement: "group.com.BabyBuddySonnet.shared"
@MainActor
enum SharedDataService {
    private static let suiteName = "group.com.BabyBuddySonnet.shared"

    static func update(
        childName: String,
        nextFeedingTime: Date?,
        nextPumpingTime: Date?,
        nextDiaperTime: Date?,
        dailyConsumedOz: Double,
        dailyTargetOz: Double
    ) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        defaults.set(childName, forKey: "childName")
        defaults.set(dailyConsumedOz, forKey: "dailyConsumedOz")
        defaults.set(dailyTargetOz, forKey: "dailyTargetOz")

        if let time = nextFeedingTime {
            defaults.set(time, forKey: "nextFeedingTime")
        } else {
            defaults.removeObject(forKey: "nextFeedingTime")
        }

        if let time = nextPumpingTime {
            defaults.set(time, forKey: "nextPumpingTime")
        } else {
            defaults.removeObject(forKey: "nextPumpingTime")
        }

        if let time = nextDiaperTime {
            defaults.set(time, forKey: "nextDiaperTime")
        } else {
            defaults.removeObject(forKey: "nextDiaperTime")
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "BabyBuddyWidget")
    }

    static func clear() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        for key in ["childName", "dailyConsumedOz", "dailyTargetOz", "nextFeedingTime", "nextPumpingTime", "nextDiaperTime"] {
            defaults.removeObject(forKey: key)
        }
    }
}
