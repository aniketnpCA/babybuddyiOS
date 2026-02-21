import Foundation

nonisolated struct AIMessage: Codable, Sendable, Identifiable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    nonisolated enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
    }

    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

/// OpenAI-compatible chat completion request/response types
nonisolated struct ChatCompletionRequest: Codable, Sendable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int?

    nonisolated struct ChatMessage: Codable, Sendable {
        let role: String
        let content: String
    }
}

nonisolated struct ChatCompletionResponse: Codable, Sendable {
    let choices: [Choice]

    nonisolated struct Choice: Codable, Sendable {
        let message: MessageContent
    }

    nonisolated struct MessageContent: Codable, Sendable {
        let role: String
        let content: String
    }
}

/// OpenAI-compatible models list response
nonisolated struct ModelsListResponse: Codable, Sendable {
    let data: [ModelEntry]

    nonisolated struct ModelEntry: Codable, Sendable {
        let id: String
    }
}
