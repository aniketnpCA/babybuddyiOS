import SwiftUI

struct FeedingRowView: View {
    let feeding: Feeding

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feeding.feedingMethod?.sfSymbol ?? "questionmark.circle")
                .font(.title3)
                .foregroundStyle(
                    AppConstants.feedingMethodColors[feeding.feedingMethod ?? .bottle] ?? .gray
                )
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(feeding.feedingMethod?.displayName ?? feeding.method)
                        .font(.subheadline.weight(.medium))
                    if let amount = feeding.amount {
                        Text("\(String(format: "%.2f", amount)) oz")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                Text(feeding.feedingType?.displayName ?? feeding.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(DateFormatting.formatTime(feeding.end))
                    .font(.subheadline)
                Text(DateFormatting.formatDuration(start: feeding.start, end: feeding.end))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
