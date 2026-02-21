import SwiftUI
import Charts

struct DailyTrendChart: View {
    let dailyFeedingOz: [(date: String, oz: Double)]
    let dailyPumpingOz: [(date: String, oz: Double)]

    private struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let series: String
    }

    private var trendData: [TrendPoint] {
        var points: [TrendPoint] = []

        // Feeding data with 7-day moving average
        let feedingWithMA = movingAverage(dailyFeedingOz, window: 7)
        for item in feedingWithMA {
            if let date = DateFormatting.parseDate(item.date) {
                points.append(TrendPoint(date: date, value: item.oz, series: "Feeding"))
                if let ma = item.ma {
                    points.append(TrendPoint(date: date, value: ma, series: "Feeding Avg"))
                }
            }
        }

        // Pumping data with 7-day moving average
        let pumpingWithMA = movingAverage(dailyPumpingOz, window: 7)
        for item in pumpingWithMA {
            if let date = DateFormatting.parseDate(item.date) {
                points.append(TrendPoint(date: date, value: item.oz, series: "Pumping"))
                if let ma = item.ma {
                    points.append(TrendPoint(date: date, value: ma, series: "Pumping Avg"))
                }
            }
        }

        return points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Trends")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dailyFeedingOz.isEmpty && dailyPumpingOz.isEmpty {
                Text("No feeding or pumping data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(trendData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("oz", point.value),
                        series: .value("Series", point.series)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .lineStyle(StrokeStyle(
                        lineWidth: point.series.contains("Avg") ? 2.5 : 1,
                        dash: point.series.contains("Avg") ? [] : [3, 3]
                    ))
                    .opacity(point.series.contains("Avg") ? 1.0 : 0.5)
                }
                .chartForegroundStyleScale([
                    "Feeding": Color.blue,
                    "Feeding Avg": Color.blue,
                    "Pumping": Color.orange,
                    "Pumping Avg": Color.orange,
                ])
                .chartYAxisLabel("oz")
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
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Moving Average

    private struct MAPoint {
        let date: String
        let oz: Double
        let ma: Double?
    }

    private func movingAverage(_ data: [(date: String, oz: Double)], window: Int) -> [MAPoint] {
        data.enumerated().map { index, item in
            let start = max(0, index - window + 1)
            let slice = data[start...index]
            let avg = slice.count >= window
                ? slice.reduce(0.0) { $0 + $1.oz } / Double(slice.count)
                : nil
            return MAPoint(date: item.date, oz: item.oz, ma: avg)
        }
    }
}
