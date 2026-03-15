import SwiftUI

struct TummyTimeRowView: View {
    let tummyTime: TummyTime

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.play")
                .font(.body)
                .foregroundStyle(.green)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(DateFormatting.formatTime(tummyTime.start)) – \(DateFormatting.formatTime(tummyTime.end))")
                        .font(.subheadline.weight(.medium))

                    if let duration = durationMinutes {
                        Text("(\(duration) min)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let milestone = tummyTime.milestone, !milestone.isEmpty {
                    Text(milestone)
                        .font(.caption)
                        .foregroundStyle(.green)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private var durationMinutes: Int? {
        guard let start = DateFormatting.parseISO(tummyTime.start),
              let end = DateFormatting.parseISO(tummyTime.end)
        else { return nil }
        return Int(end.timeIntervalSince(start) / 60)
    }
}
