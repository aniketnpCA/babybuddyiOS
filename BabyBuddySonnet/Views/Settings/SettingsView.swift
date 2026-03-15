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

