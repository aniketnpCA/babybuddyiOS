import SwiftUI

struct SleepFormSheet: View {
    let childID: Int
    let editing: SleepRecord?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isNap = true
    @State private var startTime: Date = Date().addingTimeInterval(-3600)
    @State private var endTime: Date = Date()
    @State private var isSaving = false
    @State private var error: String?

    init(childID: Int, editing: SleepRecord? = nil, onSave: @escaping () async -> Void) {
        self.childID = childID
        self.editing = editing
        self.onSave = onSave
    }

    private var isEditing: Bool { editing != nil }

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
            .navigationTitle(isEditing ? "Edit Sleep" : "Log Sleep")
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
        guard let sleep = editing else { return }
        isNap = sleep.nap
        if let s = DateFormatting.parseISO(sleep.start) { startTime = s }
        if let e = DateFormatting.parseISO(sleep.end) { endTime = e }
    }

    private func save() async {
        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            if let sleep = editing {
                let input = UpdateSleepInput(
                    start: DateFormatting.formatForAPI(startTime),
                    end: DateFormatting.formatForAPI(endTime),
                    nap: isNap,
                    notes: nil
                )
                let _: SleepRecord = try await APIClient.shared.patch(
                    path: APIEndpoints.sleepSession(sleep.id),
                    body: input
                )
            } else {
                let input = CreateSleepInput(
                    child: childID,
                    start: DateFormatting.formatForAPI(startTime),
                    end: DateFormatting.formatForAPI(endTime),
                    nap: isNap,
                    notes: nil
                )
                let _: SleepRecord = try await APIClient.shared.post(
                    path: APIEndpoints.sleep,
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
