import Foundation

nonisolated struct BabyTimer: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int?
    let name: String?
    let start: String
    let end: String?
    let duration: String?
    let active: Bool?
    let user: Int
}

nonisolated struct CreateTimerInput: Codable, Sendable {
    let child: Int
    let name: String?
    let start: String
}

nonisolated struct StopTimerInput: Codable, Sendable {
    let end: String
    let active: Bool
}
