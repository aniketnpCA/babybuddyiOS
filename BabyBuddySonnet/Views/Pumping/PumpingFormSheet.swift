import SwiftUI

struct PumpingFormSheet: View {
    let childID: Int
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Double = 3.0
    @State private var category: MilkCategory = .toBeConsumed
    @State private var startTime: Date = Date().addingTimeInterval(-1800)
    @State private var endTime: Date = Date()
    @State private var isSaving = false
    @State private var error: String?

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
                            Text(cat.displayName).tag(cat)
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
            .navigationTitle("Log Pumping")
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
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        defer { isSaving = false }

        let input = CreatePumpingInput(
            child: childID,
            start: DateFormatting.formatForAPI(startTime),
            end: DateFormatting.formatForAPI(endTime),
            amount: amount,
            notes: MilkCategory.createNotes(for: category)
        )

        do {
            let _: Pumping = try await APIClient.shared.post(
                path: APIEndpoints.pumping,
                body: input
            )
            await onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
