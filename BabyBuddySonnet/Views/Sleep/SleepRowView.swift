import SwiftUI

struct SleepRowView: View {
    let sleep: SleepRecord
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sleep.nap ? "sun.max.fill" : "moon.fill")
                .font(.title3)
                .foregroundStyle(sleep.nap ? .orange : .purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(sleep.nap ? "Nap" : theme.sleepNightLabel)
                    .font(.subheadline.weight(.medium))
                Text("\(DateFormatting.formatTime(sleep.start)) - \(DateFormatting.formatTime(sleep.end))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(DateFormatting.formatDuration(start: sleep.start, end: sleep.end))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
