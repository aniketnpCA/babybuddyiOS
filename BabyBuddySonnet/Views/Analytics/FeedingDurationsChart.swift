import SwiftUI
import Charts

struct FeedingDurationsChart: View {
    let dailyFeedingDurations: [(date: String, avgMinutes: Double, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Feeding Durations")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dailyFeedingDurations.isEmpty {
                Text("No feeding duration data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                // Top: Average duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Chart {
                        ForEach(dailyFeedingDurations, id: \.date) { day in
                            if let date = DateFormatting.parseDate(day.date) {
                                LineMark(
                                    x: .value("Date", date),
                                    y: .value("Minutes", day.avgMinutes)
                                )
                                .foregroundStyle(Color.jayFeedingFallback)
                                .lineStyle(StrokeStyle(lineWidth: 2))

                                PointMark(
                                    x: .value("Date", date),
                                    y: .value("Minutes", day.avgMinutes)
                                )
                                .foregroundStyle(Color.jayFeedingFallback)
                                .symbolSize(15)
                            }
                        }
                    }
                    .chartYAxisLabel("min")
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
                    .frame(height: 140)
                }

                // Bottom: Feeding count
                VStack(alignment: .leading, spacing: 4) {
                    Text("Feedings per Day")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Chart {
                        ForEach(dailyFeedingDurations, id: \.date) { day in
                            if let date = DateFormatting.parseDate(day.date) {
                                BarMark(
                                    x: .value("Date", date),
                                    y: .value("Count", day.count)
                                )
                                .foregroundStyle(Color.jayDiaperFallback.gradient)
                                .cornerRadius(3)
                            }
                        }
                    }
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
                    .frame(height: 140)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
