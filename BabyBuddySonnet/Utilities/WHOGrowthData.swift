import Foundation

/// WHO Child Growth Standards (boys & girls, 0–24 months)
/// Source: WHO Multicentre Growth Reference Study Group
/// https://www.who.int/tools/child-growth-standards
nonisolated enum WHOGrowthData {

    struct Percentiles: Sendable {
        let p3: Double
        let p50: Double
        let p97: Double
    }

    // MARK: - Boys

    /// Weight-for-age percentiles for boys (kg), indexed by month 0–24
    static let boyWeightKg: [Percentiles] = [
        Percentiles(p3: 2.5, p50: 3.3, p97: 4.4),    // 0 months (birth)
        Percentiles(p3: 3.4, p50: 4.5, p97: 5.8),    // 1 month
        Percentiles(p3: 4.3, p50: 5.6, p97: 7.1),    // 2 months
        Percentiles(p3: 5.0, p50: 6.4, p97: 8.0),    // 3 months
        Percentiles(p3: 5.6, p50: 7.0, p97: 8.7),    // 4 months
        Percentiles(p3: 6.0, p50: 7.5, p97: 9.3),    // 5 months
        Percentiles(p3: 6.4, p50: 7.9, p97: 9.8),    // 6 months
        Percentiles(p3: 6.7, p50: 8.3, p97: 10.3),   // 7 months
        Percentiles(p3: 6.9, p50: 8.6, p97: 10.7),   // 8 months
        Percentiles(p3: 7.1, p50: 8.9, p97: 11.0),   // 9 months
        Percentiles(p3: 7.4, p50: 9.2, p97: 11.4),   // 10 months
        Percentiles(p3: 7.6, p50: 9.4, p97: 11.7),   // 11 months
        Percentiles(p3: 7.7, p50: 9.6, p97: 12.0),   // 12 months
        Percentiles(p3: 7.9, p50: 9.9, p97: 12.3),   // 13 months
        Percentiles(p3: 8.1, p50: 10.1, p97: 12.6),  // 14 months
        Percentiles(p3: 8.3, p50: 10.3, p97: 12.8),  // 15 months
        Percentiles(p3: 8.4, p50: 10.5, p97: 13.1),  // 16 months
        Percentiles(p3: 8.6, p50: 10.7, p97: 13.4),  // 17 months
        Percentiles(p3: 8.8, p50: 10.9, p97: 13.7),  // 18 months
        Percentiles(p3: 8.9, p50: 11.1, p97: 13.9),  // 19 months
        Percentiles(p3: 9.1, p50: 11.3, p97: 14.2),  // 20 months
        Percentiles(p3: 9.2, p50: 11.5, p97: 14.5),  // 21 months
        Percentiles(p3: 9.4, p50: 11.8, p97: 14.7),  // 22 months
        Percentiles(p3: 9.5, p50: 12.0, p97: 15.0),  // 23 months
        Percentiles(p3: 9.7, p50: 12.2, p97: 15.3),  // 24 months
    ]

    /// Length/height-for-age percentiles for boys (cm), indexed by month 0–24
    static let boyLengthCm: [Percentiles] = [
        Percentiles(p3: 46.1, p50: 49.9, p97: 53.7),   // 0 months
        Percentiles(p3: 50.8, p50: 54.7, p97: 58.6),   // 1 month
        Percentiles(p3: 54.4, p50: 58.4, p97: 62.4),   // 2 months
        Percentiles(p3: 57.3, p50: 61.4, p97: 65.5),   // 3 months
        Percentiles(p3: 59.7, p50: 63.9, p97: 68.0),   // 4 months
        Percentiles(p3: 61.7, p50: 65.9, p97: 70.1),   // 5 months
        Percentiles(p3: 63.3, p50: 67.6, p97: 71.9),   // 6 months
        Percentiles(p3: 64.8, p50: 69.2, p97: 73.5),   // 7 months
        Percentiles(p3: 66.2, p50: 70.6, p97: 75.0),   // 8 months
        Percentiles(p3: 67.5, p50: 72.0, p97: 76.5),   // 9 months
        Percentiles(p3: 68.7, p50: 73.3, p97: 77.9),   // 10 months
        Percentiles(p3: 69.9, p50: 74.5, p97: 79.2),   // 11 months
        Percentiles(p3: 71.0, p50: 75.7, p97: 80.5),   // 12 months
        Percentiles(p3: 72.1, p50: 76.9, p97: 81.8),   // 13 months
        Percentiles(p3: 73.1, p50: 78.0, p97: 82.9),   // 14 months
        Percentiles(p3: 74.1, p50: 79.1, p97: 84.2),   // 15 months
        Percentiles(p3: 75.0, p50: 80.2, p97: 85.4),   // 16 months
        Percentiles(p3: 76.0, p50: 81.2, p97: 86.5),   // 17 months
        Percentiles(p3: 76.9, p50: 82.3, p97: 87.7),   // 18 months
        Percentiles(p3: 77.7, p50: 83.2, p97: 88.8),   // 19 months
        Percentiles(p3: 78.6, p50: 84.2, p97: 89.8),   // 20 months
        Percentiles(p3: 79.4, p50: 85.1, p97: 90.9),   // 21 months
        Percentiles(p3: 80.2, p50: 86.0, p97: 91.9),   // 22 months
        Percentiles(p3: 81.0, p50: 86.9, p97: 92.9),   // 23 months
        Percentiles(p3: 81.7, p50: 87.8, p97: 93.9),   // 24 months
    ]

    /// Head circumference-for-age percentiles for boys (cm), indexed by month 0–24
    static let boyHeadCircumferenceCm: [Percentiles] = [
        Percentiles(p3: 32.1, p50: 34.5, p97: 36.9),   // 0 months
        Percentiles(p3: 34.9, p50: 37.3, p97: 39.6),   // 1 month
        Percentiles(p3: 36.8, p50: 39.1, p97: 41.5),   // 2 months
        Percentiles(p3: 38.1, p50: 40.5, p97: 42.9),   // 3 months
        Percentiles(p3: 39.2, p50: 41.6, p97: 44.0),   // 4 months
        Percentiles(p3: 40.1, p50: 42.6, p97: 45.0),   // 5 months
        Percentiles(p3: 40.9, p50: 43.3, p97: 45.8),   // 6 months
        Percentiles(p3: 41.5, p50: 44.0, p97: 46.4),   // 7 months
        Percentiles(p3: 42.0, p50: 44.5, p97: 47.0),   // 8 months
        Percentiles(p3: 42.5, p50: 45.0, p97: 47.5),   // 9 months
        Percentiles(p3: 42.9, p50: 45.4, p97: 47.9),   // 10 months
        Percentiles(p3: 43.2, p50: 45.8, p97: 48.3),   // 11 months
        Percentiles(p3: 43.5, p50: 46.1, p97: 48.6),   // 12 months
        Percentiles(p3: 43.8, p50: 46.3, p97: 48.9),   // 13 months
        Percentiles(p3: 44.0, p50: 46.6, p97: 49.1),   // 14 months
        Percentiles(p3: 44.2, p50: 46.8, p97: 49.4),   // 15 months
        Percentiles(p3: 44.4, p50: 47.0, p97: 49.6),   // 16 months
        Percentiles(p3: 44.6, p50: 47.2, p97: 49.8),   // 17 months
        Percentiles(p3: 44.7, p50: 47.4, p97: 50.0),   // 18 months
        Percentiles(p3: 44.9, p50: 47.5, p97: 50.2),   // 19 months
        Percentiles(p3: 45.0, p50: 47.7, p97: 50.4),   // 20 months
        Percentiles(p3: 45.2, p50: 47.8, p97: 50.5),   // 21 months
        Percentiles(p3: 45.3, p50: 48.0, p97: 50.7),   // 22 months
        Percentiles(p3: 45.4, p50: 48.1, p97: 50.8),   // 23 months
        Percentiles(p3: 45.5, p50: 48.3, p97: 51.0),   // 24 months
    ]

    // MARK: - Girls

    /// Weight-for-age percentiles for girls (kg), indexed by month 0–24
    static let girlWeightKg: [Percentiles] = [
        Percentiles(p3: 2.4, p50: 3.2, p97: 4.2),    // 0 months (birth)
        Percentiles(p3: 3.2, p50: 4.2, p97: 5.5),    // 1 month
        Percentiles(p3: 3.9, p50: 5.1, p97: 6.6),    // 2 months
        Percentiles(p3: 4.5, p50: 5.8, p97: 7.5),    // 3 months
        Percentiles(p3: 5.0, p50: 6.4, p97: 8.2),    // 4 months
        Percentiles(p3: 5.4, p50: 6.9, p97: 8.8),    // 5 months
        Percentiles(p3: 5.7, p50: 7.3, p97: 9.3),    // 6 months
        Percentiles(p3: 6.0, p50: 7.6, p97: 9.8),    // 7 months
        Percentiles(p3: 6.3, p50: 7.9, p97: 10.2),   // 8 months
        Percentiles(p3: 6.5, p50: 8.2, p97: 10.5),   // 9 months
        Percentiles(p3: 6.7, p50: 8.5, p97: 10.9),   // 10 months
        Percentiles(p3: 6.9, p50: 8.7, p97: 11.2),   // 11 months
        Percentiles(p3: 7.0, p50: 8.9, p97: 11.5),   // 12 months
        Percentiles(p3: 7.2, p50: 9.2, p97: 11.8),   // 13 months
        Percentiles(p3: 7.4, p50: 9.4, p97: 12.1),   // 14 months
        Percentiles(p3: 7.6, p50: 9.6, p97: 12.4),   // 15 months
        Percentiles(p3: 7.7, p50: 9.8, p97: 12.6),   // 16 months
        Percentiles(p3: 7.9, p50: 10.0, p97: 12.9),  // 17 months
        Percentiles(p3: 8.1, p50: 10.2, p97: 13.2),  // 18 months
        Percentiles(p3: 8.2, p50: 10.4, p97: 13.5),  // 19 months
        Percentiles(p3: 8.4, p50: 10.6, p97: 13.7),  // 20 months
        Percentiles(p3: 8.6, p50: 10.9, p97: 14.0),  // 21 months
        Percentiles(p3: 8.7, p50: 11.1, p97: 14.3),  // 22 months
        Percentiles(p3: 8.9, p50: 11.3, p97: 14.6),  // 23 months
        Percentiles(p3: 9.0, p50: 11.5, p97: 14.8),  // 24 months
    ]

    /// Length/height-for-age percentiles for girls (cm), indexed by month 0–24
    static let girlLengthCm: [Percentiles] = [
        Percentiles(p3: 45.4, p50: 49.1, p97: 52.9),   // 0 months
        Percentiles(p3: 49.8, p50: 53.7, p97: 57.6),   // 1 month
        Percentiles(p3: 53.0, p50: 57.1, p97: 61.1),   // 2 months
        Percentiles(p3: 55.6, p50: 59.8, p97: 64.0),   // 3 months
        Percentiles(p3: 57.8, p50: 62.1, p97: 66.4),   // 4 months
        Percentiles(p3: 59.6, p50: 64.0, p97: 68.5),   // 5 months
        Percentiles(p3: 61.2, p50: 65.7, p97: 70.3),   // 6 months
        Percentiles(p3: 62.7, p50: 67.3, p97: 71.9),   // 7 months
        Percentiles(p3: 64.0, p50: 68.7, p97: 73.5),   // 8 months
        Percentiles(p3: 65.3, p50: 70.1, p97: 75.0),   // 9 months
        Percentiles(p3: 66.5, p50: 71.5, p97: 76.4),   // 10 months
        Percentiles(p3: 67.7, p50: 72.8, p97: 77.8),   // 11 months
        Percentiles(p3: 68.9, p50: 74.0, p97: 79.2),   // 12 months
        Percentiles(p3: 70.0, p50: 75.2, p97: 80.5),   // 13 months
        Percentiles(p3: 71.0, p50: 76.4, p97: 81.7),   // 14 months
        Percentiles(p3: 72.0, p50: 77.5, p97: 83.0),   // 15 months
        Percentiles(p3: 73.0, p50: 78.6, p97: 84.2),   // 16 months
        Percentiles(p3: 74.0, p50: 79.7, p97: 85.4),   // 17 months
        Percentiles(p3: 74.9, p50: 80.7, p97: 86.5),   // 18 months
        Percentiles(p3: 75.8, p50: 81.7, p97: 87.6),   // 19 months
        Percentiles(p3: 76.7, p50: 82.7, p97: 88.7),   // 20 months
        Percentiles(p3: 77.5, p50: 83.7, p97: 89.8),   // 21 months
        Percentiles(p3: 78.4, p50: 84.6, p97: 90.8),   // 22 months
        Percentiles(p3: 79.2, p50: 85.5, p97: 91.9),   // 23 months
        Percentiles(p3: 80.0, p50: 86.4, p97: 92.9),   // 24 months
    ]

    /// Head circumference-for-age percentiles for girls (cm), indexed by month 0–24
    static let girlHeadCircumferenceCm: [Percentiles] = [
        Percentiles(p3: 31.5, p50: 33.9, p97: 36.2),   // 0 months
        Percentiles(p3: 34.2, p50: 36.5, p97: 38.9),   // 1 month
        Percentiles(p3: 35.8, p50: 38.3, p97: 40.7),   // 2 months
        Percentiles(p3: 37.1, p50: 39.5, p97: 42.0),   // 3 months
        Percentiles(p3: 38.1, p50: 40.6, p97: 43.1),   // 4 months
        Percentiles(p3: 38.9, p50: 41.5, p97: 44.0),   // 5 months
        Percentiles(p3: 39.6, p50: 42.2, p97: 44.8),   // 6 months
        Percentiles(p3: 40.2, p50: 42.8, p97: 45.5),   // 7 months
        Percentiles(p3: 40.7, p50: 43.4, p97: 46.0),   // 8 months
        Percentiles(p3: 41.2, p50: 43.8, p97: 46.5),   // 9 months
        Percentiles(p3: 41.5, p50: 44.2, p97: 46.9),   // 10 months
        Percentiles(p3: 41.9, p50: 44.6, p97: 47.3),   // 11 months
        Percentiles(p3: 42.2, p50: 44.9, p97: 47.6),   // 12 months
        Percentiles(p3: 42.4, p50: 45.2, p97: 47.9),   // 13 months
        Percentiles(p3: 42.7, p50: 45.4, p97: 48.2),   // 14 months
        Percentiles(p3: 42.9, p50: 45.7, p97: 48.4),   // 15 months
        Percentiles(p3: 43.1, p50: 45.9, p97: 48.6),   // 16 months
        Percentiles(p3: 43.3, p50: 46.1, p97: 48.8),   // 17 months
        Percentiles(p3: 43.5, p50: 46.2, p97: 49.0),   // 18 months
        Percentiles(p3: 43.6, p50: 46.4, p97: 49.2),   // 19 months
        Percentiles(p3: 43.8, p50: 46.6, p97: 49.4),   // 20 months
        Percentiles(p3: 43.9, p50: 46.7, p97: 49.5),   // 21 months
        Percentiles(p3: 44.1, p50: 46.9, p97: 49.7),   // 22 months
        Percentiles(p3: 44.2, p50: 47.0, p97: 49.8),   // 23 months
        Percentiles(p3: 44.3, p50: 47.2, p97: 50.0),   // 24 months
    ]

    // MARK: - Lookup Functions

    /// Get weight percentiles for a given age and sex ("M", "F", or "" for boys default)
    static func weightPercentiles(atMonth month: Int, sex: String = "") -> Percentiles {
        let data = sex == "F" ? girlWeightKg : boyWeightKg
        let index = min(max(month, 0), data.count - 1)
        return data[index]
    }

    /// Get length percentiles for a given age and sex
    static func lengthPercentiles(atMonth month: Int, sex: String = "") -> Percentiles {
        let data = sex == "F" ? girlLengthCm : boyLengthCm
        let index = min(max(month, 0), data.count - 1)
        return data[index]
    }

    /// Get head circumference percentiles for a given age and sex
    static func headCircumferencePercentiles(atMonth month: Int, sex: String = "") -> Percentiles {
        let data = sex == "F" ? girlHeadCircumferenceCm : boyHeadCircumferenceCm
        let index = min(max(month, 0), data.count - 1)
        return data[index]
    }
}
