import SwiftUI

struct DiaperFormSheet: View {
    let childID: Int
    let editing: DiaperChange?
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    @State private var isWet = true
    @State private var isSolid = false
    @State private var selectedColor: StoolColor = .yellow
    @State private var time: Date = Date()
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var error: String?
    @State private var amount: String = ""

    init(childID: Int, editing: DiaperChange? = nil, onSave: @escaping () async -> Void) {
        self.childID = childID
        self.editing = editing
        self.onSave = onSave
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                FormSheetHeader(
                    icon: isWet && isSolid ? "drop.circle.fill" : isWet ? "drop.fill" : isSolid ? "circle.fill" : "circle.dotted",
                    color: JayColors.diaperColor(wet: isWet, solid: isSolid),
                    title: isEditing ? theme.editDiaperTitle : theme.logDiaperTitle
                )

                Section("Type") {
                    Toggle(theme.diaperWetLabel, isOn: $isWet)
                    Toggle(theme.diaperSolidLabel, isOn: $isSolid)
                }

                if isSolid {
                    Section(theme.diaperColorSectionTitle) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(AppConstants.diaperColors, id: \.color) { item in
                                Button {
                                    selectedColor = item.color
                                } label: {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(item.swiftUIColor)
                                            .frame(width: 36, height: 36)
                                            .overlay {
                                                if selectedColor == item.color {
                                                    Circle()
                                                        .strokeBorder(.primary, lineWidth: 3)
                                                }
                                            }
                                        Text(item.color.displayName)
                                            .font(.caption2)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Time") {
                    DateTimePickerRow(label: "Time", date: $time)
                }

                Section("Amount (optional)") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? theme.editDiaperTitle : theme.logDiaperTitle)
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
                    .disabled(isSaving || isDeleting || (!isWet && !isSolid))
                }
            }
            .confirmationDialog("Delete Diaper Change", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await delete() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .onAppear { prefillIfEditing() }
        }
    }

    private func prefillIfEditing() {
        guard let change = editing else { return }
        isWet = change.wet
        isSolid = change.solid
        if let sc = change.stoolColor { selectedColor = sc }
        if let t = DateFormatting.parseISO(change.time) { time = t }
        if let a = change.amount { amount = String(format: "%.1f", a) }
    }

    private func delete() async {
        guard let change = editing else { return }
        isDeleting = true
        error = nil
        defer { isDeleting = false }

        do {
            let _ = try await OfflineQueueService.shared.tryDelete(
                entityType: .diaper,
                path: APIEndpoints.change(change.id)
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
            if let change = editing {
                let input = UpdateDiaperChangeInput(
                    time: DateFormatting.formatForAPI(time),
                    wet: isWet,
                    solid: isSolid,
                    color: isSolid ? selectedColor.rawValue : "",
                    amount: Double(amount),
                    notes: nil
                )
                let _ = try await OfflineQueueService.shared.tryPatch(
                    entityType: .diaper,
                    path: APIEndpoints.change(change.id),
                    body: input
                )
            } else {
                let input = CreateDiaperChangeInput(
                    child: childID,
                    time: DateFormatting.formatForAPI(time),
                    wet: isWet,
                    solid: isSolid,
                    color: isSolid ? selectedColor.rawValue : "",
                    amount: Double(amount),
                    notes: nil
                )
                let _ = try await OfflineQueueService.shared.tryPost(
                    entityType: .diaper,
                    path: APIEndpoints.changes,
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
