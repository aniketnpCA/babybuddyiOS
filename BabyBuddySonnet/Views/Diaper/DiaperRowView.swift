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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForType)
                .font(.title3)
                .foregroundStyle(colorForType)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(typeDescription)
                    .font(.subheadline.weight(.medium))
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

            Text(DateFormatting.formatTime(change.time))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var iconForType: String {
        if change.wet && change.solid { return "drop.circle.fill" }
        if change.wet { return "drop.fill" }
        if change.solid { return "circle.fill" }
        return "circle.dotted"
    }

    private var colorForType: Color {
        if change.wet && change.solid { return .teal }
        if change.wet { return .cyan }
        if change.solid { return .brown }
        return .gray
    }

    private func swiftUIColor(for color: StoolColor) -> Color {
        AppConstants.diaperColors.first { $0.color == color }?.swiftUIColor ?? .gray
    }
}
