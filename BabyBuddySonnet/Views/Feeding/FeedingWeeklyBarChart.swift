import SwiftUI
import Charts

struct FeedingWeeklyBarChart: View {
    let data: [FeedingViewModel.DailyFeedingData]
    let targetAmount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(data) { day in
                    BarMark(
                        x: .value("Day", day.displayDate),
                        y: .value("Oz", day.totalOz)
                    )
                    .foregroundStyle(day.totalOz >= targetAmount ? Color.green : Color.blue)
                    .cornerRadius(4)
                }

                if targetAmount > 0 {
                    RuleMark(y: .value("Target", targetAmount))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .foregroundStyle(.secondary)
                        .annotation(position: .top, alignment: .trailing) {
                            Text("\(Int(targetAmount)) oz")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let oz = value.as(Double.self) {
                            Text("\(Int(oz))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
