import Foundation

// MARK: - Growth Measurement Models

nonisolated struct WeightMeasurement: Codable, Sendable, Identifiable {
    let id: Int
    let child: Int
    let weight: Double // grams
    let date: String
    let notes: String?

    /// Convert grams to pounds
    var weightInLbs: Double {
        weight / 453.592
    }

    /// Convert grams to kg
    var weightInKg: Double {
        weight / 1000.0
    }
}

nonisolated struct HeightMeasurement: Codable, Sendable, Identifiable {
    let id: Int
    let child: Int
    let height: Double // cm
    let date: String
    let notes: String?

    /// Convert cm to inches
    var heightInInches: Double {
        height / 2.54
    }
}

nonisolated struct HeadCircumferenceMeasurement: Codable, Sendable, Identifiable {
    let id: Int
    let child: Int
    let headCircumference: Double // cm
    let date: String
    let notes: String?

    /// Convert cm to inches
    var headCircumferenceInInches: Double {
        headCircumference / 2.54
    }
}

nonisolated struct BMIMeasurement: Codable, Sendable, Identifiable {
    let id: Int
    let child: Int
    let bmi: Double
    let date: String
    let notes: String?
}

// MARK: - Create Input Structs

nonisolated struct CreateWeightInput: Codable, Sendable {
    let child: Int
    let weight: Double // grams
    let date: String
    let notes: String?
}

nonisolated struct CreateHeightInput: Codable, Sendable {
    let child: Int
    let height: Double // cm
    let date: String
    let notes: String?
}

nonisolated struct CreateHeadCircumferenceInput: Codable, Sendable {
    let child: Int
    let headCircumference: Double // cm
    let date: String
    let notes: String?
}
