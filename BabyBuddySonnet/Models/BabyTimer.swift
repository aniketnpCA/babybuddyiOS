import Foundation

nonisolated struct BabyTimer: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int?
    let name: String
    let start: String
    let end: String?
    let duration: String?
    let active: Bool
    let user: Int
}
