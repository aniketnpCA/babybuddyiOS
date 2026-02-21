import SwiftUI

struct ActiveTimersCard: View {
    let timers: [BabyTimer]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Timers", systemImage: "timer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            ForEach(timers) { timer in
                HStack(spacing: 10) {
                    Image(systemName: iconForTimer(timer.name))
                        .font(.body)
                        .foregroundStyle(colorForTimer(timer.name))
                        .frame(width: 24)

                    Text(timer.name.isEmpty ? "Timer" : timer.name)
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    if let startDate = DateFormatting.parseISO(timer.start) {
                        Text(startDate, style: .timer)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func iconForTimer(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("feed") || lower.contains("bottle") || lower.contains("breast") {
            return "drop.fill"
        } else if lower.contains("sleep") || lower.contains("nap") {
            return "moon.fill"
        } else if lower.contains("pump") {
            return "drop.triangle.fill"
        } else if lower.contains("tummy") || lower.contains("play") {
            return "figure.play"
        }
        return "timer"
    }

    private func colorForTimer(_ name: String) -> Color {
        let lower = name.lowercased()
        if lower.contains("feed") || lower.contains("bottle") || lower.contains("breast") {
            return .blue
        } else if lower.contains("sleep") || lower.contains("nap") {
            return .purple
        } else if lower.contains("pump") {
            return .orange
        } else if lower.contains("tummy") || lower.contains("play") {
            return .green
        }
        return .orange
    }
}
