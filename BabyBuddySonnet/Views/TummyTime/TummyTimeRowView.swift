import SwiftUI

struct TummyTimeRowView: View {
    let tummyTime: TummyTime

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.play")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color.jayTummyTimeFallback, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("\(DateFormatting.formatTime(tummyTime.start)) \u{2013} \(DateFormatting.formatTime(tummyTime.end))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text("Tummy Time")
                        .font(.subheadline.weight(.bold))
                    if let duration = durationMinutes {
                        Text("\(duration) min")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                if let milestone = tummyTime.milestone, !milestone.isEmpty {
                    Text(milestone)
                        .font(.caption)
                        .foregroundStyle(Color.jayTummyTimeFallback)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }

    private var durationMinutes: Int? {
        guard let start = DateFormatting.parseISO(tummyTime.start),
              let end = DateFormatting.parseISO(tummyTime.end)
        else { return nil }
        return Int(end.timeIntervalSince(start) / 60)
    }
}
