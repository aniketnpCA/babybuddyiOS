import SwiftUI

@main
struct BabyBuddySonnetApp: App {
    @State private var appViewModel = AppViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await rescheduleNotificationsIfNeeded()
                        }
                    }
                }
        }
    }

    private func rescheduleNotificationsIfNeeded() async {
        guard appViewModel.isAuthenticated,
              let child = appViewModel.child
        else { return }

        // Configure AI service with current settings
        let settings = SettingsService.shared
        await AIService.shared.configure(
            apiKey: settings.aiApiKey,
            baseURL: settings.aiBaseURL,
            model: settings.aiModel
        )

        await NotificationService.shared.refreshPermissionStatus()
        await NotificationService.shared.rescheduleAll(childID: child.id)
    }
}
