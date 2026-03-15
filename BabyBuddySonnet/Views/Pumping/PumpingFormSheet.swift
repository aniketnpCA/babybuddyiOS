import SwiftUI

struct PumpingFormSheet: View {
    let childID: Int
    let editing: Pumping?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Double
    @State private var category: MilkCategory
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var error: String?

    init(childID: Int, editing: Pumping? = nil, onSave: @escaping () async -> Void) {
        self.childID = childID
        self.editing = editing
        self.onSave = onSave

        if let pumping = editing {
            _amount = State(initialValue: pumping.amount ?? 0.0)
            _category = State(initialValue: pumping.milkCategory)
            _startTime = State(initialValue: DateFormatting.parseISO(pumping.start) ?? Date.now.addingTimeInterval(-1800))
            _endTime = State(initialValue: DateFormatting.parseISO(pumping.end) ?? Date.now)
        } else {
            _amount = State(initialValue: 0.0)
            _category = State(initialValue: .toBeConsumed)
            _startTime = State(initialValue: Date.now.addingTimeInterval(-1800))
            _endTime = State(initialValue: Date.now)
        }
    }

    private var isEditing: Bool { editing != nil }
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    AmountStepperView(amount: $amount)
                        .frame(maxWidth: .infinity)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(MilkCategory.allCases, id: \.self) { cat in
                            Text(theme.milkCategoryNames[cat.rawValue] ?? cat.displayName).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
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
            .navigationTitle(isEditing ? theme.editPumpingTitle : theme.logPumpingTitle)
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
            .confirmationDialog("Delete Pumping Session", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await delete() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func delete() async {
        guard let pumping = editing else { return }
        isDeleting = true
        error = nil
        defer { isDeleting = false }

        do {
            try await APIClient.shared.delete(path: APIEndpoints.pumpingSession(pumping.id))
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
            if let pumping = editing {
                let input = UpdatePumpingInput(
                    start: DateFormatting.formatForAPI(startTime),
                    end: DateFormatting.formatForAPI(endTime),
                    amount: amount,
                    notes: MilkCategory.createNotes(for: category)
                )
                let _: Pumping = try await APIClient.shared.patch(
                    path: APIEndpoints.pumpingSession(pumping.id),
                    body: input
                )
            } else {
                let input = CreatePumpingInput(
                    child: childID,
                    start: DateFormatting.formatForAPI(startTime),
                    end: DateFormatting.formatForAPI(endTime),
                    amount: amount,
                    notes: MilkCategory.createNotes(for: category)
                )
                let _: Pumping = try await APIClient.shared.post(
                    path: APIEndpoints.pumping,
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
