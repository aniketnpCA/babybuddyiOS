import SwiftUI

struct PumpingRowView: View {
    let pumping: Pumping

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.triangle.fill")
                .font(.title3)
                .foregroundStyle(
                    AppConstants.milkCategoryColors[pumping.milkCategory] ?? .orange
                )
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(String(format: "%.2f oz", pumping.amount))
                        .font(.subheadline.weight(.medium))
                    Text(pumping.milkCategory.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (AppConstants.milkCategoryColors[pumping.milkCategory] ?? .orange).opacity(0.15)
                        )
                        .clipShape(Capsule())
                }
                Text("\(DateFormatting.formatTime(pumping.start)) - \(DateFormatting.formatTime(pumping.end))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(DateFormatting.formatDuration(start: pumping.start, end: pumping.end))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
