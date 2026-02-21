import Foundation

nonisolated enum APIError: LocalizedError {
    case invalidURL
    case noToken
    case unauthorized
    case notFound
    case serverError(statusCode: Int, message: String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .noToken: return "Not authenticated. Please set up your API token."
        case .unauthorized: return "Invalid API token. Please check your settings."
        case .notFound: return "Resource not found"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .decodingError(let err): return "Failed to parse server response: \(err.localizedDescription)"
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private var baseURL: URL?
    private var token: String?
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

    func configure(baseURL: String, token: String) throws {
        // Normalize URL: remove trailing slash, ensure https
        var normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasSuffix("/") {
            normalized = String(normalized.dropLast())
        }
        guard let url = URL(string: normalized) else {
            throw APIError.invalidURL
        }
        self.baseURL = url
        self.token = token
    }

    var isConfigured: Bool {
        baseURL != nil && token != nil
    }

    // MARK: - HTTP Methods

    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let request = try buildRequest(path: path, method: "GET", queryItems: queryItems)
        return try await execute(request)
    }

    func post<T: Decodable, U: Encodable>(
        path: String,
        body: U
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        let request = try buildRequest(path: path, method: "POST", body: bodyData)
        return try await execute(request)
    }

    func patch<T: Decodable, U: Encodable>(
        path: String,
        body: U
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        let request = try buildRequest(path: path, method: "PATCH", body: bodyData)
        return try await execute(request)
    }

    func delete(path: String) async throws {
        let request = try buildRequest(path: path, method: "DELETE")
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Private

    private func buildRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) throws -> URLRequest {
        guard let baseURL else { throw APIError.noToken }
        guard let token else { throw APIError.noToken }

        // Use string concatenation to preserve trailing slashes in API paths.
        // appendingPathComponent() strips trailing slashes, which causes Django
        // to 301-redirect and drop the Authorization header — leading to 530/403 errors.
        guard let fullURL = URL(string: baseURL.absoluteString + path) else {
            throw APIError.invalidURL
        }
        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: true)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = body
        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        try validateResponse(response)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }
    }
}
