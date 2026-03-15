import Foundation

nonisolated struct TummyTime: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int
    let start: String
    let end: String
    let duration: String?
    let milestone: String?
}

nonisolated struct CreateTummyTimeInput: Codable, Sendable {
    let child: Int
    let start: String
    let end: String
    let milestone: String?
}

nonisolated struct UpdateTummyTimeInput: Codable, Sendable {
    let start: String?
    let end: String?
    let milestone: String?
}
