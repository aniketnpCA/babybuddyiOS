import SwiftUI
import Charts

struct FeedingWeekChart: View {
    let data: [FeedingViewModel.DailyFeedingData]
    let target: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.headline)

            Chart {
                ForEach(data) { day in
                    BarMark(
                        x: .value("Day", day.displayDate),
                        y: .value("Ounces", day.totalOz)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }

                RuleMark(y: .value("Goal", target))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
            }
            .chartYAxisLabel("oz")
            .frame(height: 200)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
