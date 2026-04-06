import SwiftUI

struct PumpingRowView: View {
    let pumping: Pumping
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    private var categoryColor: Color {
        JayColors.milkCategoryColor(pumping.milkCategory)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "drop.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color.jayPumpingFallback, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("\(DateFormatting.formatTime(pumping.start)) \u{2013} \(DateFormatting.formatTime(pumping.end))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(pumping.amount.map { String(format: "%.2f oz", $0) } ?? "\u{2014} oz")
                        .font(.subheadline.weight(.bold))
                    Text(theme.milkCategoryNames[pumping.milkCategory.rawValue] ?? pumping.milkCategory.displayName)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundStyle(categoryColor)
                        .background(categoryColor.opacity(0.12), in: Capsule())
                }
            }

            Spacer()

            Text(DateFormatting.formatDuration(start: pumping.start, end: pumping.end))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
