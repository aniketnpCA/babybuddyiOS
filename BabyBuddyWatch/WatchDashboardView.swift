import SwiftUI

struct WatchDashboardView: View {
    @State private var nextFeedingTime: Date?
    @State private var nextPumpingTime: Date?
    @State private var nextDiaperTime: Date?
    @State private var dailyConsumedOz: Double = 0
    @State private var dailyTargetOz: Double = 24
    @State private var childName: String = "Baby"

    /// Reads shared data from App Groups UserDefaults
    private let sharedDefaults = UserDefaults(suiteName: "group.com.BabyBuddySonnet.shared")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Feeding progress
                    feedingProgressSection

                    Divider()

                    // Next expected timers
                    if nextFeedingTime != nil || nextPumpingTime != nil || nextDiaperTime != nil {
                        nextExpectedSection
                    } else {
                        Text("No timers configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Quick log buttons
                    quickLogSection
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle(childName)
        }
        .onAppear {
            loadSharedData()
        }
    }

    // MARK: - Feeding Progress

    private var feedingProgressSection: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text("Fed Today")
                    .font(.caption)
                Spacer()
            }

            ProgressView(value: min(dailyConsumedOz / max(dailyTargetOz, 1), 1.0))
                .tint(progressColor)

            Text("\(String(format: "%.1f", dailyConsumedOz)) / \(String(format: "%.0f", dailyTargetOz)) oz")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var progressColor: Color {
        let pct = dailyConsumedOz / max(dailyTargetOz, 1)
        if pct >= 0.9 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }

    // MARK: - Next Expected

    private var nextExpectedSection: some View {
        VStack(spacing: 8) {
            if let time = nextFeedingTime {
                WatchCountdownRow(icon: "drop.fill", label: "Feed", time: time, color: .blue)
            }
            if let time = nextPumpingTime {
                WatchCountdownRow(icon: "drop.triangle.fill", label: "Pump", time: time, color: .orange)
            }
            if let time = nextDiaperTime {
                WatchCountdownRow(icon: "circle.dotted", label: "Diaper", time: time, color: .green)
            }
        }
    }

    // MARK: - Quick Log

    private var quickLogSection: some View {
        VStack(spacing: 8) {
            Text("Quick Log")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                QuickLogButton(icon: "drop.fill", label: "Feed", color: .blue) {
                    // TODO: Open compact feeding form or log via API
                }
                QuickLogButton(icon: "circle.dotted", label: "Diaper", color: .green) {
                    // TODO: Open compact diaper form or log via API
                }
            }

            HStack(spacing: 8) {
                QuickLogButton(icon: "drop.triangle.fill", label: "Pump", color: .orange) {
                    // TODO: Open compact pumping form or log via API
                }
                QuickLogButton(icon: "moon.fill", label: "Sleep", color: .purple) {
                    // TODO: Open compact sleep form or log via API
                }
            }
        }
    }

    // MARK: - Shared Data

    private func loadSharedData() {
        guard let defaults = sharedDefaults else { return }

        if let name = defaults.string(forKey: "childName") {
            childName = name
        }

        dailyConsumedOz = defaults.double(forKey: "dailyConsumedOz")
        dailyTargetOz = defaults.double(forKey: "dailyTargetOz")
        if dailyTargetOz == 0 { dailyTargetOz = 24 }

        if let feedingInterval = defaults.object(forKey: "nextFeedingTime") as? Date {
            nextFeedingTime = feedingInterval
        }
        if let pumpingInterval = defaults.object(forKey: "nextPumpingTime") as? Date {
            nextPumpingTime = pumpingInterval
        }
        if let diaperInterval = defaults.object(forKey: "nextDiaperTime") as? Date {
            nextDiaperTime = diaperInterval
        }
    }
}

// MARK: - Countdown Row

private struct WatchCountdownRow: View {
    let icon: String
    let label: String
    let time: Date
    let color: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let remaining = time.timeIntervalSince(context.date)
            let isOverdue = remaining <= 0

            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption2)

                Spacer()

                Text(time, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(isOverdue ? .red : (remaining < 1800 ? .orange : .green))
            }
        }
    }
}

// MARK: - Quick Log Button

private struct QuickLogButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }
}
