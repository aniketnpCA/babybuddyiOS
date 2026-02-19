import SwiftUI

nonisolated enum AppConstants {
    static let defaultFeedingTarget: Double = 24.0
    static let defaultFeedingTargetTime: String = "22:00"
    static let defaultFeedingWakeTime: String = "07:00"
    static let defaultFeedingAverageDays: Int = 3
    static let defaultSleepTargetHours: Double = 14.0
    static let defaultFrozenExpirationDays: Int = 180
    static let defaultTimezone: String = "America/Los_Angeles"

    static let timezones: [(value: String, label: String)] = [
        ("America/New_York", "Eastern"),
        ("America/Chicago", "Central"),
        ("America/Denver", "Mountain"),
        ("America/Los_Angeles", "Pacific"),
        ("America/Anchorage", "Alaska"),
        ("Pacific/Honolulu", "Hawaii"),
    ]

    static let diaperColors: [(color: StoolColor, swiftUIColor: Color)] = [
        (.yellow, .yellow),
        (.green, .green),
        (.brown, .brown),
        (.black, .primary),
        (.red, .red),
        (.white, .gray),
    ]

    static let feedingMethodColors: [FeedingMethod: Color] = [
        .bottle: .blue,
        .leftBreast: .pink,
        .rightBreast: .pink,
        .bothBreasts: .pink,
        .parentFed: .orange,
        .selfFed: .green,
    ]

    static let milkCategoryColors: [MilkCategory: Color] = [
        .toBeConsumed: .orange,
        .consumed: .blue,
        .frozen: .cyan,
    ]
}
