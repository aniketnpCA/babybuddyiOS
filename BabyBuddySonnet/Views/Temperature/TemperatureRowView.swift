import SwiftUI

struct TemperatureRowView: View {
    let temperature: Temperature

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(temperatureColor, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(DateFormatting.formatTime(temperature.time))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text(String(format: "%.1f\u{00B0}F", temperature.temperature))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(temperatureColor)
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
        .padding(.vertical, 6)
    }

    private var temperatureColor: Color {
        if temperature.temperature >= 100.4 { return .jayTemperatureFallback }
        if temperature.temperature >= 99.5 { return .jayPumpingFallback }
        return .jayTummyTimeFallback
    }
}
