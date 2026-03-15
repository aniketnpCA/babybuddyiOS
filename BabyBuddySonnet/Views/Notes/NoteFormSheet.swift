import SwiftUI

struct NoteFormSheet: View {
    let childID: Int
    let editing: Note?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var noteText: String
    @State private var time: Date
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var error: String?

    init(childID: Int, editing: Note? = nil, onSave: @escaping () async -> Void) {
        self.childID = childID
        self.editing = editing
        self.onSave = onSave

        if let note = editing {
            _noteText = State(initialValue: note.note)
            _time = State(initialValue: DateFormatting.parseISO(note.time) ?? Date.now)
        } else {
            _noteText = State(initialValue: "")
            _time = State(initialValue: Date.now)
        }
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                }

                Section("Time") {
                    DateTimePickerRow(label: "Time", date: $time)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Note" : "Add Note")
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
                    .disabled(isSaving || isDeleting || noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog("Delete Note", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await delete() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func delete() async {
        guard let note = editing else { return }
        isDeleting = true
        error = nil
        defer { isDeleting = false }

        do {
            try await APIClient.shared.delete(path: APIEndpoints.note(note.id))
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
            if let note = editing {
                let input = UpdateNoteInput(
                    note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
                    time: DateFormatting.formatForAPI(time)
                )
                let _: Note = try await APIClient.shared.patch(
                    path: APIEndpoints.note(note.id),
                    body: input
                )
            } else {
                let input = CreateNoteInput(
                    child: childID,
                    note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
                    time: DateFormatting.formatForAPI(time)
                )
                let _: Note = try await APIClient.shared.post(
                    path: APIEndpoints.notes,
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
