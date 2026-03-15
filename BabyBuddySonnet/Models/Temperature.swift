import Foundation

nonisolated struct Temperature: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int
    let temperature: Double
    let time: String
    let notes: String?
}

nonisolated struct CreateTemperatureInput: Codable, Sendable {
    let child: Int
    let temperature: Double
    let time: String
    let notes: String?
}

nonisolated struct UpdateTemperatureInput: Codable, Sendable {
    let temperature: Double?
    let time: String?
    let notes: String?
}
