import Foundation

nonisolated struct Note: Codable, Identifiable, Sendable {
    let id: Int
    let child: Int
    let note: String
    let time: String
}

nonisolated struct CreateNoteInput: Codable, Sendable {
    let child: Int
    let note: String
    let time: String
}

nonisolated struct UpdateNoteInput: Codable, Sendable {
    let note: String?
    let time: String?
}
