import SwiftUI
import Charts

struct DiaperFrequencyChart: View {
    let dailyDiaperCounts: [(date: String, wetOnly: Int, solidOnly: Int, both: Int)]

    private var last14Days: [(date: String, wetOnly: Int, solidOnly: Int, both: Int)] {
        Array(dailyDiaperCounts.suffix(14))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Diaper Changes")
                    .font(.headline)
                Spacer()
                Text("Last 14 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if last14Days.isEmpty {
                Text("No diaper data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(last14Days, id: \.date) { day in
                        let displayDate = shortDate(day.date)

                        BarMark(
                            x: .value("Date", displayDate),
                            y: .value("Count", day.wetOnly)
                        )
                        .foregroundStyle(by: .value("Type", "Wet"))

                        BarMark(
                            x: .value("Date", displayDate),
                            y: .value("Count", day.solidOnly)
                        )
                        .foregroundStyle(by: .value("Type", "Solid"))

                        BarMark(
                            x: .value("Date", displayDate),
                            y: .value("Count", day.both)
                        )
                        .foregroundStyle(by: .value("Type", "Both"))
                    }
                }
                .chartForegroundStyleScale([
                    "Wet": Color.yellow,
                    "Solid": Color.brown,
                    "Both": Color.green,
                ])
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
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

            // Daily average
            if !last14Days.isEmpty {
                let totalChanges = last14Days.reduce(0) { $0 + $1.wetOnly + $1.solidOnly + $1.both }
                let avg = Double(totalChanges) / Double(last14Days.count)
                Text("Average: \(String(format: "%.1f", avg)) changes/day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func shortDate(_ dateString: String) -> String {
        guard let date = DateFormatting.parseDate(dateString) else { return dateString }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
