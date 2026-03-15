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
                        Image(systemName: "bird.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.blue)
                        Text(theme.appName)
                            .font(.largeTitle.bold())
                        Text(theme.setupTagline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Baby Buddy explanation
                    VStack(spacing: 8) {
                        Text("Jaybird is a native iOS client for **Baby Buddy**, the open-source baby tracking platform. You'll need a running Baby Buddy server to use this app.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link(destination: URL(string: "https://baby-buddy.net")!) {
                                Label("Website", systemImage: "globe")
                                    .font(.caption)
                            }
                            Link(destination: URL(string: "https://github.com/babybuddy/babybuddy")!) {
                                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)

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

                    // Demo server
                    VStack(spacing: 8) {
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            viewModel.serverURL = "https://demo.baby-buddy.net"
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Use Demo Server")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Text("Pre-fills demo.baby-buddy.net — log in with admin/admin to find your API token under User Settings")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
