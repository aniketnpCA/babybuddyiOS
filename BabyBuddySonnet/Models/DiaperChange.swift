import Foundation

nonisolated struct DiaperChange: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int
    let time: String
    let wet: Bool
    let solid: Bool
    let color: String
    let amount: Double?
    let notes: String

    var stoolColor: StoolColor? {
        StoolColor(rawValue: color)
    }

    var typeDescription: String {
        if wet && solid { return "Wet + Solid" }
        if wet { return "Wet" }
        if solid { return "Solid" }
        return "Empty"
    }
}

nonisolated enum StoolColor: String, Codable, CaseIterable, Sendable {
    case yellow
    case green
    case brown
    case black
    case red
    case white

    var displayName: String { rawValue.capitalized }
}

nonisolated struct CreateDiaperChangeInput: Codable, Sendable {
    let child: Int
    let time: String
    let wet: Bool
    let solid: Bool
    let color: String?
    let notes: String?
}
