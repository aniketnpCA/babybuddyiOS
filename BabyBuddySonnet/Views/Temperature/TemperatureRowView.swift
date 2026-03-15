import SwiftUI

struct TemperatureRowView: View {
    let temperature: Temperature

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "thermometer.medium")
                .font(.body)
                .foregroundStyle(temperatureColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(String(format: "%.1f\u{00B0}", temperature.temperature))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(temperatureColor)

                    Text(DateFormatting.formatTime(temperature.time))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let notes = temperature.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    private var temperatureColor: Color {
        if temperature.temperature >= 100.4 { return .red }
        if temperature.temperature >= 99.5 { return .orange }
        return .green
    }
}
