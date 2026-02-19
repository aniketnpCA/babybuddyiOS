import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        Group {
            if appViewModel.isLoading {
                LoadingView(message: "Connecting to Baby Buddy...")
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

struct MainTabView: View {
    let child: Child

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                DashboardView(child: child)
            }

            Tab("Feeding", systemImage: "drop.fill") {
                FeedingView(childID: child.id)
            }

            Tab("Sleep", systemImage: "moon.fill") {
                SleepView(childID: child.id)
            }

            Tab("Diaper", systemImage: "circle.dotted") {
                DiaperView(childID: child.id)
            }

            Tab("Pumping", systemImage: "drop.triangle.fill") {
                PumpingView(childID: child.id)
            }
        }
    }
}
