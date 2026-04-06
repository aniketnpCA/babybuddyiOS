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

    private func formatOffset(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) sec" }
        let minutes = seconds / 60
        if seconds % 60 == 0 { return "\(minutes) min" }
        return "\(minutes)m \(seconds % 60)s"
    }

    var body: some View {
        Form {
            // MARK: - Time & Display
            Section {
                Picker("Home Timezone", selection: Binding(
                    get: { viewModel.settings.timezone },
                    set: { viewModel.settings.timezone = $0 }
                )) {
                    ForEach(AppConstants.timezones, id: \.value) { tz in
                        Text(tz.label).tag(tz.value)
                    }
                }

                Toggle(isOn: Binding(
                    get: { viewModel.settings.useLocalTimezone },
                    set: { viewModel.settings.useLocalTimezone = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Local Time")
                        Text("Display times in your current device timezone instead of the home timezone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Time & Display")
            } footer: {
                if viewModel.settings.useLocalTimezone && TimeZone.current.identifier != viewModel.settings.timezone {
                    Text("Times will display in \(TimeZone.current.localizedName(for: .shortGeneric, locale: .current) ?? TimeZone.current.abbreviation() ?? "local time"). Home timezone: \(TimeZone(identifier: viewModel.settings.timezone)?.localizedName(for: .shortGeneric, locale: .current) ?? viewModel.settings.timezone).")
                }
            }

            // MARK: - Default Start Times
            Section {
                OffsetRow(
                    label: "Feeding",
                    icon: "drop.fill",
                    color: .blue,
                    seconds: Binding(
                        get: { viewModel.settings.feedingStartOffset },
                        set: { viewModel.settings.feedingStartOffset = $0 }
                    )
                )
                OffsetRow(
                    label: "Pumping",
                    icon: "drop.triangle.fill",
                    color: .orange,
                    seconds: Binding(
                        get: { viewModel.settings.pumpingStartOffset },
                        set: { viewModel.settings.pumpingStartOffset = $0 }
                    )
                )
                OffsetRow(
                    label: "Sleep",
                    icon: "moon.fill",
                    color: .purple,
                    seconds: Binding(
                        get: { viewModel.settings.sleepStartOffset },
                        set: { viewModel.settings.sleepStartOffset = $0 }
                    )
                )
                OffsetRow(
                    label: "Tummy Time",
                    icon: "figure.play",
                    color: .green,
                    seconds: Binding(
                        get: { viewModel.settings.tummyTimeStartOffset },
                        set: { viewModel.settings.tummyTimeStartOffset = $0 }
                    )
                )
                OffsetRow(
                    label: "Timer Fallback",
                    icon: "timer",
                    color: .secondary,
                    seconds: Binding(
                        get: { viewModel.settings.timerFallbackOffset },
                        set: { viewModel.settings.timerFallbackOffset = $0 }
                    )
                )
            } header: {
                Text("Default Start Times")
            } footer: {
                Text("When logging a new activity, the start time defaults to this many minutes before the current time.")
            }

            // MARK: - Daily Goals
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

            // MARK: - Notifications
            ReminderSettingsSection()

            IntervalSettingsSection()

            // MARK: - Appearance
            Section("Appearance") {
                Toggle(isOn: Binding(
                    get: { viewModel.settings.isDogMode },
                    set: { viewModel.settings.isDogMode = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dog Mode")
                        Text("Woof! Track your pup's routine")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            AppIconSection()

            Section {
                Picker("Child's Sex", selection: Binding(
                    get: { viewModel.settings.childSex },
                    set: { viewModel.settings.childSex = $0 }
                )) {
                    Text("Not Set").tag("")
                    Text("Boy").tag("M")
                    Text("Girl").tag("F")
                }
            } header: {
                Text("Growth Charts")
            } footer: {
                Text("Used to select WHO growth percentiles (boys vs girls).")
            }

            // MARK: - Offline Queue
            OfflineQueueSection()

            // MARK: - API & Server
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

            // MARK: - Customization
            TabOrderSection()

            // MARK: - About
            AboutSection()

            // MARK: - Danger Zone
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

// MARK: - Offset Row (for Default Start Times)

struct OffsetRow: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var seconds: Int

    private var minutes: Int { seconds / 60 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(label, systemImage: icon)
                    .foregroundStyle(color)
                Spacer()
                Text("\(minutes) min before now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Stepper(
                value: Binding(
                    get: { minutes },
                    set: { seconds = $0 * 60 }
                ),
                in: 0...120,
                step: 1
            ) {
                Text("Adjust")
            }
        }
    }
}

// MARK: - Offline Queue Section

struct OfflineQueueSection: View {
    private let offlineQueue = OfflineQueueService.shared

    var body: some View {
        Section {
            HStack {
                Label("Connection", systemImage: offlineQueue.isOnline ? "wifi" : "wifi.slash")
                    .foregroundStyle(offlineQueue.isOnline ? .green : .red)
                Spacer()
                Text(offlineQueue.isOnline ? "Online" : "Offline")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if offlineQueue.hasPendingOperations {
                HStack {
                    Label("Pending", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Text("\(offlineQueue.pendingCount) item\(offlineQueue.pendingCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if offlineQueue.failedCount > 0 {
                    HStack {
                        Label("Failed", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text("\(offlineQueue.failedCount) item\(offlineQueue.failedCount == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }

                    Button("Retry Failed") {
                        Task {
                            await offlineQueue.retryFailed()
                        }
                    }
                }

                ForEach(offlineQueue.queue) { op in
                    HStack {
                        Image(systemName: statusIcon(for: op.status))
                            .foregroundStyle(statusColor(for: op.status))
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(op.operationType.rawValue.capitalized) \(op.entityType.rawValue)")
                                .font(.caption)
                            if let error = op.lastError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if op.status == .failed {
                            Button {
                                offlineQueue.removeOperation(id: op.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        } header: {
            Text("Sync Status")
        } footer: {
            if !offlineQueue.hasPendingOperations {
                Text("All changes are synced with the server.")
            } else {
                Text("Pending changes will sync automatically when connected.")
            }
        }
    }

    private func statusIcon(for status: QueuedOperationStatus) -> String {
        switch status {
        case .pending: return "clock"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .failed: return "exclamationmark.circle.fill"
        }
    }

    private func statusColor(for status: QueuedOperationStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .syncing: return .blue
        case .failed: return .red
        }
    }
}

// MARK: - Tab Order Section

struct TabOrderSection: View {
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }
    @State private var tabs: [AppTab] = []

    var body: some View {
        Section {
            ForEach(tabs) { tab in
                Label(theme.tabDisplayName(for: tab), systemImage: theme.tabIcon(for: tab))
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

// MARK: - App Icon Section

nonisolated enum AppIconChoice: String, CaseIterable, Sendable {
    case `default` = "AppIcon"
    case icon1 = "Icon1"

    var displayName: String {
        switch self {
        case .default: return "Soft Baby Curls"
        case .icon1: return "Delicate Hair Wisps"
        }
    }

    /// The value to pass to `setAlternateIconName`. `nil` resets to primary.
    var alternateIconName: String? {
        self == .default ? nil : rawValue
    }
}

struct AppIconSection: View {
    @State private var selected: AppIconChoice = .default

    var body: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 12)], spacing: 12) {
                ForEach(AppIconChoice.allCases, id: \.self) { icon in
                    Button {
                        selected = icon
                        UIApplication.shared.setAlternateIconName(icon.alternateIconName)
                    } label: {
                        VStack(spacing: 4) {
                            Image(uiImage: iconImage(for: icon))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selected == icon ? Color.accentColor : Color.clear, lineWidth: 3)
                                )
                            Text(icon.displayName)
                                .font(.caption2)
                                .foregroundStyle(selected == icon ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("App Icon")
        }
        .onAppear {
            if let current = UIApplication.shared.alternateIconName,
               let choice = AppIconChoice(rawValue: current) {
                selected = choice
            } else {
                selected = .default
            }
        }
    }

    private func iconImage(for icon: AppIconChoice) -> UIImage {
        // Try loading from the asset catalog by icon set name
        if let img = UIImage(named: icon.rawValue) {
            return img
        }
        // Fallback: try loading the app's current icon
        if icon == .default,
           let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last,
           let img = UIImage(named: name) {
            return img
        }
        return UIImage(systemName: "app.fill") ?? UIImage()
    }
}

// MARK: - About Section

struct AboutSection: View {
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Section("About") {
            HStack(spacing: 12) {
                Image(systemName: theme.aboutAppIcon)
                    .font(.title2)
                    .foregroundStyle(theme.aboutIconColor == "brown" ? Color.brown : theme.aboutIconColor == "blue" ? Color.blue : Color.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.aboutAppName)
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
                Label("\(theme.aboutAppName) on GitHub", systemImage: "link")
            }

            Link(destination: URL(string: "https://github.com/sponsors/babybuddy")!) {
                Label("Support \(theme.aboutAppName)", systemImage: "heart")
            }

            Link(destination: URL(string: "https://github.com/sponsors/aniketpatil")!) {
                Label("Support the Developer", systemImage: "star")
            }
        }
    }
}
