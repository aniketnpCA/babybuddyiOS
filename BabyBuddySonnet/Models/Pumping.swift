import Foundation

nonisolated struct Pumping: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int
    let start: String
    let end: String
    let duration: String?
    let amount: Double
    let notes: String

    var milkCategory: MilkCategory {
        MilkCategory.parse(from: notes)
    }
}

nonisolated enum MilkCategory: String, Codable, CaseIterable, Sendable {
    case toBeConsumed = "to-be-consumed"
    case consumed = "consumed"
    case frozen = "frozen"

    var displayName: String {
        switch self {
        case .toBeConsumed: return "To Be Consumed"
        case .consumed: return "Consumed"
        case .frozen: return "Frozen"
        }
    }

    static func parse(from notes: String) -> MilkCategory {
        guard !notes.isEmpty,
              let data = notes.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let categoryString = json["category"],
              let category = MilkCategory(rawValue: categoryString)
        else {
            return .toBeConsumed
        }
        return category
    }

    static func createNotes(for category: MilkCategory) -> String {
        let json: [String: String] = ["category": category.rawValue]
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let string = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return string
    }
}

nonisolated struct CreatePumpingInput: Codable, Sendable {
    let child: Int
    let start: String
    let end: String
    let amount: Double
    let notes: String?
}
