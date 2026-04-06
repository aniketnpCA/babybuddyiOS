import SwiftUI

struct TemperatureFormSheet: View {
    let childID: Int
    let editing: Temperature?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var temperatureValue: String
    @State private var time: Date
    @State private var notes: String
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var error: String?

    init(childID: Int, editing: Temperature? = nil, onSave: @escaping () async -> Void) {
        self.childID = childID
        self.editing = editing
        self.onSave = onSave

        if let temp = editing {
            _temperatureValue = State(initialValue: String(format: "%.1f", temp.temperature))
            _time = State(initialValue: DateFormatting.parseISO(temp.time) ?? Date.now)
            _notes = State(initialValue: temp.notes ?? "")
        } else {
            _temperatureValue = State(initialValue: "98.6")
            _time = State(initialValue: Date.now)
            _notes = State(initialValue: "")
        }
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Temperature") {
                    HStack {
                        TextField("Temperature", text: $temperatureValue)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                        Text("\u{00B0}F")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Time") {
                    DateTimePickerRow(label: "Time", date: $time)
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
            .navigationTitle(isEditing ? "Edit Temperature" : "Log Temperature")
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
            .confirmationDialog("Delete Temperature", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await delete() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func delete() async {
        guard let temp = editing else { return }
        isDeleting = true
        error = nil
        defer { isDeleting = false }

        do {
            let _ = try await OfflineQueueService.shared.tryDelete(
                entityType: .temperature,
                path: APIEndpoints.temperature(temp.id)
            )
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
        guard let tempDouble = Double(temperatureValue) else {
            error = "Please enter a valid temperature"
            return
        }

        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            if let temp = editing {
                let input = UpdateTemperatureInput(
                    temperature: tempDouble,
                    time: DateFormatting.formatForAPI(time),
                    notes: notes.isEmpty ? nil : notes
                )
                let _ = try await OfflineQueueService.shared.tryPatch(
                    entityType: .temperature,
                    path: APIEndpoints.temperature(temp.id),
                    body: input
                )
            } else {
                let input = CreateTemperatureInput(
                    child: childID,
                    temperature: tempDouble,
                    time: DateFormatting.formatForAPI(time),
                    notes: notes.isEmpty ? nil : notes
                )
                let _ = try await OfflineQueueService.shared.tryPost(
                    entityType: .temperature,
                    path: APIEndpoints.temperatures,
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
