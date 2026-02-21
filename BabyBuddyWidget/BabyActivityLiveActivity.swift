import ActivityKit
import SwiftUI
import WidgetKit

struct BabyActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BabyActivityAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.7))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.childName)
                        .font(.headline)
                }
            } compactLeading: {
                compactLeading(context: context)
            } compactTrailing: {
                compactTrailing(context: context)
            } minimal: {
                minimalView(context: context)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<BabyActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(context.attributes.childName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                feedingProgressBadge(context: context)
            }

            HStack(spacing: 16) {
                if let feedingTime = context.state.nextFeedingTime {
                    countdownItem(
                        icon: "drop.fill",
                        label: "Feed",
                        time: feedingTime,
                        color: .blue
                    )
                }

                if let pumpingTime = context.state.nextPumpingTime {
                    countdownItem(
                        icon: "drop.triangle.fill",
                        label: "Pump",
                        time: pumpingTime,
                        color: .orange
                    )
                }

                if let diaperTime = context.state.nextDiaperTime {
                    countdownItem(
                        icon: "circle.dotted",
                        label: "Diaper",
                        time: diaperTime,
                        color: .green
                    )
                }
            }
        }
        .padding()
    }

    private func countdownItem(icon: String, label: String, time: Date, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(time, style: .timer)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func feedingProgressBadge(context: ActivityViewContext<BabyActivityAttributes>) -> some View {
        let consumed = context.state.dailyConsumedOz
        let target = context.state.dailyTargetOz
        let pct = target > 0 ? Int((consumed / target) * 100) : 0

        return Text("\(String(format: "%.0f", consumed))/\(String(format: "%.0f", target))oz")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(pct >= 90 ? Color.green : (pct >= 50 ? Color.orange : Color.red))
            .clipShape(Capsule())
    }

    // MARK: - Dynamic Island Expanded

    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<BabyActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let feedingTime = context.state.nextFeedingTime {
                Label {
                    Text(feedingTime, style: .timer)
                        .font(.caption.monospacedDigit())
                } icon: {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.blue)
                }
                .font(.caption2)
            }

            if let pumpingTime = context.state.nextPumpingTime {
                Label {
                    Text(pumpingTime, style: .timer)
                        .font(.caption.monospacedDigit())
                } icon: {
                    Image(systemName: "drop.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.caption2)
            }
        }
    }

    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<BabyActivityAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let diaperTime = context.state.nextDiaperTime {
                Label {
                    Text(diaperTime, style: .timer)
                        .font(.caption.monospacedDigit())
                } icon: {
                    Image(systemName: "circle.dotted")
                        .foregroundStyle(.green)
                }
                .font(.caption2)
            }
        }
    }

    private func expandedBottom(context: ActivityViewContext<BabyActivityAttributes>) -> some View {
        let consumed = context.state.dailyConsumedOz
        let target = context.state.dailyTargetOz

        return HStack {
            Text("Fed today:")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(String(format: "%.1f", consumed))/\(String(format: "%.0f", target)) oz")
                .font(.caption.bold())
        }
    }

    // MARK: - Compact Views

    private func compactLeading(context: ActivityViewContext<BabyActivityAttributes>) -> some View {
        // Show soonest category icon
        let soonest = soonestTime(context: context)
        return Image(systemName: soonest?.icon ?? "drop.fill")
            .foregroundStyle(soonest?.color ?? .blue)
    }

    @ViewBuilder
    private func compactTrailing(context: ActivityViewContext<BabyActivityAttributes>) -> some View {
        if let time = soonestTime(context: context)?.time {
            Text(time, style: .timer)
                .font(.caption.monospacedDigit())
                .frame(minWidth: 32)
        }
    }

    // MARK: - Minimal View

    private func minimalView(context: ActivityViewContext<BabyActivityAttributes>) -> some View {
        let soonest = soonestTime(context: context)
        return Image(systemName: soonest?.icon ?? "drop.fill")
            .foregroundStyle(soonest?.color ?? .blue)
    }

    // MARK: - Helpers

    private struct SoonestInfo {
        let time: Date
        let icon: String
        let color: Color
    }

    private func soonestTime(context: ActivityViewContext<BabyActivityAttributes>) -> SoonestInfo? {
        var candidates: [(Date, String, Color)] = []
        if let t = context.state.nextFeedingTime { candidates.append((t, "drop.fill", .blue)) }
        if let t = context.state.nextPumpingTime { candidates.append((t, "drop.triangle.fill", .orange)) }
        if let t = context.state.nextDiaperTime { candidates.append((t, "circle.dotted", .green)) }
        guard let closest = candidates.min(by: { $0.0 < $1.0 }) else { return nil }
        return SoonestInfo(time: closest.0, icon: closest.1, color: closest.2)
    }
}
