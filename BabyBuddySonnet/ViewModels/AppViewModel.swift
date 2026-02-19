import Foundation

@Observable
@MainActor
final class AppViewModel {
    var child: Child?
    var isAuthenticated = false
    var isLoading = false
    var error: String?

    private let settings = SettingsService.shared

    func checkAuth() async {
        guard let token = KeychainService.loadToken(),
              !settings.serverURL.isEmpty
        else {
            isAuthenticated = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await APIClient.shared.configure(baseURL: settings.serverURL, token: token)
            let response: PaginatedResponse<Child> = try await APIClient.shared.get(
                path: APIEndpoints.children
            )
            child = response.results.first
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            isAuthenticated = false
        }
    }

    func authenticate(serverURL: String, token: String) async throws {
        try await APIClient.shared.configure(baseURL: serverURL, token: token)

        // Validate by fetching children
        let response: PaginatedResponse<Child> = try await APIClient.shared.get(
            path: APIEndpoints.children
        )

        // Save credentials
        try KeychainService.save(token: token)
        settings.serverURL = serverURL

        child = response.results.first
        isAuthenticated = true
    }

    func signOut() {
        KeychainService.deleteToken()
        settings.serverURL = ""
        child = nil
        isAuthenticated = false
    }

    func refreshChild() async {
        guard isAuthenticated else { return }
        do {
            let response: PaginatedResponse<Child> = try await APIClient.shared.get(
                path: APIEndpoints.children
            )
            child = response.results.first
        } catch {
            self.error = error.localizedDescription
        }
    }
}
