import SwiftUI

nonisolated enum AppConstants {
    static let defaultFeedingTarget: Double = 24.0
    static let defaultFeedingTargetTime: String = "22:00"
    static let defaultFeedingWakeTime: String = "07:00"
    static let defaultFeedingAverageDays: Int = 3
    static let defaultSleepTargetHours: Double = 14.0
    static let defaultFrozenExpirationDays: Int = 180
    static let defaultTimezone: String = "America/Los_Angeles"

    // Default Start Time Offsets (seconds before now)
    static let defaultFeedingStartOffset: Int = 900        // 15 minutes
    static let defaultPumpingStartOffset: Int = 120        // 2 minutes
    static let defaultSleepStartOffset: Int = 3600         // 60 minutes
    static let defaultTummyTimeStartOffset: Int = 600      // 10 minutes
    static let defaultTimerFallbackOffset: Int = 3600      // 60 minutes (StopTimerSheet fallback)

    // AI Defaults
    static let defaultAIBaseURL: String = "https://api.openai.com"
    static let defaultAIModel: String = "gpt-4o-mini"

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
        .bottle: .jayFeedingFallback,
        .leftBreast: .jayBreastFeeding,
        .rightBreast: .jayBreastFeeding,
        .bothBreasts: .jayBreastFeeding,
        .parentFed: .jayPumpingFallback,
        .selfFed: .jayTummyTimeFallback,
    ]

    static let milkCategoryColors: [MilkCategory: Color] = [
        .toBeConsumed: .jayPumpingFallback,
        .consumed: .jayFeedingFallback,
        .frozen: .jayDiaperFallback,
    ]
}
