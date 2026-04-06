import SwiftUI

struct DiaperRowView: View {
    let change: DiaperChange
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    private var typeDescription: String {
        if change.wet && change.solid { return theme.diaperBothDesc }
        if change.wet { return theme.diaperWetDesc }
        if change.solid { return theme.diaperSolidDesc }
        return "Empty"
    }

    private var entryColor: Color {
        JayColors.diaperColor(wet: change.wet, solid: change.solid)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconForType)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(entryColor, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(DateFormatting.formatTime(change.time))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(typeDescription)
                    .font(.subheadline.weight(.bold))
                if change.solid, let stoolColor = change.stoolColor {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(swiftUIColor(for: stoolColor))
                            .frame(width: 8, height: 8)
                        Text(stoolColor.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let amount = change.amount, amount > 0 {
                Text(String(format: "%.1f", amount))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var iconForType: String {
        if change.wet && change.solid { return "drop.circle.fill" }
        if change.wet { return "drop.fill" }
        if change.solid { return "circle.fill" }
        return "circle.dotted"
    }

    private func swiftUIColor(for color: StoolColor) -> Color {
        AppConstants.diaperColors.first { $0.color == color }?.swiftUIColor ?? .gray
    }
}
