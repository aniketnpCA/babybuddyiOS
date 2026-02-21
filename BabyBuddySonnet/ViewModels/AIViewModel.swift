import Foundation

@Observable
@MainActor
final class AIViewModel {
    var messages: [AIMessage] = []
    var isLoading = false
    var error: String?

    private let settings = SettingsService.shared

    var isConfigured: Bool {
        !settings.aiApiKey.isEmpty
    }

    func ask(question: String, context: String) async {
        guard isConfigured else {
            error = "Please configure your AI API key in Settings."
            return
        }

        // Add user message
        messages.append(AIMessage(role: .user, content: question))
        isLoading = true
        error = nil

        // Ensure AI service is configured with latest settings
        await AIService.shared.configure(
            apiKey: settings.aiApiKey,
            baseURL: settings.aiBaseURL,
            model: settings.aiModel
        )

        do {
            let response = try await AIService.shared.ask(
                question: question,
                context: context
            )
            messages.append(AIMessage(role: .assistant, content: response))
        } catch {
            self.error = error.localizedDescription
            // Add error as assistant message for display
            messages.append(AIMessage(role: .assistant, content: "Sorry, I encountered an error: \(error.localizedDescription)"))
        }

        isLoading = false
    }

    func clearConversation() {
        messages.removeAll()
        error = nil
    }
}
