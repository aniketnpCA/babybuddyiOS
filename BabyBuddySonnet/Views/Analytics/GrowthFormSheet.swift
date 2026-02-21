import SwiftUI

struct GrowthFormSheet: View {
    let childID: Int
    let viewModel: AnalyticsViewModel
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var measurementType: MeasurementType = .weight
    @State private var date = Date()
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    // Weight fields (imperial: lbs + oz)
    @State private var weightPounds: Int = 0
    @State private var weightOunces: Double = 0

    // Height field (cm)
    @State private var heightCm: Double = 0

    // Head circumference field (cm)
    @State private var headCircumferenceCm: Double = 0

    nonisolated enum MeasurementType: String, CaseIterable {
        case weight = "Weight"
        case height = "Height"
        case headCircumference = "Head Circumference"

        var icon: String {
            switch self {
            case .weight: return "scalemass.fill"
            case .height: return "ruler.fill"
            case .headCircumference: return "circle"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Measurement type picker
                Section {
                    Picker("Type", selection: $measurementType) {
                        ForEach(MeasurementType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Value input
                Section("Measurement") {
                    switch measurementType {
                    case .weight:
                        weightInput
                    case .height:
                        heightInput
                    case .headCircumference:
                        headCircumferenceInput
                    }
                }

                // Date picker
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                // Notes
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Log Growth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
        }
    }

    // MARK: - Input Views

    private var weightInput: some View {
        VStack(spacing: 8) {
            Stepper("Pounds: \(weightPounds)", value: $weightPounds, in: 0...50)
            HStack {
                Text("Ounces:")
                Spacer()
                TextField("oz", value: $weightOunces, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                Text("oz")
                    .foregroundStyle(.secondary)
            }

            let totalGrams = (Double(weightPounds) * 453.592) + (weightOunces * 28.3495)
            if totalGrams > 0 {
                Text("\(String(format: "%.0f", totalGrams))g / \(String(format: "%.2f", totalGrams / 1000.0))kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var heightInput: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Height:")
                Spacer()
                TextField("cm", value: $heightCm, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                Text("cm")
                    .foregroundStyle(.secondary)
            }

            if heightCm > 0 {
                Text("\(String(format: "%.1f", heightCm / 2.54)) inches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var headCircumferenceInput: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Circumference:")
                Spacer()
                TextField("cm", value: $headCircumferenceCm, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                Text("cm")
                    .foregroundStyle(.secondary)
            }

            if headCircumferenceCm > 0 {
                Text("\(String(format: "%.1f", headCircumferenceCm / 2.54)) inches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        switch measurementType {
        case .weight:
            return (Double(weightPounds) * 453.592 + weightOunces * 28.3495) > 0
        case .height:
            return heightCm > 0
        case .headCircumference:
            return headCircumferenceCm > 0
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let noteText: String? = notes.isEmpty ? nil : notes

        do {
            switch measurementType {
            case .weight:
                let totalGrams = (Double(weightPounds) * 453.592) + (weightOunces * 28.3495)
                try await viewModel.createWeight(
                    childID: childID,
                    weightGrams: totalGrams,
                    date: date,
                    notes: noteText
                )
            case .height:
                try await viewModel.createHeight(
                    childID: childID,
                    heightCm: heightCm,
                    date: date,
                    notes: noteText
                )
            case .headCircumference:
                try await viewModel.createHeadCircumference(
                    childID: childID,
                    headCircumferenceCm: headCircumferenceCm,
                    date: date,
                    notes: noteText
                )
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
