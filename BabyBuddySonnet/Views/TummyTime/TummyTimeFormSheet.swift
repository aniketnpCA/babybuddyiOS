import SwiftUI

struct TummyTimeFormSheet: View {
    let childID: Int
    let editing: TummyTime?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var milestone: String
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var error: String?

    init(childID: Int, editing: TummyTime? = nil, initialStartTime: Date? = nil, initialEndTime: Date? = nil, onSave: @escaping () async -> Void) {
        self.childID = childID
        self.editing = editing
        self.onSave = onSave

        if let tt = editing {
            _startTime = State(initialValue: DateFormatting.parseISO(tt.start) ?? Date.now.addingTimeInterval(-Double(SettingsService.shared.tummyTimeStartOffset)))
            _endTime = State(initialValue: DateFormatting.parseISO(tt.end) ?? Date.now)
            _milestone = State(initialValue: tt.milestone ?? "")
        } else {
            _startTime = State(initialValue: initialStartTime ?? Date.now.addingTimeInterval(-Double(SettingsService.shared.tummyTimeStartOffset)))
            _endTime = State(initialValue: initialEndTime ?? Date.now)
            _milestone = State(initialValue: "")
        }
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                FormSheetHeader(
                    icon: "figure.play",
                    color: .jayTummyTimeFallback,
                    title: isEditing ? "Edit Tummy Time" : "Log Tummy Time"
                )

                Section("Time") {
                    DateTimePickerRow(label: "Start", date: $startTime)
                    DateTimePickerRow(label: "End", date: $endTime)
                }

                Section("Milestone") {
                    TextField("What did they do? (optional)", text: $milestone, axis: .vertical)
                        .lineLimit(1...3)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Tummy Time" : "Log Tummy Time")
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
            .confirmationDialog("Delete Tummy Time", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await delete() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func delete() async {
        guard let tt = editing else { return }
        isDeleting = true
        error = nil
        defer { isDeleting = false }

        do {
            let _ = try await OfflineQueueService.shared.tryDelete(
                entityType: .tummyTime,
                path: APIEndpoints.tummyTime(tt.id)
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
        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            if let tt = editing {
                let input = UpdateTummyTimeInput(
                    start: DateFormatting.formatForAPI(startTime),
                    end: DateFormatting.formatForAPI(endTime),
                    milestone: milestone.isEmpty ? nil : milestone
                )
                let _ = try await OfflineQueueService.shared.tryPatch(
                    entityType: .tummyTime,
                    path: APIEndpoints.tummyTime(tt.id),
                    body: input
                )
            } else {
                let input = CreateTummyTimeInput(
                    child: childID,
                    start: DateFormatting.formatForAPI(startTime),
                    end: DateFormatting.formatForAPI(endTime),
                    milestone: milestone.isEmpty ? nil : milestone
                )
                let _ = try await OfflineQueueService.shared.tryPost(
                    entityType: .tummyTime,
                    path: APIEndpoints.tummyTimes,
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
