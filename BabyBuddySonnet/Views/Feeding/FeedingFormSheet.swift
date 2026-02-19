import SwiftUI

struct FeedingFormSheet: View {
    let childID: Int
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var feedingType: FeedingType = .breastMilk
    @State private var feedingMethod: FeedingMethod = .bottle
    @State private var amount: Double = 3.0
    @State private var startTime: Date = Date().addingTimeInterval(-1800)
    @State private var endTime: Date = Date()
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Feeding Type", selection: $feedingType) {
                        ForEach(FeedingType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Method") {
                    Picker("Method", selection: $feedingMethod) {
                        ForEach(FeedingMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                }

                if feedingMethod == .bottle {
                    Section("Amount") {
                        AmountStepperView(amount: $amount)
                            .frame(maxWidth: .infinity)
                    }
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
            .navigationTitle("Log Feeding")
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

        let input = CreateFeedingInput(
            child: childID,
            start: DateFormatting.formatForAPI(startTime),
            end: DateFormatting.formatForAPI(endTime),
            type: feedingType.rawValue,
            method: feedingMethod.rawValue,
            amount: feedingMethod == .bottle ? amount : nil,
            notes: nil
        )

        do {
            let _: Feeding = try await APIClient.shared.post(
                path: APIEndpoints.feedings,
                body: input
            )
            await onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
