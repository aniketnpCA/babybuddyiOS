import SwiftUI

/// Shows the time interval between two activities as a subtle inline badge.
/// Place between row items in a list.
struct IntervalIndicator: View {
    let minutes: Int

    var body: some View {
        HStack(spacing: 6) {
            dashedLine
            intervalBadge
            dashedLine
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }

    private var intervalBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 9))
            Text(DateFormatting.formatMinutesToDuration(minutes))
                .font(.caption2.weight(.medium).monospacedDigit())
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private var dashedLine: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(height: 1)
    }
}

// MARK: - Helpers for computing intervals

extension IntervalIndicator {
    /// Compute interval in minutes between two ISO date strings.
    /// `laterTime` should be the more recent activity's start/time.
    /// `earlierTime` should be the previous activity's end/time.
    /// Returns nil if interval is < 1 minute or dates can't be parsed.
    static func intervalMinutes(from earlierTime: String, to laterTime: String) -> Int? {
        guard let earlier = DateFormatting.parseISO(earlierTime),
              let later = DateFormatting.parseISO(laterTime)
        else { return nil }
        let minutes = Int(later.timeIntervalSince(earlier) / 60)
        return minutes >= 1 ? minutes : nil
    }
}
