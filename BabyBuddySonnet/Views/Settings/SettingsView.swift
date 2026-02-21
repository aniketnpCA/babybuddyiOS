import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = SettingsViewModel()
    @State private var showResetConfirmation = false
    @State private var showSignOutConfirmation = false

    // MARK: - Helpers

    private func timeStringToDate(_ s: String) -> Date {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return Date() }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = parts[0]
        comps.minute = parts[1]
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func dateToTimeString(_ d: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    var body: some View {
        Form {
            Section("Daily Feeding Goal") {
                HStack {
                    Text("Target Amount")
                    Spacer()
                    Text("\(String(format: "%.0f", viewModel.settings.feedingTargetAmount)) oz")
                        .foregroundStyle(.secondary)
                }
                Stepper(
                    value: Binding(
                        get: { viewModel.settings.feedingTargetAmount },
                        set: { viewModel.settings.feedingTargetAmount = $0 }
                    ),
                    in: 1...60,
                    step: 1
                ) {
                    Text("Adjust")
                }

                HStack {
                    Text("Target Time")
                    Spacer()
                    Text(viewModel.settings.feedingTargetTime)
                        .foregroundStyle(.secondary)
                }

                DatePicker(
                    "Wake Time",
                    selection: Binding(
                        get: { timeStringToDate(viewModel.settings.feedingWakeTime) },
                        set: { viewModel.settings.feedingWakeTime = dateToTimeString($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )

                HStack {
                    Text("Average Days")
                    Spacer()
                    Text("\(viewModel.settings.feedingAverageDays)")
                        .foregroundStyle(.secondary)
                }
                Stepper(
                    value: Binding(
                        get: { viewModel.settings.feedingAverageDays },
                        set: { viewModel.settings.feedingAverageDays = $0 }
                    ),
                    in: 1...14,
                    step: 1
                ) {
                    Text("Adjust")
                }
            }

            Section("Sleep Target") {
                HStack {
                    Text("Daily Hours")
                    Spacer()
                    Text("\(String(format: "%.0f", viewModel.settings.sleepTargetHours))h")
                        .foregroundStyle(.secondary)
                }
                Stepper(
                    value: Binding(
                        get: { viewModel.settings.sleepTargetHours },
                        set: { viewModel.settings.sleepTargetHours = $0 }
                    ),
                    in: 1...24,
                    step: 0.5
                ) {
                    Text("Adjust")
                }
            }

            ReminderSettingsSection()

            IntervalSettingsSection()

            Section("Timezone") {
                Picker("Timezone", selection: Binding(
                    get: { viewModel.settings.timezone },
                    set: { viewModel.settings.timezone = $0 }
                )) {
                    ForEach(AppConstants.timezones, id: \.value) { tz in
                        Text(tz.label).tag(tz.value)
                    }
                }
            }

            Section("API Configuration") {
                HStack {
                    Text("Server")
                    Spacer()
                    Text(viewModel.settings.serverURL)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                SecureField("New API Token", text: $viewModel.newApiToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    Task {
                        await viewModel.updateAPIToken(viewModel.newApiToken, appViewModel: appViewModel)
                    }
                } label: {
                    HStack {
                        if viewModel.isUpdatingToken {
                            ProgressView()
                        }
                        Text("Update Token")
                    }
                }
                .disabled(viewModel.newApiToken.isEmpty || viewModel.isUpdatingToken)

                if let error = viewModel.tokenUpdateError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                if viewModel.tokenUpdateSuccess {
                    Text("Token updated successfully")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            AISettingsSection()

            TabOrderSection()

            AboutSection()

            Section("Danger Zone") {
                Button("Reset All Settings") {
                    showResetConfirmation = true
                }
                .foregroundStyle(.orange)

                Button("Sign Out") {
                    showSignOutConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
        .task {
            await NotificationService.shared.refreshPermissionStatus()
        }
        .navigationTitle("Settings")
        .confirmationDialog("Reset Settings?", isPresented: $showResetConfirmation) {
            Button("Reset to Defaults", role: .destructive) {
                viewModel.resetSettings()
            }
        } message: {
            Text("This will reset all settings to their default values.")
        }
        .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                appViewModel.signOut()
            }
        } message: {
            Text("You will need to re-enter your server URL and API token.")
        }
    }
}

// MARK: - Tab Order Section

struct TabOrderSection: View {
    private let settings = SettingsService.shared
    @State private var tabs: [AppTab] = []

    var body: some View {
        Section {
            ForEach(tabs) { tab in
                Label(tab.displayName, systemImage: tab.icon)
            }
            .onMove { from, to in
                tabs.move(fromOffsets: from, toOffset: to)
                settings.tabOrder = tabs.map(\.rawValue)
            }
        } header: {
            Text("Tab Order")
        } footer: {
            Text("Drag to reorder tabs. Changes take effect immediately.")
        }
        .onAppear {
            tabs = AppTab.resolveOrder(from: settings.tabOrder)
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Section("About") {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Baby Buddy")
                        .font(.headline)
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text("Published with love in San Francisco")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Link(destination: URL(string: "https://github.com/babybuddy/babybuddy")!) {
                Label("Baby Buddy on GitHub", systemImage: "link")
            }

            Link(destination: URL(string: "https://github.com/sponsors/babybuddy")!) {
                Label("Support Baby Buddy", systemImage: "heart")
            }

            Link(destination: URL(string: "https://github.com/sponsors/aniketpatil")!) {
                Label("Support the Developer", systemImage: "star")
            }
        }
    }
}

