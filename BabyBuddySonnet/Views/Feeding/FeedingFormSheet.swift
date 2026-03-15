import SwiftUI

struct FeedingFormSheet: View {
    let childID: Int
    let editing: Feeding?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var feedingType: FeedingType
    @State private var feedingMethod: FeedingMethod
    @State private var amount: Double
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var error: String?

    init(childID: Int, editing: Feeding? = nil, onSave: @escaping () async -> Void) {
        self.childID = childID
        self.editing = editing
        self.onSave = onSave

        if let feeding = editing {
            _feedingType = State(initialValue: feeding.feedingType ?? .breastMilk)
            _feedingMethod = State(initialValue: feeding.feedingMethod ?? .bottle)
            _amount = State(initialValue: feeding.amount ?? 3.0)
            _startTime = State(initialValue: DateFormatting.parseISO(feeding.start) ?? Date.now.addingTimeInterval(-900))
            _endTime = State(initialValue: DateFormatting.parseISO(feeding.end) ?? Date.now)
            _notes = State(initialValue: feeding.notes ?? "")
        } else {
            _feedingType = State(initialValue: .breastMilk)
            _feedingMethod = State(initialValue: .bottle)
            _amount = State(initialValue: 3.0)
            _startTime = State(initialValue: Date.now.addingTimeInterval(-900))
            _endTime = State(initialValue: Date.now)
            _notes = State(initialValue: "")
        }
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

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
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
                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete") { showDeleteConfirmation = true }
                            .foregroundStyle(.red)
                            .disabled(isDeleting || isSaving)
                    }
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
                    .disabled(isSaving || isDeleting)
                }
            }
            .confirmationDialog("Delete Feeding", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await delete() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func delete() async {
        guard let feeding = editing else { return }
        isDeleting = true
        error = nil
        defer { isDeleting = false }

        do {
            try await APIClient.shared.delete(path: APIEndpoints.feeding(feeding.id))
            await onSave()
            dismiss()
        } catch {
            if (error as? URLError)?.code != .cancelled {
                self.error = error.localizedDescription
            }
        }
    }

    private func save() async {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                    notes: notes.isEmpty ? nil : notes
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
                    notes: notes.isEmpty ? nil : notes
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
