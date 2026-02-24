import SwiftUI

struct DailySurplusCard: View {
    let pumpedOz: Double
    let consumedOz: Double
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    var surplus: Double { pumpedOz - consumedOz }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundStyle(.orange)
                Text(theme.surplusCardTitle)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.surplusCardPumped)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f oz", pumpedOz))
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.surplusCardConsumed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f oz", consumedOz))
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(theme.surplusCardSurplus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%+.1f oz", surplus))
                        .font(.title3.bold())
                        .foregroundStyle(surplus >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
