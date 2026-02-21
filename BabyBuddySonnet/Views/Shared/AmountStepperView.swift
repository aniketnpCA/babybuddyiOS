import SwiftUI

struct AmountStepperView: View {
    @Binding var amount: Double
    var step: Double = 0.25
    var range: ClosedRange<Double> = 0...50
    var unit: String = "oz"

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

            Text(String(format: "%.2f", amount))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .frame(minWidth: 80)
                .contentTransition(.numericText())

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
}
