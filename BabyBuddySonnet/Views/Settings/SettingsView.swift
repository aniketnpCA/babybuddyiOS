import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = SettingsViewModel()
    @State private var showResetConfirmation = false
    @State private var showSignOutConfirmation = false

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
