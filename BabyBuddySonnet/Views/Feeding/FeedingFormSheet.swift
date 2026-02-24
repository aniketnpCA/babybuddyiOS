import SwiftUI

struct FeedingFormSheet: View {
    let childID: Int
    let editing: Feeding?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var feedingType: FeedingType = .breastMilk
    @State private var feedingMethod: FeedingMethod = .bottle
    @State private var amount: Double = 3.0
    @State private var startTime: Date = Date().addingTimeInterval(-900)
    @State private var endTime: Date = Date()
    @State private var isSaving = false
    @State private var error: String?

    init(childID: Int, editing: Feeding? = nil, onSave: @escaping () async -> Void) {
        self.childID = childID
        self.editing = editing
        self.onSave = onSave
    }

    private var isEditing: Bool { editing != nil }
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Feeding Type", selection: $feedingType) {
                        ForEach(FeedingType.allCases, id: \.self) { type in
                            Text(theme.feedingTypeNames[type.rawValue] ?? type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Method") {
                    Picker("Method", selection: $feedingMethod) {
                        ForEach(FeedingMethod.allCases, id: \.self) { method in
                            Text(theme.feedingMethodNames[method.rawValue] ?? method.displayName).tag(method)
                        }
                    }
                }

                if feedingMethod == .bottle {
                    Section("Amount") {
                        AmountStepperView(amount: $amount)
                            .frame(maxWidth: .infinity)
                    }
                }

                Section("Time") {
                    DateTimePickerRow(label: "Start", date: $startTime)
                    DateTimePickerRow(label: "End", date: $endTime)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? theme.editFeedingTitle : theme.logFeedingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear { prefillIfEditing() }
        }
    }

    private func prefillIfEditing() {
        guard let feeding = editing else { return }
        if let ft = feeding.feedingType { feedingType = ft }
        if let fm = feeding.feedingMethod { feedingMethod = fm }
        amount = feeding.amount ?? 3.0
        if let s = DateFormatting.parseISO(feeding.start) { startTime = s }
        if let e = DateFormatting.parseISO(feeding.end) { endTime = e }
    }

    private func save() async {
        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            if let feeding = editing {
                let input = UpdateFeedingInput(
                    start: DateFormatting.formatForAPI(startTime),
                    end: DateFormatting.formatForAPI(endTime),
                    type: feedingType.rawValue,
                    method: feedingMethod.rawValue,
                    amount: feedingMethod == .bottle ? amount : nil,
                    notes: nil
                )
                let _: Feeding = try await APIClient.shared.patch(
                    path: APIEndpoints.feeding(feeding.id),
                    body: input
                )
            } else {
                let input = CreateFeedingInput(
                    child: childID,
                    start: DateFormatting.formatForAPI(startTime),
                    end: DateFormatting.formatForAPI(endTime),
                    type: feedingType.rawValue,
                    method: feedingMethod.rawValue,
                    amount: feedingMethod == .bottle ? amount : nil,
                    notes: nil
                )
                let _: Feeding = try await APIClient.shared.post(
                    path: APIEndpoints.feedings,
                    body: input
                )
            }
            await onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
