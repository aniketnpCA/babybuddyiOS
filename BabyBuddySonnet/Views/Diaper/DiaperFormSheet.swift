import SwiftUI

struct DiaperFormSheet: View {
    let childID: Int
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isWet = true
    @State private var isSolid = false
    @State private var selectedColor: StoolColor = .brown
    @State private var time: Date = Date()
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Toggle("Wet", isOn: $isWet)
                    Toggle("Solid", isOn: $isSolid)
                }

                if isSolid {
                    Section("Stool Color") {
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

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Log Diaper")
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
                    .disabled(isSaving || (!isWet && !isSolid))
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        defer { isSaving = false }

        let input = CreateDiaperChangeInput(
            child: childID,
            time: DateFormatting.formatForAPI(time),
            wet: isWet,
            solid: isSolid,
            color: isSolid ? selectedColor.rawValue : "",
            notes: nil
        )

        do {
            let _: DiaperChange = try await APIClient.shared.post(
                path: APIEndpoints.changes,
                body: input
            )
            await onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
