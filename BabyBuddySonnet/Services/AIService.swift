import Foundation

actor AIService {
    static let shared = AIService()

    private var apiKey: String?
    private var baseURL: URL?
    private var model: String = AppConstants.defaultAIModel
    private let session = URLSession.shared

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Configuration

    func configure(apiKey: String, baseURL: String, model: String) {
        self.apiKey = apiKey.isEmpty ? nil : apiKey
        self.baseURL = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines))
        self.model = model.isEmpty ? AppConstants.defaultAIModel : model
    }

    var isConfigured: Bool {
        apiKey != nil && baseURL != nil
    }

    // MARK: - Chat Completion

    func ask(question: String, context: String) async throws -> String {
        guard let apiKey, let baseURL else {
            throw AIError.notConfigured
        }

        let url = baseURL.appendingPathComponent("/v1/chat/completions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let systemPrompt = """
        You are a helpful baby care assistant. You analyze baby tracking data (feeding, sleep, diaper changes, pumping, growth measurements) and provide insights, answer questions, and identify patterns. \
        Be concise, supportive, and factual. When discussing health concerns, always recommend consulting a pediatrician. \
        Use the data context provided to give specific, data-driven answers.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Here is the baby's recent data:\n\n\(context)\n\nQuestion: \(question)"],
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_completion_tokens": 1000,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        let completionResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
        guard let content = completionResponse.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        return content
    }

    // MARK: - List Models

    func fetchModels() async throws -> [String] {
        guard let apiKey, let baseURL else {
            throw AIError.notConfigured
        }

        let url = baseURL.appendingPathComponent("/v1/models")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        let modelsResponse = try decoder.decode(ModelsListResponse.self, from: data)
        return modelsResponse.data.map(\.id).sorted()
    }
}

// MARK: - Errors

nonisolated enum AIError: LocalizedError {
    case notConfigured
    case networkError(Error)
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI is not configured. Please add your API key in Settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service."
        case .serverError(let code, let message):
            return "AI service error (\(code)): \(message)"
        case .emptyResponse:
            return "AI returned an empty response."
        }
    }
}
