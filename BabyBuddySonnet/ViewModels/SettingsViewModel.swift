import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    let settings = SettingsService.shared

    var newApiToken: String = ""
    var isUpdatingToken = false
    var tokenUpdateError: String?
    var tokenUpdateSuccess = false

    func updateAPIToken(_ token: String, appViewModel: AppViewModel) async {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            tokenUpdateError = "Token cannot be empty"
            return
        }

        isUpdatingToken = true
        tokenUpdateError = nil
        tokenUpdateSuccess = false
        defer { isUpdatingToken = false }

        do {
            // Validate new token by re-authenticating
            try await appViewModel.authenticate(
                serverURL: settings.serverURL,
                token: trimmed
            )
            tokenUpdateSuccess = true
            newApiToken = ""
        } catch {
            tokenUpdateError = error.localizedDescription
        }
    }

    func resetSettings() {
        settings.resetToDefaults()
    }
}
