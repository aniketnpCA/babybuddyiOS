import SwiftUI

struct SleepRowView: View {
    let sleep: SleepRecord
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    private var entryColor: Color {
        JayColors.sleepColor(isNap: sleep.nap)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: sleep.nap ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(entryColor, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("\(DateFormatting.formatTime(sleep.start)) \u{2013} \(DateFormatting.formatTime(sleep.end))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(sleep.nap ? "Nap" : theme.sleepNightLabel)
                    .font(.subheadline.weight(.bold))
            }

            Spacer()

            Text(DateFormatting.formatDuration(start: sleep.start, end: sleep.end))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
