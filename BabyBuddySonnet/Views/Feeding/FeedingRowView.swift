import SwiftUI

struct FeedingRowView: View {
    let feeding: Feeding
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    private var methodColor: Color {
        JayColors.feedingMethodColor(feeding.feedingMethod ?? .bottle)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Large filled icon circle
            Image(systemName: feeding.feedingMethod?.sfSymbol ?? "questionmark.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(methodColor, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("\(DateFormatting.formatTime(feeding.start)) \u{2013} \(DateFormatting.formatTime(feeding.end))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(theme.feedingMethodNames[feeding.method] ?? feeding.feedingMethod?.displayName ?? feeding.method)
                        .font(.subheadline.weight(.bold))
                    if let amount = feeding.amount {
                        Text("\(String(format: "%.2f", amount)) oz")
                            .font(.subheadline)
                            .foregroundStyle(methodColor)
                    }
                }
                Text(theme.feedingTypeNames[feeding.type] ?? feeding.feedingType?.displayName ?? feeding.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(DateFormatting.formatDuration(start: feeding.start, end: feeding.end))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
