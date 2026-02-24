import SwiftUI

struct SleepTimelineView: View {
    let periods: [SleepViewModel.SleepPeriod]
    let targetHours: Double
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    var totalMinutes: Int {
        periods.reduce(0) { total, period in
            total + Int((period.endHour - period.startHour) * 60)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.purple)
                Text(theme.sleepTimelineTitle)
                    .font(.headline)
                Spacer()
                Text(DateFormatting.formatMinutesToDuration(totalMinutes))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.purple)
            }

            // 24-hour timeline
            GeometryReader { geometry in
                let width = geometry.size.width

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 24)

                    // Sleep periods
                    ForEach(periods) { period in
                        let startX = (period.startHour / 24.0) * width
                        let periodWidth = ((period.endHour - period.startHour) / 24.0) * width

                        RoundedRectangle(cornerRadius: 4)
                            .fill(period.isNap ? Color.orange : Color.purple)
                            .frame(width: max(2, periodWidth), height: 20)
                            .offset(x: startX)
                    }
                }
                .frame(height: 24)
            }
            .frame(height: 24)

            // Hour labels
            HStack {
                Text("12a")
                Spacer()
                Text("6a")
                Spacer()
                Text("12p")
                Spacer()
                Text("6p")
                Spacer()
                Text("12a")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(.orange).frame(width: 8, height: 8)
                    Text("Nap").font(.caption)
                }
                HStack(spacing: 4) {
                    Circle().fill(.purple).frame(width: 8, height: 8)
                    Text(theme.sleepNightStat.capitalized).font(.caption)
                }
                Spacer()
                Text("Target: \(String(format: "%.0f", targetHours))h")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
