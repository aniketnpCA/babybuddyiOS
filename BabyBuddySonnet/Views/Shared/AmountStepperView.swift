import SwiftUI

struct AmountStepperView: View {
    @Binding var amount: Double
    var step: Double = 0.25
    var range: ClosedRange<Double> = 0...50
    var unit: String = "oz"

    @State private var isEditing = false
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        HStack(spacing: 20) {
            RepeatingButton {
                if amount - step >= range.lowerBound {
                    amount -= step
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }

            if isEditing {
                TextField("", value: $amount, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 80)
                    .focused($textFieldFocused)
                    .onSubmit { isEditing = false }
                    .onChange(of: textFieldFocused) { _, focused in
                        if !focused { isEditing = false }
                    }
                    .onAppear { textFieldFocused = true }
            } else {
                Button {
                    isEditing = true
                } label: {
                    Text(amount, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .frame(minWidth: 80)
                        .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
            }

            Text(unit)
                .font(.title3)
                .foregroundStyle(.secondary)

            RepeatingButton {
                if amount + step <= range.upperBound {
                    amount += step
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - RepeatingButton

private struct RepeatingButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: Label

    @State private var task: Task<Void, Never>?

    var body: some View {
        label
            .accessibilityAddTraits(.isButton)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard task == nil else { return }
                        action()
                        task = Task {
                            try? await Task.sleep(for: .milliseconds(400))
                            while !Task.isCancelled {
                                action()
                                try? await Task.sleep(for: .milliseconds(150))
                            }
                        }
                    }
                    .onEnded { _ in
                        task?.cancel()
                        task = nil
                    }
            )
    }
}
