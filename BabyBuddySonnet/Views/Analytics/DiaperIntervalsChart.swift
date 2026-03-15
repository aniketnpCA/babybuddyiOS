import SwiftUI
import Charts

struct DiaperIntervalsChart: View {
    let diaperIntervals: [(date: Date, hours: Double)]

    private struct IntervalPoint: Identifiable {
        let id = UUID()
        let date: Date
        let hours: Double
        let series: String
    }

    private var chartData: [IntervalPoint] {
        // Build daily averages for MA calculation
        var dailyAvg: [(date: String, value: Double)] = []
        var grouped: [String: [Double]] = [:]
        for interval in diaperIntervals {
            let key = DateFormatting.formatDateOnly(interval.date)
            grouped[key, default: []].append(interval.hours)
        }
        for (dateStr, hours) in grouped.sorted(by: { $0.key < $1.key }) {
            dailyAvg.append((date: dateStr, value: hours.reduce(0, +) / Double(hours.count)))
        }

        let maData = Calculations.movingAverage(dailyAvg, window: 7)
        var points: [IntervalPoint] = []
        for item in maData {
            if let date = DateFormatting.parseDate(item.date) {
                if let ma = item.ma {
                    points.append(IntervalPoint(date: date, hours: ma, series: "7-day Avg"))
                }
            }
        }
        return points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Diaper Intervals")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if diaperIntervals.isEmpty {
                Text("No diaper interval data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    // Individual intervals as scatter
                    ForEach(Array(diaperIntervals.enumerated()), id: \.offset) { _, interval in
                        PointMark(
                            x: .value("Date", interval.date, unit: .day),
                            y: .value("Hours", interval.hours)
                        )
                        .foregroundStyle(.green.opacity(0.3))
                        .symbolSize(15)
                    }

                    // 7-day moving average
                    ForEach(chartData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Hours", point.hours)
                        )
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
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
                        Circle()
                            .fill(.green.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Text("Each change")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: 14, height: 2)
                        Text("7-day Avg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
