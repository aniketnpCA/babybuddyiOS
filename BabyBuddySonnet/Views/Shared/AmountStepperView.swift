import SwiftUI

struct AmountStepperView: View {
    @Binding var amount: Double
    var step: Double = 0.25
    var range: ClosedRange<Double> = 0...50
    var unit: String = "oz"

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        HStack(spacing: 20) {
            Button {
                if amount - step >= range.lowerBound {
                    amount -= step
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $editText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 80)
                    .focused($textFieldFocused)
                    .onSubmit { commitEdit() }
                    .onChange(of: textFieldFocused) { _, focused in
                        if !focused { commitEdit() }
                    }
                    .onAppear { textFieldFocused = true }
            } else {
                Text(String(format: "%.2f", amount))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .frame(minWidth: 80)
                    .contentTransition(.numericText())
                    .onTapGesture {
                        editText = String(format: "%.2f", amount)
                        isEditing = true
                    }
            }

            Text(unit)
                .font(.title3)
                .foregroundStyle(.secondary)

            Button {
                if amount + step <= range.upperBound {
                    amount += step
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    private func commitEdit() {
        if let value = Double(editText) {
            amount = min(max(value, range.lowerBound), range.upperBound)
        }
        isEditing = false
    }
}
