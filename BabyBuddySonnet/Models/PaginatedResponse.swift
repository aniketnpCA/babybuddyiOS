import Foundation

nonisolated struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]
}
