import Foundation

nonisolated struct Feeding: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int
    let start: String
    let end: String
    let duration: String?
    let type: String
    let method: String
    let amount: Double?
    let notes: String

    var feedingType: FeedingType? {
        FeedingType(rawValue: type)
    }

    var feedingMethod: FeedingMethod? {
        FeedingMethod(rawValue: method)
    }
}

nonisolated enum FeedingType: String, Codable, CaseIterable, Sendable {
    case breastMilk = "breast milk"
    case formula = "formula"
    case fortifiedBreastMilk = "fortified breast milk"
    case solidFood = "solid food"

    var displayName: String {
        switch self {
        case .breastMilk: return "Breast Milk"
        case .formula: return "Formula"
        case .fortifiedBreastMilk: return "Fortified"
        case .solidFood: return "Solid Food"
        }
    }
}

nonisolated enum FeedingMethod: String, Codable, CaseIterable, Sendable {
    case bottle = "bottle"
    case leftBreast = "left breast"
    case rightBreast = "right breast"
    case bothBreasts = "both breasts"
    case parentFed = "parent fed"
    case selfFed = "self fed"

    var displayName: String {
        switch self {
        case .bottle: return "Bottle"
        case .leftBreast: return "Left Breast"
        case .rightBreast: return "Right Breast"
        case .bothBreasts: return "Both Breasts"
        case .parentFed: return "Parent Fed"
        case .selfFed: return "Self Fed"
        }
    }

    var sfSymbol: String {
        switch self {
        case .bottle: return "cup.and.saucer.fill"
        case .leftBreast: return "l.circle.fill"
        case .rightBreast: return "r.circle.fill"
        case .bothBreasts: return "b.circle.fill"
        case .parentFed: return "hand.raised.fill"
        case .selfFed: return "figure.child"
        }
    }
}

nonisolated struct CreateFeedingInput: Codable, Sendable {
    let child: Int
    let start: String
    let end: String
    let type: String
    let method: String
    let amount: Double?
    let notes: String?
}
