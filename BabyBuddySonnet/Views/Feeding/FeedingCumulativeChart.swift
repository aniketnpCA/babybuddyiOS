import SwiftUI
import Charts

struct FeedingCumulativeChart: View {
    let data: FeedingViewModel.CumulativeChartData

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        return String(format: "%02d:%02d", h, m)
    }

    private func oz(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private var statusColor: Color {
        switch data.status {
        case .onTrack: return .green
        case .behind: return .orange
        case .critical: return .red
        case .complete: return .blue
        }
    }

    // X-axis domain: show from 0 to 1440 (midnight to midnight)
    private var xDomain: ClosedRange<Double> { 0...1440 }

    // Y-axis domain: 0 to target with 10% headroom
    private var yMax: Double { max(data.targetAmount * 1.15, 2) }

    // Tick marks at every 3 hours
    private var xTicks: [Double] {
        stride(from: 0.0, through: 1440.0, by: 180.0).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            headerRow

            // Chart
            chart
                .frame(height: 200)

            // Footer stats
            footerRow
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Feeding")
                    .font(.headline)
                Text("\(oz(data.currentOz)) / \(oz(data.targetAmount)) oz")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(data.status.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
    }

    private var chart: some View {
        Chart {
            // Expected line (dashed, gray/white)
            ForEach(Array(data.expectedSeries.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.x),
                    y: .value("Expected oz", point.y),
                    series: .value("Series", "Expected")
                )
                .foregroundStyle(.white.opacity(0.75))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .interpolationMethod(.linear)
            }

            // Average line (orange, step)
            ForEach(Array(data.averageSeries.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.x),
                    y: .value("Avg oz", point.y),
                    series: .value("Series", "\(data.averageDays)-day avg")
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.stepEnd)
            }

            // Today line (blue, step)
            ForEach(Array(data.todaySeries.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.x),
                    y: .value("Today oz", point.y),
                    series: .value("Series", "Today")
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.stepEnd)
            }

            // Target amount reference line
            RuleMark(y: .value("Target", data.targetAmount))
                .foregroundStyle(.white.opacity(0.25))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: 0...yMax)
        .chartXAxis {
            AxisMarks(values: xTicks) { value in
                if let minutes = value.as(Double.self) {
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.1))
                    AxisTick()
                        .foregroundStyle(.secondary)
                    AxisValueLabel {
                        Text(formatMinutes(minutes))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.1))
                AxisTick()
                    .foregroundStyle(.secondary)
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
    }

    private var footerRow: some View {
        HStack {
            if !data.expectedSeries.isEmpty {
                Label {
                    Text("Expected: \(oz(data.expectedNow)) oz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Rectangle()
                        .fill(.white.opacity(0.75))
                        .frame(width: 14, height: 2)
                }
            }
            Spacer()
            if !data.averageSeries.isEmpty {
                Label {
                    Text("\(data.averageDays)-day avg: \(oz(data.averageNow)) oz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Rectangle()
                        .fill(.orange)
                        .frame(width: 14, height: 2)
                }
            }
        }
    }
}
