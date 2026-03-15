import SwiftUI
import Charts

struct SleepTotalsChart: View {
    let dailySleepTotals: [(date: String, hours: Double)]
    let targetHours: Double

    private struct SleepPoint: Identifiable {
        let id = UUID()
        let date: Date
        let hours: Double
        let series: String
    }

    private var chartData: [SleepPoint] {
        let maData = Calculations.movingAverage(
            dailySleepTotals.map { (date: $0.date, value: $0.hours) },
            window: 7
        )
        var points: [SleepPoint] = []
        for item in maData {
            if let date = DateFormatting.parseDate(item.date) {
                points.append(SleepPoint(date: date, hours: item.value, series: "Daily"))
                if let ma = item.ma {
                    points.append(SleepPoint(date: date, hours: ma, series: "7-day Avg"))
                }
            }
        }
        return points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sleep Totals")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dailySleepTotals.isEmpty {
                Text("No sleep data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    // Daily bars
                    ForEach(dailySleepTotals, id: \.date) { day in
                        if let date = DateFormatting.parseDate(day.date) {
                            BarMark(
                                x: .value("Date", date),
                                y: .value("Hours", day.hours)
                            )
                            .foregroundStyle(.purple.opacity(0.5).gradient)
                            .cornerRadius(3)
                        }
                    }

                    // 7-day moving average line
                    ForEach(chartData.filter { $0.series == "7-day Avg" }) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Hours", point.hours)
                        )
                        .foregroundStyle(.purple)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }

                    // Target line
                    if targetHours > 0 {
                        RuleMark(y: .value("Target", targetHours))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Target: \(String(format: "%.0f", targetHours))h")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                    }
                }
                .chartYAxisLabel("hours")
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
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

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.purple.opacity(0.5))
                            .frame(width: 14, height: 8)
                        Text("Daily")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.purple)
                            .frame(width: 14, height: 2)
                        Text("7-day Avg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if targetHours > 0 {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.green)
                                .frame(width: 14, height: 1)
                            Text("Target")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
