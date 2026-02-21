import Foundation

nonisolated struct SleepRecord: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int
    let start: String
    let end: String
    let duration: String?
    let nap: Bool
    let notes: String?
}

nonisolated struct CreateSleepInput: Codable, Sendable {
    let child: Int
    let start: String
    let end: String
    let nap: Bool?
    let notes: String?
}

nonisolated struct UpdateSleepInput: Codable, Sendable {
    let start: String?
    let end: String?
    let nap: Bool?
    let notes: String?
}
