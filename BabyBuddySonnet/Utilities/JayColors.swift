import SwiftUI

// MARK: - Jaybird Color Palette
// Warm, dusty tones inspired by Structured. Adapts for dark mode.

extension Color {
    // MARK: - Category Colors (warm/dusty variants)
    nonisolated(unsafe) static let jayFeeding = Color("JayFeeding", bundle: nil)
    nonisolated(unsafe) static let jayPumping = Color("JayPumping", bundle: nil)
    nonisolated(unsafe) static let jaySleep = Color("JaySleep", bundle: nil)
    nonisolated(unsafe) static let jayDiaper = Color("JayDiaper", bundle: nil)
    nonisolated(unsafe) static let jayTummyTime = Color("JayTummyTime", bundle: nil)
    nonisolated(unsafe) static let jayTemperature = Color("JayTemperature", bundle: nil)
    nonisolated(unsafe) static let jayNotes = Color("JayNotes", bundle: nil)

    // MARK: - Programmatic fallbacks (used if asset catalog colors aren't set)
    // These work in both light and dark mode via adaptive init

    /// Dusty blue - feeding
    nonisolated(unsafe) static let jayFeedingFallback = Color(uiColor: UIColor(
        light: UIColor(red: 0.42, green: 0.55, blue: 0.64, alpha: 1),
        dark:  UIColor(red: 0.53, green: 0.68, blue: 0.80, alpha: 1)
    ))
    /// Warm coral - pumping
    nonisolated(unsafe) static let jayPumpingFallback = Color(uiColor: UIColor(
        light: UIColor(red: 0.85, green: 0.53, blue: 0.42, alpha: 1),
        dark:  UIColor(red: 0.90, green: 0.62, blue: 0.52, alpha: 1)
    ))
    /// Muted lavender - sleep
    nonisolated(unsafe) static let jaySleepFallback = Color(uiColor: UIColor(
        light: UIColor(red: 0.55, green: 0.48, blue: 0.64, alpha: 1),
        dark:  UIColor(red: 0.67, green: 0.60, blue: 0.78, alpha: 1)
    ))
    /// Sage green - diaper
    nonisolated(unsafe) static let jayDiaperFallback = Color(uiColor: UIColor(
        light: UIColor(red: 0.48, green: 0.64, blue: 0.56, alpha: 1),
        dark:  UIColor(red: 0.58, green: 0.78, blue: 0.68, alpha: 1)
    ))
    /// Olive - tummy time
    nonisolated(unsafe) static let jayTummyTimeFallback = Color(uiColor: UIColor(
        light: UIColor(red: 0.55, green: 0.66, blue: 0.44, alpha: 1),
        dark:  UIColor(red: 0.65, green: 0.78, blue: 0.55, alpha: 1)
    ))
    /// Dusty rose - temperature
    nonisolated(unsafe) static let jayTemperatureFallback = Color(uiColor: UIColor(
        light: UIColor(red: 0.77, green: 0.48, blue: 0.48, alpha: 1),
        dark:  UIColor(red: 0.85, green: 0.58, blue: 0.58, alpha: 1)
    ))
    /// Warm gold - notes
    nonisolated(unsafe) static let jayNotesFallback = Color(uiColor: UIColor(
        light: UIColor(red: 0.77, green: 0.66, blue: 0.30, alpha: 1),
        dark:  UIColor(red: 0.85, green: 0.75, blue: 0.42, alpha: 1)
    ))

    /// Accent salmon/rose
    nonisolated(unsafe) static let jayAccent = Color(uiColor: UIColor(
        light: UIColor(red: 0.83, green: 0.56, blue: 0.56, alpha: 1),
        dark:  UIColor(red: 0.88, green: 0.65, blue: 0.65, alpha: 1)
    ))

    /// Warm off-white background
    nonisolated(unsafe) static let jayBackground = Color(uiColor: UIColor(
        light: UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1),
        dark:  UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
    ))

    /// Card background - slightly elevated
    nonisolated(unsafe) static let jayCardBackground = Color(uiColor: UIColor(
        light: UIColor(red: 1.0,  green: 0.99, blue: 0.98, alpha: 1),
        dark:  UIColor(red: 0.15, green: 0.15, blue: 0.16, alpha: 1)
    ))

    /// Nap color (warm sun)
    nonisolated(unsafe) static let jayNap = Color(uiColor: UIColor(
        light: UIColor(red: 0.85, green: 0.65, blue: 0.35, alpha: 1),
        dark:  UIColor(red: 0.90, green: 0.72, blue: 0.45, alpha: 1)
    ))

    // MARK: - Breast feeding variants
    nonisolated(unsafe) static let jayBreastFeeding = Color(uiColor: UIColor(
        light: UIColor(red: 0.78, green: 0.52, blue: 0.60, alpha: 1),
        dark:  UIColor(red: 0.85, green: 0.62, blue: 0.70, alpha: 1)
    ))
}

// MARK: - Adaptive UIColor helper (nonisolated, safe for static initializers)
extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
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
        if solid { return Color(uiColor: UIColor(
                                light: UIColor(red: 0.60, green: 0.50, blue: 0.38, alpha: 1),
                                dark:  UIColor(red: 0.72, green: 0.60, blue: 0.48, alpha: 1))) }
        return .secondary
    }

    /// Sleep color (nap vs night)
    static func sleepColor(isNap: Bool) -> Color {
        isNap ? .jayNap : .jaySleepFallback
    }
}
