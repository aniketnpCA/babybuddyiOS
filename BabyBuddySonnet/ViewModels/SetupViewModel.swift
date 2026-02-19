import Foundation

@Observable
@MainActor
final class SetupViewModel {
    var serverURL: String = ""
    var apiToken: String = ""
    var isValidating = false
    var errorMessage: String?

    func validate(appViewModel: AppViewModel) async -> Bool {
        // Basic validation
        let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedURL.isEmpty else {
            errorMessage = "Please enter your Baby Buddy server URL"
            return false
        }

        guard trimmedURL.hasPrefix("http://") || trimmedURL.hasPrefix("https://") else {
            errorMessage = "URL must start with http:// or https://"
            return false
        }

        guard !trimmedToken.isEmpty else {
            errorMessage = "Please enter your API token"
            return false
        }

        isValidating = true
        errorMessage = nil
        defer { isValidating = false }

        do {
            try await appViewModel.authenticate(serverURL: trimmedURL, token: trimmedToken)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = "Connection failed: \(error.localizedDescription)"
            return false
        }
    }
}
