import SwiftUI

struct SleepFormSheet: View {
    let childID: Int
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isNap = true
    @State private var startTime: Date = Date().addingTimeInterval(-3600)
    @State private var endTime: Date = Date()
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Sleep Type", selection: $isNap) {
                        Text("Nap").tag(true)
                        Text("Night Sleep").tag(false)
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
            .navigationTitle("Log Sleep")
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

        let input = CreateSleepInput(
            child: childID,
            start: DateFormatting.formatForAPI(startTime),
            end: DateFormatting.formatForAPI(endTime),
            nap: isNap,
            notes: nil
        )

        do {
            let _: SleepRecord = try await APIClient.shared.post(
                path: APIEndpoints.sleep,
                body: input
            )
            await onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
