import SwiftUI

struct PumpingFormSheet: View {
    let childID: Int
    let editing: Pumping?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Double = 3.0
    @State private var category: MilkCategory = .toBeConsumed
    @State private var startTime: Date = Date().addingTimeInterval(-1800)
    @State private var endTime: Date = Date()
    @State private var isSaving = false
    @State private var error: String?

    init(childID: Int, editing: Pumping? = nil, onSave: @escaping () async -> Void) {
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
        guard let pumping = editing else { return }
        amount = pumping.amount
        category = pumping.milkCategory
        if let s = DateFormatting.parseISO(pumping.start) { startTime = s }
        if let e = DateFormatting.parseISO(pumping.end) { endTime = e }
    }

    private func save() async {
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
