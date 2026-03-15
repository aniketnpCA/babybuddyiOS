import SwiftUI
import Charts

struct PumpingAmountsChart: View {
    let dailyPumpingOz: [(date: String, oz: Double)]

    private struct PumpPoint: Identifiable {
        let id = UUID()
        let date: Date
        let oz: Double
        let series: String
    }

    private var chartData: [PumpPoint] {
        let maData = Calculations.movingAverage(
            dailyPumpingOz.map { (date: $0.date, value: $0.oz) },
            window: 7
        )
        var points: [PumpPoint] = []
        for item in maData {
            if let date = DateFormatting.parseDate(item.date) {
                points.append(PumpPoint(date: date, oz: item.value, series: "Daily"))
                if let ma = item.ma {
                    points.append(PumpPoint(date: date, oz: ma, series: "7-day Avg"))
                }
            }
        }
        return points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pumping Amounts")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dailyPumpingOz.isEmpty {
                Text("No pumping data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    // Area fill
                    ForEach(chartData.filter { $0.series == "Daily" }) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("oz", point.oz)
                        )
                        .foregroundStyle(.orange.opacity(0.2).gradient)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("oz", point.oz),
                            series: .value("Series", "Daily")
                        )
                        .foregroundStyle(.orange.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    }

                    // 7-day moving average
                    ForEach(chartData.filter { $0.series == "7-day Avg" }) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("oz", point.oz),
                            series: .value("Series", "7-day Avg")
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                }
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
                .frame(height: 200)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.orange.opacity(0.3))
                            .frame(width: 14, height: 8)
                        Text("Daily")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.orange)
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
