import SwiftUI

// MARK: - Jaybird Color Palette
// Warm, dusty tones inspired by Structured. Adapts for dark mode.

extension Color {
    // MARK: - Category Colors (warm/dusty variants)
    static let jayFeeding = Color("JayFeeding", bundle: nil)
    static let jayPumping = Color("JayPumping", bundle: nil)
    static let jaySleep = Color("JaySleep", bundle: nil)
    static let jayDiaper = Color("JayDiaper", bundle: nil)
    static let jayTummyTime = Color("JayTummyTime", bundle: nil)
    static let jayTemperature = Color("JayTemperature", bundle: nil)
    static let jayNotes = Color("JayNotes", bundle: nil)

    // MARK: - Programmatic fallbacks (used if asset catalog colors aren't set)
    // These work in both light and dark mode via adaptive init

    /// Dusty blue - feeding
    static let jayFeedingFallback = Color(light: .init(red: 0.42, green: 0.55, blue: 0.64),
                                          dark: .init(red: 0.53, green: 0.68, blue: 0.80))
    /// Warm coral - pumping
    static let jayPumpingFallback = Color(light: .init(red: 0.85, green: 0.53, blue: 0.42),
                                          dark: .init(red: 0.90, green: 0.62, blue: 0.52))
    /// Muted lavender - sleep
    static let jaySleepFallback = Color(light: .init(red: 0.55, green: 0.48, blue: 0.64),
                                         dark: .init(red: 0.67, green: 0.60, blue: 0.78))
    /// Sage green - diaper
    static let jayDiaperFallback = Color(light: .init(red: 0.48, green: 0.64, blue: 0.56),
                                          dark: .init(red: 0.58, green: 0.78, blue: 0.68))
    /// Olive - tummy time
    static let jayTummyTimeFallback = Color(light: .init(red: 0.55, green: 0.66, blue: 0.44),
                                             dark: .init(red: 0.65, green: 0.78, blue: 0.55))
    /// Dusty rose - temperature
    static let jayTemperatureFallback = Color(light: .init(red: 0.77, green: 0.48, blue: 0.48),
                                               dark: .init(red: 0.85, green: 0.58, blue: 0.58))
    /// Warm gold - notes
    static let jayNotesFallback = Color(light: .init(red: 0.77, green: 0.66, blue: 0.30),
                                         dark: .init(red: 0.85, green: 0.75, blue: 0.42))

    /// Accent salmon/rose
    static let jayAccent = Color(light: .init(red: 0.83, green: 0.56, blue: 0.56),
                                  dark: .init(red: 0.88, green: 0.65, blue: 0.65))

    /// Warm off-white background
    static let jayBackground = Color(light: .init(red: 0.98, green: 0.97, blue: 0.96),
                                      dark: .init(red: 0.11, green: 0.11, blue: 0.12))

    /// Card background - slightly elevated
    static let jayCardBackground = Color(light: .init(red: 1.0, green: 0.99, blue: 0.98),
                                          dark: .init(red: 0.15, green: 0.15, blue: 0.16))

    /// Nap color (warm sun)
    static let jayNap = Color(light: .init(red: 0.85, green: 0.65, blue: 0.35),
                               dark: .init(red: 0.90, green: 0.72, blue: 0.45))

    // MARK: - Breast feeding variants
    static let jayBreastFeeding = Color(light: .init(red: 0.78, green: 0.52, blue: 0.60),
                                         dark: .init(red: 0.85, green: 0.62, blue: 0.70))

    // MARK: - Adaptive Color Helper
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Category Color Resolver

nonisolated enum JayColors {
    /// Returns the warm category color for a given activity type
    static func color(for category: TimelineCategory) -> Color {
        switch category {
        case .feeding: return .jayFeedingFallback
        case .pumping: return .jayPumpingFallback
        case .sleep: return .jaySleepFallback
        case .diaper: return .jayDiaperFallback
        case .tummyTime: return .jayTummyTimeFallback
        case .temperature: return .jayTemperatureFallback
        case .note: return .jayNotesFallback
        }
    }

    /// Feeding method colors (warm variants)
    static func feedingMethodColor(_ method: FeedingMethod) -> Color {
        switch method {
        case .bottle: return .jayFeedingFallback
        case .leftBreast, .rightBreast, .bothBreasts: return .jayBreastFeeding
        case .parentFed: return .jayPumpingFallback
        case .selfFed: return .jayTummyTimeFallback
        }
    }

    /// Milk category colors (warm variants)
    static func milkCategoryColor(_ category: MilkCategory) -> Color {
        switch category {
        case .toBeConsumed: return .jayPumpingFallback
        case .consumed: return .jayFeedingFallback
        case .frozen: return .jayDiaperFallback
        }
    }

    /// Diaper type color
    static func diaperColor(wet: Bool, solid: Bool) -> Color {
        if wet && solid { return .jayDiaperFallback }
        if wet { return .jayFeedingFallback }
        if solid { return Color(light: .init(red: 0.60, green: 0.50, blue: 0.38),
                                dark: .init(red: 0.72, green: 0.60, blue: 0.48)) }
        return .secondary
    }

    /// Sleep color (nap vs night)
    static func sleepColor(isNap: Bool) -> Color {
        isNap ? .jayNap : .jaySleepFallback
    }
}
