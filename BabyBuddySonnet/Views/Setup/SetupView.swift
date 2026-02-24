import SwiftUI

struct SetupView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = SetupViewModel()
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: theme.aboutAppIcon)
                            .font(.system(size: 64))
                            .foregroundStyle(theme.aboutIconColor == "brown" ? Color.brown : Color.pink)
                        Text(theme.appName)
                            .font(.largeTitle.bold())
                        Text(theme.setupTagline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server URL")
                                .font(.headline)
                            TextField("https://your-server.com", text: $viewModel.serverURL)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Token")
                                .font(.headline)
                            SecureField("Your API token", text: $viewModel.apiToken)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            Text(theme.setupHint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    if let error = viewModel.errorMessage {
                        ErrorBannerView(message: error) {
                            viewModel.errorMessage = nil
                        }
                    }

                    Button {
                        Task {
                            await viewModel.validate(appViewModel: appViewModel)
                        }
                    } label: {
                        HStack {
                            if viewModel.isValidating {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isValidating ? "Connecting..." : "Connect")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isValidating)
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
