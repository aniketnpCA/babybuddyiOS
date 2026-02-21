import SwiftUI

struct ReminderSettingsSection: View {
    @Environment(AppViewModel.self) private var appViewModel
    private let settings = SettingsService.shared

    var body: some View {
        Section {
            if NotificationService.shared.permissionStatus == .denied {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Notifications are disabled in system Settings.")
                        .font(.caption)
                    Spacer()
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
            }

            ForEach(ReminderCategory.allCases, id: \.self) { category in
                ReminderCategoryRow(category: category, childID: appViewModel.child?.id)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Get notified if the most recent entry for a category is older than the threshold.")
        }
    }
}

struct ReminderCategoryRow: View {
    let category: ReminderCategory
    let childID: Int?
    private let settings = SettingsService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { settings.isReminderEnabled(for: category) },
                set: { newValue in
                    settings.setReminderEnabled(newValue, for: category)
                    rescheduleIfNeeded()
                }
            )) {
                Label(category.displayName, systemImage: category.icon)
            }

            if settings.isReminderEnabled(for: category) {
                HStack {
                    Text("Alert after")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(formattedThreshold) hours")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Stepper(
                    value: Binding(
                        get: { settings.reminderThresholdHours(for: category) },
                        set: { newValue in
                            settings.setReminderThresholdHours(newValue, for: category)
                            rescheduleIfNeeded()
                        }
                    ),
                    in: 0.5...12.0,
                    step: 0.5
                ) {
                    Text("Adjust")
                }
            }
        }
    }

    private var formattedThreshold: String {
        let h = settings.reminderThresholdHours(for: category)
        if h == Double(Int(h)) {
            return "\(Int(h))"
        }
        return String(format: "%.1f", h)
    }

    private func rescheduleIfNeeded() {
        guard let childID else { return }
        Task {
            await NotificationService.shared.rescheduleAll(childID: childID)
        }
    }
}

struct IntervalSettingsSection: View {
    private let settings = SettingsService.shared
    private let categories: [ReminderCategory] = [.feeding, .pumping, .diaper]

    var body: some View {
        Section {
            ForEach(categories, id: \.self) { category in
                IntervalCategoryRow(category: category)
            }
        } header: {
            Text("Expected Intervals")
        } footer: {
            Text("Set how often you expect each activity. The dashboard will show when the next one is due.")
        }
    }
}

struct IntervalCategoryRow: View {
    let category: ReminderCategory
    private let settings = SettingsService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { settings.isIntervalEnabled(for: category) },
                set: { settings.setIntervalEnabled($0, for: category) }
            )) {
                Label(category.displayName, systemImage: category.icon)
            }

            if settings.isIntervalEnabled(for: category) {
                HStack {
                    Text("Every")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(formattedInterval) hours")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Stepper(
                    value: Binding(
                        get: { settings.intervalHours(for: category) },
                        set: { settings.setIntervalHours($0, for: category) }
                    ),
                    in: 0.5...12.0,
                    step: 0.5
                ) {
                    Text("Adjust")
                }
            }
        }
    }

    private var formattedInterval: String {
        let h = settings.intervalHours(for: category)
        if h == Double(Int(h)) {
            return "\(Int(h))"
        }
        return String(format: "%.1f", h)
    }
}

struct AISettingsSection: View {
    private let settings = SettingsService.shared
    @State private var apiKeyInput: String = ""
    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var modelError: String?

    var body: some View {
        Section {
            SecureField("API Key", text: Binding(
                get: {
                    let key = settings.aiApiKey
                    return key.isEmpty ? apiKeyInput : key
                },
                set: { newValue in
                    apiKeyInput = newValue
                    settings.aiApiKey = newValue
                    Task {
                        await AIService.shared.configure(
                            apiKey: newValue,
                            baseURL: settings.aiBaseURL,
                            model: settings.aiModel
                        )
                    }
                }
            ))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            HStack {
                Text("Base URL")
                Spacer()
                TextField("https://api.openai.com", text: Binding(
                    get: { settings.aiBaseURL },
                    set: { settings.aiBaseURL = $0 }
                ))
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.secondary)
            }

            // Model selector
            if !availableModels.isEmpty {
                Picker("Model", selection: Binding(
                    get: { settings.aiModel },
                    set: { settings.aiModel = $0 }
                )) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            }

            HStack {
                Button {
                    Task { await fetchModels() }
                } label: {
                    HStack(spacing: 6) {
                        if isLoadingModels {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(availableModels.isEmpty ? "Fetch Models" : "Refresh Models")
                    }
                }
                .disabled(settings.aiApiKey.isEmpty || isLoadingModels)

                Spacer()

                if let error = modelError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }

            HStack {
                Text("Or type manually")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("gpt-4o-mini", text: Binding(
                    get: { settings.aiModel },
                    set: { settings.aiModel = $0 }
                ))
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("AI Configuration")
        } footer: {
            Text("Enter an OpenAI-compatible API key for AI-powered analytics. Works with OpenAI, Gemini (OpenAI mode), and other compatible providers.")
        }
    }

    private func fetchModels() async {
        isLoadingModels = true
        modelError = nil
        defer { isLoadingModels = false }

        await AIService.shared.configure(
            apiKey: settings.aiApiKey,
            baseURL: settings.aiBaseURL,
            model: settings.aiModel
        )

        do {
            let models = try await AIService.shared.fetchModels()
            availableModels = models
            // If current model isn't in the list, keep it (manual entry)
            // If list is non-empty and current model is default/empty, select first
            if settings.aiModel.isEmpty, let first = models.first {
                settings.aiModel = first
            }
        } catch {
            modelError = "Failed to fetch"
        }
    }
}
