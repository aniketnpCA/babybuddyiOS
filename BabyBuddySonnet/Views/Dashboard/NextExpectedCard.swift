import SwiftUI

struct NextExpectedCard: View {
    let nextFeedingTime: Date?
    let nextPumpingTime: Date?
    let nextDiaperTime: Date?
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    var body: some View {
        let items = buildItems()

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Next Expected")
                    .font(.headline)

                ForEach(items) { item in
                    NextExpectedRow(item: item)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func buildItems() -> [NextExpectedItem] {
        var items: [NextExpectedItem] = []

        if let time = nextFeedingTime {
            items.append(NextExpectedItem(
                category: theme.nextFeedingCategory,
                icon: theme.feedingTabIcon,
                color: .blue,
                expectedTime: time
            ))
        }

        if let time = nextPumpingTime {
            items.append(NextExpectedItem(
                category: theme.nextPumpingCategory,
                icon: theme.pumpingTabIcon,
                color: .orange,
                expectedTime: time
            ))
        }

        if let time = nextDiaperTime {
            items.append(NextExpectedItem(
                category: theme.nextDiaperCategory,
                icon: theme.diaperTabIcon,
                color: .green,
                expectedTime: time
            ))
        }

        return items.sorted { $0.expectedTime < $1.expectedTime }
    }
}

// MARK: - Supporting Types

private struct NextExpectedItem: Identifiable {
    let id = UUID()
    let category: String
    let icon: String
    let color: Color
    let expectedTime: Date
}

// MARK: - Row with Live Countdown

private struct NextExpectedRow: View {
    let item: NextExpectedItem

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            let remaining = item.expectedTime.timeIntervalSince(now)
            let urgency = urgencyLevel(remaining: remaining)

            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.body)
                    .foregroundStyle(item.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.category)
                        .font(.subheadline.weight(.medium))

                    Text(formatExpectedTime(item.expectedTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(countdownText(remaining: remaining))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(urgency.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(urgency.color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private func formatExpectedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func countdownText(remaining: TimeInterval) -> String {
        if remaining <= 0 {
            let overdue = -remaining
            let minutes = Int(overdue / 60)
            if minutes < 60 {
                return "\(minutes)m overdue"
            }
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m overdue"
        }

        let totalMinutes = Int(remaining / 60)
        if totalMinutes < 60 {
            return "in \(totalMinutes)m"
        }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if mins == 0 {
            return "in \(hours)h"
        }
        return "in \(hours)h \(mins)m"
    }

    private func urgencyLevel(remaining: TimeInterval) -> UrgencyLevel {
        if remaining <= 0 { return .overdue }
        if remaining <= 30 * 60 { return .soon }
        return .ok
    }
}

private enum UrgencyLevel {
    case ok, soon, overdue

    var color: Color {
        switch self {
        case .ok: return .green
        case .soon: return .orange
        case .overdue: return .red
        }
    }
}
