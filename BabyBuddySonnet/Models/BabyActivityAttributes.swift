import ActivityKit
import Foundation

struct BabyActivityAttributes: ActivityAttributes {
    let childName: String

    struct ContentState: Codable, Hashable {
        let nextFeedingTime: Date?
        let nextPumpingTime: Date?
        let nextDiaperTime: Date?
        let dailyConsumedOz: Double
        let dailyTargetOz: Double
    }
}
