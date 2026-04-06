import SwiftUI
import Charts

struct FeedingIntervalsChart: View {
    let dailyFeedingIntervals: [(date: String, avgHours: Double)]

    private var overallAvg: Double {
        guard !dailyFeedingIntervals.isEmpty else { return 0 }
        return dailyFeedingIntervals.reduce(0) { $0 + $1.avgHours } / Double(dailyFeedingIntervals.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Feeding Intervals")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dailyFeedingIntervals.isEmpty {
                Text("No feeding interval data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(dailyFeedingIntervals, id: \.date) { day in
                        if let date = DateFormatting.parseDate(day.date) {
                            LineMark(
                                x: .value("Date", date),
                                y: .value("Hours", day.avgHours)
                            )
                            .foregroundStyle(Color.jayFeedingFallback)
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            PointMark(
                                x: .value("Date", date),
                                y: .value("Hours", day.avgHours)
                            )
                            .foregroundStyle(Color.jayFeedingFallback)
                            .symbolSize(15)
                        }
                    }

                    RuleMark(y: .value("Average", overallAvg))
                        .foregroundStyle(Color.jayPumpingFallback)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Avg: \(String(format: "%.1f", overallAvg))h")
                                .font(.caption2)
                                .foregroundStyle(Color.jayPumpingFallback)
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
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
