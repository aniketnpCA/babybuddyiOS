import SwiftUI

// MARK: - AppTab

nonisolated enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard
    case feeding
    case sleep
    case diaper
    case pumping
    case analytics

    nonisolated var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dashboard: "Dashboard"
        case .feeding: "Feeding"
        case .sleep: "Sleep"
        case .diaper: "Diaper"
        case .pumping: "Pumping"
        case .analytics: "Analytics"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "house.fill"
        case .feeding: "drop.fill"
        case .sleep: "moon.fill"
        case .diaper: "circle.dotted"
        case .pumping: "drop.triangle.fill"
        case .analytics: "chart.line.uptrend.xyaxis"
        }
    }

    static let defaultOrder: [AppTab] = [.dashboard, .feeding, .sleep, .diaper, .pumping, .analytics]

    /// Resolve a persisted array of raw values back to AppTab, falling back to defaults.
    static func resolveOrder(from rawValues: [String]) -> [AppTab] {
        let resolved = rawValues.compactMap { AppTab(rawValue: $0) }
        // Ensure all tabs are present (in case new tabs were added or data is corrupt)
        let missing = AppTab.allCases.filter { !resolved.contains($0) }
        let order = resolved + missing
        return order
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        Group {
            if appViewModel.isLoading {
                LoadingView(message: "Connecting to \(SettingsService.shared.theme.appName)...")
            } else if appViewModel.isAuthenticated, let child = appViewModel.child {
                MainTabView(child: child)
            } else {
                SetupView()
            }
        }
        .task {
            await appViewModel.checkAuth()
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    let child: Child
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    private var orderedTabs: [AppTab] {
        AppTab.resolveOrder(from: settings.tabOrder)
    }

    var body: some View {
        TabView {
            ForEach(orderedTabs) { tab in
                Tab(theme.tabDisplayName(for: tab), systemImage: theme.tabIcon(for: tab)) {
                    viewForTab(tab)
                }
            }
        }
    }

    @ViewBuilder
    private func viewForTab(_ tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(child: child)
        case .feeding:
            FeedingView(childID: child.id)
        case .sleep:
            SleepView(childID: child.id)
        case .diaper:
            DiaperView(childID: child.id)
        case .pumping:
            PumpingView(childID: child.id)
        case .analytics:
            AnalyticsView(child: child)
        }
    }
}
