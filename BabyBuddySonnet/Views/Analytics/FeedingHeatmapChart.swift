import SwiftUI
import Charts

struct FeedingHeatmapChart: View {
    let feedingByHour: [Int: Int]

    private var chartData: [(hour: Int, count: Int)] {
        (0...23).map { hour in
            (hour: hour, count: feedingByHour[hour] ?? 0)
        }
    }

    private var maxCount: Int {
        chartData.map(\.count).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Feeding by Time of Day")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Chart(chartData, id: \.hour) { item in
                BarMark(
                    x: .value("Hour", item.hour),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    barColor(for: item.count).gradient
                )
                .cornerRadius(3)
            }
            .chartXScale(domain: 0...23)
            .chartXAxis {
                AxisMarks(values: [0, 3, 6, 9, 12, 15, 18, 21]) { value in
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.1))
                    AxisTick()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(hourLabel(hour))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.1))
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)

            // Peak time indicator
            if let peak = chartData.max(by: { $0.count < $1.count }), peak.count > 0 {
                Text("Peak: \(hourLabel(peak.hour)) (\(peak.count) feedings)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "a" : "p"
        return "\(h)\(period)"
    }

    private func barColor(for count: Int) -> Color {
        guard maxCount > 0 else { return .blue }
        let intensity = Double(count) / Double(maxCount)
        if intensity > 0.7 { return .blue }
        if intensity > 0.3 { return .blue.opacity(0.7) }
        return .blue.opacity(0.4)
    }
}
