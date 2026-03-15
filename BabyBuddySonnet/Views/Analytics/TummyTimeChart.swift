import SwiftUI
import Charts

struct TummyTimeChart: View {
    let dailyTummyTimeMinutes: [(date: String, minutes: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tummy Time")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dailyTummyTimeMinutes.isEmpty {
                Text("No tummy time data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(dailyTummyTimeMinutes, id: \.date) { day in
                        if let date = DateFormatting.parseDate(day.date) {
                            BarMark(
                                x: .value("Date", date),
                                y: .value("Minutes", day.minutes)
                            )
                            .foregroundStyle(.green.opacity(0.6).gradient)
                            .cornerRadius(3)
                        }
                    }
                }
                .chartYAxisLabel("minutes")
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
