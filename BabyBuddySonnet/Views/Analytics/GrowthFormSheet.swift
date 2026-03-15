import SwiftUI

nonisolated enum GrowthEditTarget: Sendable {
    case weight(WeightMeasurement)
    case height(HeightMeasurement)
    case headCircumference(HeadCircumferenceMeasurement)
}

struct GrowthFormSheet: View {
    let childID: Int
    let viewModel: AnalyticsViewModel
    let editing: GrowthEditTarget?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var measurementType: MeasurementType
    @State private var date: Date
    @State private var notes: String
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?

    // Weight fields (imperial: lbs + oz)
    @State private var weightPounds: Int
    @State private var weightOunces: Double

    // Height field (cm)
    @State private var heightCm: Double

    // Head circumference field (cm)
    @State private var headCircumferenceCm: Double

    nonisolated enum MeasurementType: String, CaseIterable {
        case weight = "Weight"
        case height = "Height"
        case headCircumference = "Head Circ."

        var icon: String {
            switch self {
            case .weight: return "scalemass.fill"
            case .height: return "ruler.fill"
            case .headCircumference: return "circle"
            }
        }
    }

    init(childID: Int, viewModel: AnalyticsViewModel, editing: GrowthEditTarget? = nil, onSave: @escaping () -> Void) {
        self.childID = childID
        self.viewModel = viewModel
        self.editing = editing
        self.onSave = onSave

        switch editing {
        case .weight(let m):
            _measurementType = State(initialValue: .weight)
            let totalOz = m.weight / 28.3495
            _weightPounds = State(initialValue: Int(totalOz / 16))
            _weightOunces = State(initialValue: totalOz.truncatingRemainder(dividingBy: 16))
            _heightCm = State(initialValue: 0)
            _headCircumferenceCm = State(initialValue: 0)
            _date = State(initialValue: DateFormatting.parseDate(m.date) ?? Date())
            _notes = State(initialValue: m.notes ?? "")
        case .height(let m):
            _measurementType = State(initialValue: .height)
            _weightPounds = State(initialValue: 0)
            _weightOunces = State(initialValue: 0)
            _heightCm = State(initialValue: m.height)
            _headCircumferenceCm = State(initialValue: 0)
            _date = State(initialValue: DateFormatting.parseDate(m.date) ?? Date())
            _notes = State(initialValue: m.notes ?? "")
        case .headCircumference(let m):
            _measurementType = State(initialValue: .headCircumference)
            _weightPounds = State(initialValue: 0)
            _weightOunces = State(initialValue: 0)
            _heightCm = State(initialValue: 0)
            _headCircumferenceCm = State(initialValue: m.headCircumference)
            _date = State(initialValue: DateFormatting.parseDate(m.date) ?? Date())
            _notes = State(initialValue: m.notes ?? "")
        case nil:
            _measurementType = State(initialValue: .weight)
            _weightPounds = State(initialValue: 0)
            _weightOunces = State(initialValue: 0)
            _heightCm = State(initialValue: 0)
            _headCircumferenceCm = State(initialValue: 0)
            _date = State(initialValue: Date())
            _notes = State(initialValue: "")
        }
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Measurement type picker (disabled when editing)
                Section {
                    Picker("Type", selection: $measurementType) {
                        ForEach(MeasurementType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isEditing)
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
            .navigationTitle(isEditing ? "Edit Measurement" : "Log Growth")
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
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || isDeleting || !isValid)
                }
            }
            .confirmationDialog("Delete Measurement", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await deleteMeasurement() }
                }
            } message: {
                Text("This action cannot be undone.")
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

    // MARK: - Delete

    private func deleteMeasurement() async {
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            switch editing {
            case .weight(let m):
                try await viewModel.deleteWeight(id: m.id)
            case .height(let m):
                try await viewModel.deleteHeight(id: m.id)
            case .headCircumference(let m):
                try await viewModel.deleteHeadCircumference(id: m.id)
            case nil:
                return
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let noteText: String? = notes.isEmpty ? nil : notes
        do {
            switch (measurementType, editing) {
            case (.weight, .weight(let m)):
                let totalGrams = (Double(weightPounds) * 453.592) + (weightOunces * 28.3495)
                try await viewModel.updateWeight(id: m.id, weightGrams: totalGrams, date: date, notes: noteText)
            case (.weight, _):
                let totalGrams = (Double(weightPounds) * 453.592) + (weightOunces * 28.3495)
                try await viewModel.createWeight(childID: childID, weightGrams: totalGrams, date: date, notes: noteText)
            case (.height, .height(let m)):
                try await viewModel.updateHeight(id: m.id, heightCm: heightCm, date: date, notes: noteText)
            case (.height, _):
                try await viewModel.createHeight(childID: childID, heightCm: heightCm, date: date, notes: noteText)
            case (.headCircumference, .headCircumference(let m)):
                try await viewModel.updateHeadCircumference(id: m.id, headCircumferenceCm: headCircumferenceCm, date: date, notes: noteText)
            case (.headCircumference, _):
                try await viewModel.createHeadCircumference(childID: childID, headCircumferenceCm: headCircumferenceCm, date: date, notes: noteText)
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
